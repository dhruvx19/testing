import { ApiResponse } from '../../utils/ApiResponseClass.js';
import prisma from '../../config/database.js';
import { logWithTraceId } from '../../utils/logger.js';
import TokenService from '../tokenManagement/Token.services.js';
import bcrypt from 'bcryptjs';
import { redisService } from '../../externalSystems/redis/redis.js';
import { cacheAppointmentMeta } from '../../utils/etaCache.js';
import dashboardEvents from '../dashboard/dashboard.events.js';
import PaymentService from '../payments/payment.services.js';
import { appointmentFee } from '../../config/constants.js';
import WalletService from '../wallet/wallet.services.js';
import { sendNotification } from '../../queues/notificationQueue.js';
import { NotificationTypes } from '../../utils/notificationTypes.js';

class AppointmentService {
  // Booking an appointment
  static async bookAppointment(appointmentData) {
    const logger = logWithTraceId();
    const spanId = `[BOOK-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Booking appointment`);
    const {
      patientId,
      doctorId,
      doctorSlotScheduleId,
      reason,
      referBy,
      dependentId,
      bookedFor,
      bookingType,
      useWallet = false, // Optional: Whether to use wallet balance (default: false)
    } = appointmentData;

    try {
      const result = await prisma.$transaction(
        async (tx) => {
          //STEP 1: If DEPENDENT ensure dependent exists and belongs to patient
          if (bookedFor === 'DEPENDENT') {
            if (!dependentId)
              throw ApiResponse.error('dependentId is required for DEPENDENT booking');
            const dependent = await tx.dependent.findFirst({
              where: { id: dependentId, isActive: true },
            });
            if (!dependent || dependent.patientId !== patientId) {
              throw ApiResponse.error(400, 'Invalid dependent for given patient');
            }
          }

          // STEP 2: Verify slot exists and belongs to the doctor
          const slot = await tx.doctorSlotSchedule.findFirst({
            where: { id: doctorSlotScheduleId, doctor: { deletedAt: null } },
            select: { id: true, doctorId: true, clinicId: true, hospitalId: true },
          });
          if (!slot || slot.doctorId !== doctorId) {
            throw ApiResponse.error(400, 'Invalid slot for provided doctor');
          }

          // STEP 3: Check if user has already booked an appointment for the same slot
          const existingAppointment = await tx.appointment.findFirst({
            where: {
              patientId,
              dependentId: bookedFor === 'DEPENDENT' ? dependentId : null,
              doctorSlotScheduleId,
              status: {
                in: ['CONFIRMED', 'CHECKED_IN', 'SERVED', 'NO_SHOW', 'ENGAGED'],
              },
            },
          });
          if (existingAppointment) {
            logger.warn(
              `${spanId} Patient ${patientId} has already booked an appointment for slot ${doctorSlotScheduleId}`
            );
            throw ApiResponse.error(400, 'You have already booked an appointment for this slot');
          }

          // STEP 4: Check if patient has free appointments
          const patient = await tx.patient.findFirst({
            where: { userId: patientId, deletedAt: null },
            select: { freeAppointments: true },
          });
          if (!patient) {
            throw ApiResponse.error(404, 'Patient not found');
          }
          const hasFreeAppointment = patient.freeAppointments > 0;

          // STEP 5: If has free appointment
          if (hasFreeAppointment) {
            logger.info(
              `${spanId} Patient has free appointments available: ${patient.freeAppointments}`
            );
            // Decrement free appointments count at booking time
            await tx.patient.update({
              where: { userId: patientId },
              data: { freeAppointments: { decrement: 1 } },
            });
            // Create appointment with CREATED status
            const appointment = await tx.appointment.create({
              data: {
                patientId,
                doctorId,
                dependentId: bookedFor === 'DEPENDENT' ? dependentId : null,
                bookedFor,
                doctorSlotScheduleId,
                referBy,
                reason,
                type: 'ONLINE',
                bookingType,
                status: 'CREATED',
                paymentStatus: 'COMPLETED', // Free appointment - payment not required
              },
            });
            logger.info(`${spanId} Free appointment created: ${appointment.id}`);

            // AUTO-VERIFY/CONFIRM: Since it's free, we can move it to PENDING or CONFIRMED immediately
            logger.info(`${spanId} Auto-verifying free appointment`);
            const verifiedAppointment = await this.verifyAppointment(
              { appointmentId: appointment.id },
              tx
            );

            return { appointment: verifiedAppointment, isFree: true };
          }

          // STEP 6: No free appointment - Create appointment and payment
          logger.info(`${spanId} No free appointments - initiating payment flow`);

          // Use platform service fee (consultation fee paid directly to doctor)
          const serviceFee = appointmentFee.SERVICE_FEE;

          // Create appointment with CREATED status (will be confirmed after payment)
          const appointment = await tx.appointment.create({
            data: {
              patientId,
              doctorId,
              dependentId: bookedFor === 'DEPENDENT' ? dependentId : null,
              bookedFor,
              doctorSlotScheduleId,
              referBy,
              reason,
              type: 'ONLINE',
              bookingType,
              status: 'CREATED',
              paymentStatus: 'PENDING',
            },
          });

          // Create payment for web (get PhonePe payment URL)
          const payment = await PaymentService.createAppointmentPayment(
            {
              appointmentId: appointment.id,
              patientId,
              doctorId,
              amount: serviceFee,
              bookingType,
              useWallet, // Pass user's wallet preference
            },
            tx
          );

          logger.info(`${spanId} Appointment created with payment: ${appointment.id}`);

          // AUTO-VERIFY/CONFIRM: If payment is wallet-only (completed), move to next status immediately
          if (payment && !payment.requiresGateway) {
            logger.info(`${spanId} Wallet-only payment detected - auto-verifying appointment`);
            const verifiedAppointment = await this.verifyAppointment(
              {
                appointmentId: appointment.id,
                merchantTransactionId: payment.merchantTransactionId,
              },
              tx
            );

            return {
              appointment: verifiedAppointment,
              payment,
              isFree: false,
            };
          }

          return {
            appointment,
            payment,
            isFree: false,
          };
        },
        {
          timeout: 15000, // Increased timeout for payment API calls
        }
      );

      logger.info(`${spanId} Appointment booking process completed: ${result.appointment.id}`);

      // Return appropriate response based on whether it's free or paid
      if (result.isFree) {
        return {
          appointmentId: result.appointment.id,
          status: result.appointment.status,
          tokenNo: result.appointment.tokenNo || null,
          paymentRequired: false,
          freeAppointmentUsed: true,
        };
      } else {
        // Paid appointment response
        const response = {
          appointmentId: result.appointment.id,
          status: result.appointment.status,
          tokenNo: result.appointment.tokenNo || null,
          paymentRequired: result.payment.requiresGateway, // true if PhonePe needed, false if wallet-only
          payment: {
            paymentId: result.payment.paymentId, // MOBILE ONLY - commented for web
            merchantTransactionId: result.payment.merchantTransactionId,
            totalAmount: result.payment.totalAmount,
            walletAmount: result.payment.walletAmount,
            gatewayAmount: result.payment.gatewayAmount,
            provider: result.payment.provider, // MOBILE ONLY - WALLET / GATEWAY / MIXED - commented for web
            token: result.payment.token, // MOBILE ONLY - SDK token for mobile app - commented for web
            requestPayload: result.payment.requestPayload, // MOBILE ONLY - Base64 payload - commented for web
            // paymentUrl: result.payment.paymentUrl, // WEB ONLY - PhonePe payment URL (null if wallet-only)
            orderId: result.payment.orderId, // PhonePe order ID (null if wallet-only)
            expiresAt: result.payment.expiresAt,
          },
        };
        return response;
      }
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error booking appointment:`, error);
      throw ApiResponse.error('Internal Server Error', error?.message || 'Error booking appointment', 500);
    }
  }

  // verify payment and confirm appointment
  static async verifyAppointment(appointmentData, externalTx = null) {
    const logger = logWithTraceId();
    const spanId = `[VERIFY-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Verifying appointment`);
    const { appointmentId, merchantTransactionId } = appointmentData;

    try {
      // Use external transaction if provided (for webhook/reconciliation), otherwise create new one
      const executeInTransaction = async (tx) => {
        // STEP 1: Fetch the appointment
        const appointment = await tx.appointment.findFirst({
          where: { id: appointmentId, deletedAt: null },
        });
        if (!appointment) {
          logger.warn(`${spanId} Appointment ${appointmentId} not found`);
          throw ApiResponse.error(404, 'Appointment not found');
        }
        // Check if appointment is already confirmed
        if (appointment.status === 'CONFIRMED' && appointment.paymentStatus === 'COMPLETED') {
          logger.warn(`${spanId} Appointment ${appointmentId} is already confirmed`);
          throw ApiResponse.error(400, 'Appointment is already confirmed');
        }
        // Check if appointment is NOT in CREATED status
        if (appointment.status !== 'CREATED') {
          logger.warn(`${spanId} Appointment ${appointmentId} is not in CREATED status`);
          throw ApiResponse.error(400, 'Appointment is not pending verification');
        }

        // STEP 2: Determine if payment verification is needed
        let paymentVerified = false;
        if (appointment.paymentStatus === 'COMPLETED') {
          // Free appointment (payment already marked as COMPLETED)
          logger.info(`${spanId} Free appointment - no payment verification needed`);
          paymentVerified = true;
        } else if (merchantTransactionId) {
          // Paid appointment - Verify payment with PhonePe
          logger.info(`${spanId} Verifying payment with PhonePe: ${merchantTransactionId}`);
          const paymentData = await PaymentService.verifyPaymentStatus(merchantTransactionId, tx);
          paymentVerified = paymentData.isSuccessful;
        } else {
          // No payment information provided
          logger.warn(`${spanId} No payment information provided`);
          throw ApiResponse.error(400, 'Payment verification information required');
        }

        // STEP 3: Handle payment verification result
        if (!paymentVerified) {
          // Check if payment is still processing
          const paymentStatusCheck = await tx.payment.findFirst({
            where: {
              referenceId: appointmentId,
              referenceType: 'APPOINTMENT',
            },
            select: { status: true },
          });

          if (paymentStatusCheck?.status === 'PROCESSING') {
            logger.info(`${spanId} Payment is still processing, returning status to mobile app`);
            return {
              appointmentId: appointment.id,
              status: 'CREATED',
              paymentStatus: 'PROCESSING',
              message: 'Payment is still being processed. Please wait.'
            };
          }

          // Payment failed - restore free appointment if it was used
          logger.warn(`${spanId} Payment verification failed (Status: ${paymentStatusCheck?.status})`);

          // Check if a free appointment was used (paymentStatus would be COMPLETED for free)
          if (appointment.paymentStatus === 'COMPLETED') {
            // This was a free appointment, restore it
            logger.info(
              `${spanId} Restoring free appointment for patient ${appointment.patientId}`
            );
            await tx.patient.update({
              where: { userId: appointment.patientId },
              data: { freeAppointments: { increment: 1 } },
            });
          }
          // IMPORTANT: Refund wallet if wallet was used
          // Fetch payment record to check if wallet was used
          const existingPaymentRecord = await tx.payment.findFirst({
            where: {
              referenceId: appointmentId,
              referenceType: 'APPOINTMENT',
            },
            select: {
              id: true,
              walletAmount: true,
              provider: true,
              gatewayAmount: true,
              processedAt: true,
              totalAmount: true,
              status: true,
            },
          });

          if (existingPaymentRecord && Number(existingPaymentRecord.walletAmount) > 0) {
            logger.info(`${spanId} Refunding ₹${existingPaymentRecord.walletAmount} to wallet (payment failed)`);

            // Credit wallet back
            await WalletService.credit(
              {
                userId: appointment.patientId,
                amount: Number(existingPaymentRecord.walletAmount),
                type: 'REFUND',
                paymentId: existingPaymentRecord.id,
                description: `Refund for failed payment (Appointment ${appointmentId})`,
                referenceId: appointmentId,
                referenceType: 'APPOINTMENT',
              },
              tx
            );
            logger.info(`${spanId} Wallet refunded successfully`);
          }

          // Initiate PhonePe refund if gateway was used AND payment was successful
          if (existingPaymentRecord && Number(existingPaymentRecord.gatewayAmount) > 0) {
            // Only refund if money was actually debited (processedAt is set only on success)
            const wasSuccessful = existingPaymentRecord.processedAt !== null;

            if (wasSuccessful) {
              logger.info(`${spanId} Scheduling PhonePe refund for ${existingPaymentRecord.gatewayAmount}`);

              // Schedule refund outside transaction
              setImmediate(async () => {
                try {
                  const RefundService = (await import('../refunds/refund.services.js')).default;
                  await RefundService.initiateRefund({
                    paymentId: existingPaymentRecord.id,
                    amount: Number(existingPaymentRecord.totalAmount),
                    reason: `Automatic refund for failed payment (Verify API)`,
                    initiatedBy: 'SYSTEM',
                  });
                  logger.info(`${spanId} PhonePe refund initiated for payment ${existingPaymentRecord.id}`);
                } catch (refundError) {
                  logger.error(`${spanId} Failed to initiate PhonePe refund:`, refundError);
                }
              });
            } else {
              logger.info(
                `${spanId} Skipping PhonePe refund - payment failed before money was debited`
              );
            }
          }
          // Update appointment status to FAILED
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: {
              paymentStatus: existingPaymentRecord?.status ? existingPaymentRecord?.status : 'FAILED', // Store actual status (FAILED or EXPIRED)
              status: 'FAILED',
            },
          });

          return updatedAppointment;
        }

        // STEP 4: Payment verified - Now confirm the appointment
        logger.info(`${spanId} Payment verified - confirming appointment`);

        // Determine auto-approve setting from slot's clinic/hospital
        const slot = await tx.doctorSlotSchedule.findFirst({
          where: { id: appointment.doctorSlotScheduleId },
          select: { clinicId: true, hospitalId: true },
        });

        let isAutoApprove = null;

        if (slot?.clinicId) {
          const clinicMapping = await tx.doctorClinicMapping.findFirst({
            where: {
              doctorId: appointment.doctorId,
              clinicId: slot.clinicId,
              status: 'ACTIVE',
            },
            select: { autoApprove: true },
          });
          if (clinicMapping && typeof clinicMapping.autoApprove === 'boolean') {
            isAutoApprove = clinicMapping.autoApprove;
          }
        } else if (slot?.hospitalId) {
          const hospitalMapping = await tx.doctorHospitalMapping.findFirst({
            where: {
              doctorId: appointment.doctorId,
              hospitalId: slot.hospitalId,
              status: 'ACTIVE',
            },
            select: { autoApprove: true },
          });
          if (hospitalMapping && typeof hospitalMapping.autoApprove === 'boolean') {
            isAutoApprove = hospitalMapping.autoApprove;
          }
        }

        // STEP 5: If auto-approve is disabled, set to PENDING (requires manual approval)
        if (isAutoApprove === false) {
          logger.info(`${spanId} Auto-approve disabled - setting appointment to PENDING`);

          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: {
              status: 'PENDING',
              paymentStatus: 'COMPLETED',
            },
          });

          // Increase booked token count for slot
          await TokenService.increaseBookedToken(
            tx,
            appointment.doctorId,
            appointment.doctorSlotScheduleId,
            appointment.patientId,
            true
          );
          // Send notification to patient that appointment is pending approval
          await sendNotification({
            userId: appointment.patientId,
            type: NotificationTypes.APPOINTMENT_REQUESTED,
            payload: { appointmentId },
          }).catch((err) => {
            logger.warn(`${spanId} Failed to queue notification:`, err);
          });

          // Convert tokenNo to string for frontend compatibility
          return {
            ...updatedAppointment,
            tokenNo: updatedAppointment.tokenNo?.toString() || null,
          };
        }

        // STEP 6: Auto-approve enabled - Get token and confirm appointment
        logger.info(`${spanId} Auto-approve enabled - confirming appointment`);

        const tokenNo = await TokenService.getToken(
          tx,
          appointment.doctorId,
          appointment.doctorSlotScheduleId,
          appointment.patientId,
          true
        );

        if (tokenNo === null) {
          logger.warn(`${spanId} No available tokens for slot ${appointment.doctorSlotScheduleId}`);
          throw ApiResponse.error(400, 'No available tokens for this slot');
        }

        // Update appointment with token number and CONFIRMED status
        const updatedAppointment = await tx.appointment.update({
          where: {
            id: appointmentId,
          },
          data: {
            status: 'CONFIRMED',
            tokenNo: tokenNo,
            paymentStatus: 'COMPLETED',
          },
        });

        logger.info(`${spanId} Appointment confirmed with token ${tokenNo}`);

        // STEP 7: Create/Update HospitalClinicPatientMapping
        // We do this after successful confirmation to ensure patient is mapped to the facility
        if (slot?.clinicId) {
          await tx.hospitalClinicPatientMapping.upsert({
            where: {
              clinicId_patientId: {
                clinicId: slot.clinicId,
                patientId: appointment.patientId,
              },
            },
            create: {
              clinicId: slot.clinicId,
              patientId: appointment.patientId,
            },
            update: {
              updatedAt: new Date(),
            },
          });
          logger.info(
            `${spanId} Mapped patient ${appointment.patientId} to clinic ${slot.clinicId}`
          );
        } else if (slot?.hospitalId) {
          await tx.hospitalClinicPatientMapping.upsert({
            where: {
              hospitalId_patientId: {
                hospitalId: slot.hospitalId,
                patientId: appointment.patientId,
              },
            },
            create: {
              hospitalId: slot.hospitalId,
              patientId: appointment.patientId,
            },
            update: {
              updatedAt: new Date(),
            },
          });
          logger.info(
            `${spanId} Mapped patient ${appointment.patientId} to hospital ${slot.hospitalId}`
          );
        }

        // Convert tokenNo to string for frontend compatibility
        return {
          ...updatedAppointment,
          tokenNo: updatedAppointment.tokenNo?.toString() || null,
        };
      };

      // Execute in external transaction or create new one
      const result = externalTx
        ? await executeInTransaction(externalTx)
        : await prisma.$transaction(executeInTransaction, {
          timeout: 15000, // Increased timeout for payment API calls
        });

      logger.info(`${spanId} Appointment verification completed: ${result.id}`);

      // Cache appointment metadata for ETA API (Async)
      if (result.status === 'CONFIRMED') {
        (async () => {
          try {
            const fullDetails = await prisma.appointment.findFirst({
              where: { id: result.id, deletedAt: null },
              select: {
                doctorSlotScheduleId: true,
                status: true,
                tokenNo: true,
                doctor: { select: { avgDurationMinutes: true } },
                schedule: { select: { startTime: true, date: true } },
              },
            });
            if (fullDetails) {
              await cacheAppointmentMeta(result.id, fullDetails);
            }
          } catch (cacheErr) {
            logger.warn(`${spanId} Failed to cache appointment meta`, cacheErr);
          }
        })();
      }
      // Send notification about confirmed appointment (only if verification was successful)
      if (result.status === 'CONFIRMED') {
        await sendNotification({
          userId: result.patientId,
          type: NotificationTypes.APPOINTMENT_CONFIRMED,
          payload: { appointmentId: result.id },
        }).catch((err) => {
          logger.warn(`${spanId} Failed to queue notification:`, err);
        });

        // Send initial SLOT_LIVE_UPDATE to trigger lock screen notification immediately after booking.
        // currentToken=0 means the queue hasn't started yet; the ETA worker will send real-time updates once the slot goes live.
        setImmediate(async () => {
          try {
            const appointmentDetails = await prisma.appointment.findFirst({
              where: { id: result.id, deletedAt: null },
              select: {
                tokenNo: true,
                patientId: true,
                doctor: {
                  select: {
                    user: { select: { firstName: true, lastName: true } },
                  },
                },
                schedule: {
                  select: {
                    startTime: true,
                    clinic: { select: { name: true } },
                    hospital: { select: { name: true } },
                  },
                },
              },
            });

            if (!appointmentDetails) return;

            const doctorFirstName = appointmentDetails.doctor?.user?.firstName || '';
            const doctorLastName = appointmentDetails.doctor?.user?.lastName || '';
            const doctorName = `Dr. ${doctorFirstName} ${doctorLastName}`.trim();
            const hospitalName =
              appointmentDetails.schedule?.clinic?.name ||
              appointmentDetails.schedule?.hospital?.name ||
              'eClinic-Q';
            const slotStartTime = appointmentDetails.schedule?.startTime;

            await sendNotification({
              userId: result.patientId,
              type: NotificationTypes.SLOT_LIVE_UPDATE,
              priority: 'high',
              channels: ['push'],
              data: {
                appointmentId: result.id,
                doctorName,
                hospitalName,
                yourToken: (result.tokenNo || appointmentDetails.tokenNo || 0).toString(),
                currentToken: '0',
                estimatedTime: slotStartTime ? new Date(slotStartTime).toISOString() : new Date().toISOString(),
                waitTimeMinutes: '0',
              },
            });
            logger.info(`${spanId} Initial SLOT_LIVE_UPDATE sent for appointment ${result.id}`);
          } catch (err) {
            logger.warn(`${spanId} Failed to send initial SLOT_LIVE_UPDATE:`, err);
          }
        });
      }
      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error verifying appointment:`, error);
      throw ApiResponse.error('Internal Server Error', error?.message || 'Error verifying appointment', 500);
    }
  }

  // get Appointment details by ID
  static async getAppointmentById(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[GET-APPOINTMENT-BY-ID-SERVICE]`;
    logger.info(`${spanId} Fetching appointment ${appointmentId}`);
    try {
      const appointment = await prisma.appointment.findFirst({
        where: { id: appointmentId, deletedAt: null },
        include: {
          doctor: {
            select: {
              userId: true,
              workExperience: true,
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  profilePhoto: true,
                },
              },
              specialties: {
                include: {
                  specialty: {
                    select: {
                      name: true,
                    },
                  },
                },
              },
              education: {
                select: {
                  degree: true,
                  graduationType: true,
                },
                orderBy: {
                  completionYear: 'desc',
                },
              },
              // Include doctor->clinic/hospital mappings so we can read mapping-level fees
              clinics: {
                select: {
                  clinic: {
                    select: {
                      id: true,
                      name: true,
                      blockNo: true,
                      areaStreet: true,
                      landmark: true,
                      city: true,
                      state: true,
                      pincode: true,
                      latitude: true,
                      longitude: true,
                    },
                  },
                  consultationFee: true,
                  followUpFee: true,
                  status: true,
                },
              },
              hospitals: {
                select: {
                  hospital: {
                    select: {
                      id: true,
                      name: true,
                      address: true,
                      city: true,
                      state: true,
                      pincode: true,
                      latitude: true,
                      longitude: true,
                    },
                  },
                  consultationFee: true,
                  followUpFee: true,
                  status: true,
                },
              },
            },
          },
          schedule: {
            select: {
              id: true,
              date: true,
              startTime: true,
              endTime: true,
              slotStatus: true,
              clinic: {
                select: {
                  id: true,
                  name: true,
                  blockNo: true,
                  areaStreet: true,
                  landmark: true,
                  city: true,
                  state: true,
                  pincode: true,
                },
              },
              hospital: {
                select: {
                  id: true,
                  name: true,
                  address: true,
                  city: true,
                  state: true,
                  pincode: true,
                },
              },
            },
          },
          patient: {
            select: {
              dob: true,
              bloodGroup: true,
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  phone: true,
                  emailId: true,
                  gender: true,
                },
              },
            },
          },
          dependent: {
            select: {
              firstName: true,
              lastName: true,
              phone: true,
              emailId: true,
              gender: true,
              dob: true,
            },
          },
        },
      });

      // Fetch payment details if payment exists
      let paymentDetails = null;
      if (appointment && appointment.status != 'CREATED') {
        const payment = await prisma.payment.findFirst({
          where: {
            referenceId: appointmentId,
            referenceType: 'APPOINTMENT',
          },
          select: {
            id: true,
            totalAmount: true,
            walletAmount: true,
            gatewayAmount: true,
            status: true,
            provider: true,
            processedAt: true,
            createdAt: true,
          },
        });

        if (payment) {
          paymentDetails = {
            paymentId: payment.id,
            isFree: false,
            totalAmount: Number(payment.totalAmount),
            walletAmount: Number(payment.walletAmount),
            gatewayAmount: Number(payment.gatewayAmount),
            status: payment.status,
            provider: payment.provider,
            processedAt: payment.processedAt,
            createdAt: payment.createdAt,
          };
        } else {
          // Free appointment (no payment record)
          paymentDetails = {
            isFree: true,
            totalAmount: 0,
            walletAmount: 0,
            gatewayAmount: 0,
            status: null,
            provider: null,
          };
        }
      }

      if (!appointment) {
        logger.warn(`${spanId} Appointment ${appointmentId} not found`);
        throw ApiResponse.error(404, 'Appointment not found');
      }

      // Derive consultation and follow-up fees from the slot's clinic/hospital mapping
      const _feesFromSlotMapping = (() => {
        try {
          const schedule = appointment.schedule || {};
          const scheduleClinicId = schedule.clinic?.id || schedule.clinicId || null;
          const scheduleHospitalId = schedule.hospital?.id || schedule.hospitalId || null;

          // Prefer clinic mapping
          if (scheduleClinicId && appointment.doctor?.clinics) {
            const map = appointment.doctor.clinics.find(
              (m) =>
                (m.clinic && m.clinic.id === scheduleClinicId) || m.clinicId === scheduleClinicId
            );
            if (map) {
              return {
                consultationFee:
                  typeof map.consultationFee !== 'undefined' ? map.consultationFee : null,
                followUpFee: typeof map.followUpFee !== 'undefined' ? map.followUpFee : null,
              };
            }
          }

          // Fallback to hospital mapping
          if (scheduleHospitalId && appointment.doctor?.hospitals) {
            const map = appointment.doctor.hospitals.find(
              (m) =>
                (m.hospital && m.hospital.id === scheduleHospitalId) ||
                m.hospitalId === scheduleHospitalId
            );
            if (map) {
              return {
                consultationFee:
                  typeof map.consultationFee !== 'undefined' ? map.consultationFee : null,
                followUpFee: typeof map.followUpFee !== 'undefined' ? map.followUpFee : null,
              };
            }
          }
        } catch (e) { }
        return { consultationFee: null, followUpFee: null };
      })();

      // Format the response according to UI requirements
      const formattedAppointment = {
        appointmentId: appointment.id,
        consultationFee: _feesFromSlotMapping.consultationFee,
        followUpFee: _feesFromSlotMapping.followUpFee,
        status: appointment.status,
        tokenNo: appointment.tokenNo,
        bookedFor: appointment.bookedFor,
        bookingType: appointment.bookingType,
        type: appointment.type,
        isRescheduled: appointment.isRescheduled,
        rating: appointment.rating || null,

        // Doctor Information
        doctor: {
          userId: appointment.doctor.userId,
          name: `${appointment.doctor.user.firstName || ''} ${appointment.doctor.user.lastName || ''}`.trim(),
          profilePhoto: appointment.doctor.user.profilePhoto,
          specialties: appointment.doctor.specialties.map((s) => s.specialty.name),
          degrees: appointment.doctor.education.map(
            (edu) => `${edu.degree} - ${edu.graduationType}`
          ),
          // consultation/follow-up fees derived from the slot's mapping
          consultationFee: _feesFromSlotMapping.consultationFee,
          followUpFee: _feesFromSlotMapping.followUpFee,
          workExperience: appointment.doctor.workExperience || null,
          // Primary clinic (if associated) - derive from doctor->clinics mapping
          primaryClinic:
            appointment.doctor?.clinics && appointment.doctor.clinics.length > 0
              ? (() => {
                const mapping = appointment.doctor.clinics[0];
                const c = mapping.clinic || {};
                return {
                  id: c.id,
                  name: c.name,
                  address: [c.blockNo, c.areaStreet, c.landmark, c.city, c.state, c.pincode]
                    .filter(Boolean)
                    .join(', '),
                  latitude: c.latitude,
                  longitude: c.longitude,
                  consultationFee: mapping.consultationFee || null,
                  followUpFee: mapping.followUpFee || null,
                };
              })()
              : null,
          // Associated hospitals
          associatedHospitals: appointment.doctor.hospitals.map((h) => ({
            id: h.hospital.id,
            name: h.hospital.name,
            address: h.hospital.address
              ? typeof h.hospital.address === 'string'
                ? h.hospital.address
                : JSON.stringify(h.hospital.address)
              : [h.hospital.city, h.hospital.state, h.hospital.pincode].filter(Boolean).join(', '),
            city: h.hospital.city,
            state: h.hospital.state,
            pincode: h.hospital.pincode,
            latitude: h.hospital.latitude,
            longitude: h.hospital.longitude,
          })),
        },

        // Patient Information
        patient: {
          name:
            appointment.bookedFor === 'DEPENDENT' && appointment.dependent
              ? `${appointment.dependent.firstName || ''} ${appointment.dependent.lastName || ''}`.trim()
              : `${appointment.patient.user.firstName || ''} ${appointment.patient.user.lastName || ''}`.trim(),
          phone:
            appointment.bookedFor === 'DEPENDENT' && appointment.dependent
              ? appointment.dependent.phone
              : appointment.patient.user.phone,
          emailId:
            appointment.bookedFor === 'DEPENDENT' && appointment.dependent
              ? appointment.dependent.emailId
              : appointment.patient.user.emailId,
          gender:
            appointment.bookedFor === 'DEPENDENT' && appointment.dependent
              ? appointment.dependent.gender
              : appointment.patient.user.gender,
          dob:
            appointment.bookedFor === 'DEPENDENT' && appointment.dependent
              ? appointment.dependent.dob
              : appointment.patient.dob,
          bloodGroup: appointment.patient?.bloodGroup || null,
        },

        // Schedule Information
        schedule: {
          date: appointment.schedule.date,
          startTime: appointment.schedule.startTime,
          endTime: appointment.schedule.endTime,
          slotStatus: appointment.schedule.slotStatus,
        },

        // Clinic/Hospital Information
        location: appointment.schedule.clinic
          ? {
            type: 'CLINIC',
            id: appointment.schedule.clinic.id,
            name: appointment.schedule.clinic.name,
            address: [
              appointment.schedule.clinic.blockNo,
              appointment.schedule.clinic.areaStreet,
              appointment.schedule.clinic.landmark,
              appointment.schedule.clinic.city,
              appointment.schedule.clinic.state,
              appointment.schedule.clinic.pincode,
            ]
              .filter(Boolean)
              .join(', '),
          }
          : appointment.schedule.hospital
            ? {
              type: 'HOSPITAL',
              id: appointment.schedule.hospital.id,
              name: appointment.schedule.hospital.name,
              address: appointment.schedule.hospital.address
                ? typeof appointment.schedule.hospital.address === 'string'
                  ? appointment.schedule.hospital.address
                  : JSON.stringify(appointment.schedule.hospital.address)
                : [
                  appointment.schedule.hospital.city,
                  appointment.schedule.hospital.state,
                  appointment.schedule.hospital.pincode,
                ]
                  .filter(Boolean)
                  .join(', '),
            }
            : null,

        // Additional fields
        reason: appointment.reason,
        paymentStatus: appointment.paymentStatus,
        createdAt: appointment.createdAt,
        updatedAt: appointment.updatedAt,

        // Payment Details
        payment: paymentDetails,
      };

      logger.info(`${spanId} Appointment ${appointmentId} fetched successfully`);
      return formattedAppointment;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error fetching appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Rescheduling an appointment
  static async rescheduleAppointment(data) {
    const logger = logWithTraceId();
    const spanId = `[RESCHEDULE-APPOINTMENT-SERVICE]`;
    const { appointmentId, newSlotId } = data;
    logger.info(`${spanId} Rescheduling appointment ${appointmentId}`);
    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // Fetch the existing appointment
          const existingAppointment = await tx.appointment.findUnique({
            where: { id: appointmentId },
          });
          if (!existingAppointment) {
            logger.warn(`${spanId} Appointment ${appointmentId} not found`);
            throw ApiResponse.error(404, 'Appointment not found');
          }
          if (existingAppointment.status === 'CANCELLED') {
            logger.warn(`${spanId} Cannot reschedule a cancelled appointment ${appointmentId}`);
            throw ApiResponse.error(400, 'Cannot reschedule a cancelled appointment');
          }
          if (existingAppointment.isRescheduled) {
            logger.warn(`${spanId} Appointment ${appointmentId} is already rescheduled once`);
            throw ApiResponse.error(400, 'Appointment is already rescheduled once');
          }
          // Checking that user has not already booked an appointment for the new slot
          const duplicateAppointment = await tx.appointment.findFirst({
            where: {
              patientId: existingAppointment.patientId,
              dependentId: existingAppointment.dependentId,
              doctorSlotScheduleId: newSlotId,
              bookedFor: existingAppointment.bookedFor,
              status: 'CONFIRMED',
            },
          });
          if (duplicateAppointment) {
            logger.warn(
              `${spanId} Patient ${existingAppointment.patientId} has already booked an appointment for slot ${newSlotId}`
            );
            throw ApiResponse.error(400, 'You have already booked an appointment for this slot');
          }
          // Verify new slot exists and belongs to the same doctor, and get clinic/hospital details
          const newSlot = await tx.doctorSlotSchedule.findUnique({
            where: { id: newSlotId },
            select: { doctorId: true, clinicId: true, hospitalId: true },
          });
          if (!newSlot || newSlot.doctorId !== existingAppointment.doctorId) {
            throw ApiResponse.error(400, 'Invalid slot for the appointment doctor');
          }
          const doctorId = existingAppointment.doctorId;

          // Prefer mapping-level autoApprove (clinic/hospital)
          let isAutoApprove = null;

          if (newSlot && newSlot.clinicId) {
            const clinicMapping = await tx.doctorClinicMapping.findFirst({
              where: {
                doctorId: doctorId,
                clinicId: newSlot.clinicId,
                status: 'ACTIVE',
              },
              select: { autoApprove: true },
            });
            if (clinicMapping && typeof clinicMapping.autoApprove === 'boolean') {
              isAutoApprove = clinicMapping.autoApprove;
            }
          } else if (newSlot && newSlot.hospitalId) {
            const hospitalMapping = await tx.doctorHospitalMapping.findFirst({
              where: {
                doctorId: doctorId,
                hospitalId: newSlot.hospitalId,
                status: 'ACTIVE',
              },
              select: { autoApprove: true },
            });
            if (hospitalMapping && typeof hospitalMapping.autoApprove === 'boolean') {
              isAutoApprove = hospitalMapping.autoApprove;
            }
          }

          if (isAutoApprove === false) {
            // 1.current slot booking decrease
            await TokenService.decreaseBookedToken(
              tx,
              doctorId,
              existingAppointment.doctorSlotScheduleId
            );
            // 2. new slot booking increase (skipHoldRelease=true since reschedule has no hold)
            await TokenService.increaseBookedToken(
              tx,
              doctorId,
              newSlotId,
              existingAppointment.patientId,
              true // skipHoldRelease
            );
            // 3. update appointment status to PENDING
            // 4. set isRescheduled to true
            const updatedAppointment = await tx.appointment.update({
              where: { id: appointmentId },
              data: {
                doctorSlotScheduleId: newSlotId,
                status: 'PENDING',
                isRescheduled: true,
              },
            });
            return updatedAppointment;
            // 5. RETURN appointment
          }
          const getTokenNo = await TokenService.getToken(
            tx,
            doctorId,
            newSlotId,
            existingAppointment.patientId,
            true // skipHoldRelease since reschedule has no hold
          );
          if (getTokenNo === null) {
            logger.warn(`${spanId} No available tokens for slot ${newSlotId}`);
            throw ApiResponse.error(400, 'No available tokens for this slot');
          }
          // Update the appointment with the new slot and token number
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: {
              doctorSlotScheduleId: newSlotId,
              tokenNo: getTokenNo,
              status: 'CONFIRMED',
              isRescheduled: true,
            },
          });
          await TokenService.updateToken(tx, existingAppointment.doctorSlotScheduleId);
          return updatedAppointment;
        },
        {
          timeout: 10000,
        }
      );
      logger.info(`${spanId} Appointment ${appointmentId} rescheduled successfully`);
      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error rescheduling appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Cancelling an appointment
  static async cancelAppointment(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[CANCEL-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Cancelling appointment ${appointmentId}`);
    try {
      const result = await prisma.$transaction(
        async (tx) => {
          const appointment = await tx.appointment.findUnique({
            where: { id: appointmentId },
          });
          if (!appointment) {
            logger.warn(`${spanId} Appointment ${appointmentId} not found`);
            throw new Error('Appointment not found');
          }
          if (appointment.status === 'CANCELLED') {
            logger.warn(`${spanId} Appointment ${appointmentId} is already cancelled`);
            throw new Error('Appointment is already cancelled');
          }
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: { status: 'CANCELLED' },
          });
          // Release token for cancelled appointment inside same transaction
          await TokenService.updateToken(tx, appointment.doctorSlotScheduleId);

          // HIGH CANCELLATION ALERT LOGIC
          try {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const cancelCount = await tx.appointment.count({
              where: {
                patientId: appointment.patientId,
                status: 'CANCELLED',
                updatedAt: { gte: today },
              }
            });

            // If a patient cancels 3 or more appointments in a single day
            if (cancelCount >= 3) {
              const NotificationService = (await import('../../notifications/notification.services.js')).default;
              await NotificationService.notifySuperAdmins({
                category: 'SYSTEM_ALERT',
                contentSubject: 'High Cancellation Alert',
                contentBody: `Patient ${appointment.patientId} has cancelled ${cancelCount} appointments today.`,
                entityType: 'PATIENT',
                entityId: appointment.patientId,
                priority: 'HIGH'
              });
            }
          } catch (notifErr) {
            logger.error(`${spanId} Failed to check/send high cancellation alert:`, notifErr);
          }

          return updatedAppointment;
        },
        {
          timeout: 10000,
        }
      );
      logger.info(`${spanId} Appointment ${appointmentId} cancelled successfully`);
      // Send notification to patient that appointment has been cancelled by user
      await sendNotification({
        userId: result.patientId,
        type: NotificationTypes.APPOINTMENT_CANCELLED_BY_USER,
        payload: { appointmentId: result.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });
      return result;
    } catch (error) {
      logger.error(`${spanId} Error cancelling appointment: ${error.message}`);
      if (
        error.message === 'Appointment not found' ||
        error.message === 'Appointment is already cancelled'
      ) {
        return ApiResponse.error(400, error.message, null);
      }
      return ApiResponse.error(500, `{error: ${error.message}}`, null);
    }
  }

  // Cancel Appointment by Provider (Doctor/Admin/Staff) - Can cancel CONFIRMED or PENDING appointments
  static async cancelAppointmentByProvider(appointmentId, cancellationReason = null) {
    const logger = logWithTraceId();
    const spanId = `[CANCEL-APPOINTMENT-BY-PROVIDER-SERVICE]`;
    logger.info(`${spanId} Provider cancelling appointment ${appointmentId}`);

    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // STEP 1: Fetch the appointment
          const appointment = await tx.appointment.findUnique({
            where: { id: appointmentId },
          });

          if (!appointment) {
            logger.warn(`${spanId} Appointment ${appointmentId} not found`);
            throw ApiResponse.error(404, 'Appointment not found');
          }

          // STEP 2: Check if appointment can be cancelled
          if (appointment.status === 'CANCELLED') {
            logger.warn(`${spanId} Appointment ${appointmentId} is already cancelled`);
            throw ApiResponse.error(400, 'Appointment is already cancelled');
          }

          // STEP 3: Only allow cancellation of CONFIRMED or PENDING appointments
          if (!['CONFIRMED', 'PENDING'].includes(appointment.status)) {
            logger.warn(
              `${spanId} Cannot cancel appointment with status ${appointment.status}. Only CONFIRMED or PENDING appointments can be cancelled.`
            );
            throw ApiResponse.error(
              400,
              `Cannot cancel appointment with status ${appointment.status}. Only CONFIRMED or PENDING appointments can be cancelled.`
            );
          }

          // STEP 4: Update appointment status to CANCELLED
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: {
              status: 'CANCELLED_BY_DOCTOR',
              cancellationReason: cancellationReason || 'Cancelled by provider',
            },
          });

          // STEP 5: Release token for cancelled appointment (only if it was CONFIRMED with token)
          if (appointment.status === 'CONFIRMED' && appointment.tokenNo) {
            await TokenService.decreaseBookedToken(
              tx,
              appointment.doctorId,
              appointment.doctorSlotScheduleId
            );
            logger.info(
              `${spanId} Token ${appointment.tokenNo} released for slot ${appointment.doctorSlotScheduleId}`
            );
          }

          // HIGH CANCELLATION ALERT LOGIC
          try {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const cancelCount = await tx.appointment.count({
              where: {
                doctorId: appointment.doctorId,
                status: 'CANCELLED_BY_DOCTOR',
                updatedAt: { gte: today },
              }
            });

            // If a doctor cancels 5 or more appointments in a single day
            if (cancelCount >= 5) {
              const NotificationService = (await import('../../notifications/notification.services.js')).default;
              await NotificationService.notifySuperAdmins({
                category: 'SYSTEM_ALERT',
                contentSubject: 'High Cancellation Alert',
                contentBody: `Doctor ${appointment.doctorId} has cancelled ${cancelCount} appointments today.`,
                entityType: 'DOCTOR',
                entityId: appointment.doctorId,
                priority: 'HIGH'
              });
            }
          } catch (notifErr) {
            logger.error(`${spanId} Failed to check/send high cancellation alert:`, notifErr);
          }

          return updatedAppointment;
        },
        {
          timeout: 10000,
        }
      );

      logger.info(`${spanId} Appointment ${appointmentId} cancelled successfully by provider`);

      // Send notification to patient that appointment has been cancelled by provider
      await sendNotification({
        userId: result.patientId,
        type: NotificationTypes.APPOINTMENT_CANCELLED_BY_PROVIDER,
        payload: { appointmentId: result.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });

      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error cancelling appointment by provider: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Getting scheduled appointments
  static async getScheduledAppointments(userId, type) {
    const logger = logWithTraceId();
    const spanId = `[GET-SCHEDULED-APPOINTMENTS-SERVICE]`;
    logger.info(
      `${spanId} Fetching scheduled appointments for user ${userId}${type ? ` with type filter: ${type}` : ''}`
    );
    try {
      // Build the where clause - start with base conditions
      const whereClause = {
        patientId: userId,
        status: {
          in: ['PENDING', 'CONFIRMED'],
        },
      };

      // Add type filtering if provided
      if (type === 'hospital') {
        // Filter appointments where slot has a hospitalId
        whereClause.schedule = {
          hospitalId: { not: null },
        };
      } else if (type === 'doctor') {
        // Filter appointments where slot has a clinicId
        whereClause.schedule = {
          clinicId: { not: null },
        };
      }
      // If no type provided, return all appointments (no additional filter)

      const appointments = await prisma.appointment.findMany({
        where: whereClause,
        select: {
          id: true,
          status: true,
          tokenNo: true,
          bookedFor: true,
          doctor: {
            select: {
              userId: true,
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  profilePhoto: true,
                },
              },
              specialties: {
                select: {
                  specialty: {
                    select: {
                      name: true,
                    },
                  },
                },
              },
              education: {
                select: {
                  degree: true,
                  graduationType: true,
                },
                orderBy: {
                  completionYear: 'desc',
                },
              },
            },
          },
          schedule: {
            select: {
              date: true,
              startTime: true,
              endTime: true,
            },
          },
          dependent: {
            select: {
              firstName: true,
              lastName: true,
            },
          },
          patient: {
            select: {
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                },
              },
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      // Format the response
      const formattedAppointments = appointments.map((appointment) => ({
        appointmentId: appointment.id,
        status: appointment.status,
        doctorName:
          `${appointment.doctor.user.firstName || ''} ${appointment.doctor.user.lastName || ''}`.trim(),
        doctorPhoto: appointment.doctor.user.profilePhoto,
        speciality: appointment.doctor.specialties.map((s) => s.specialty.name),
        degrees: appointment.doctor.education.map((edu) => edu.degree),
        appointmentDate: appointment.schedule.date,
        appointmentTime: {
          startTime: appointment.schedule.startTime,
          endTime: appointment.schedule.endTime,
        },
        tokenNo: appointment.status === 'CONFIRMED' ? appointment.tokenNo : null,
        patientName:
          appointment.bookedFor === 'DEPENDENT' && appointment.dependent
            ? `${appointment.dependent.firstName || ''} ${appointment.dependent.lastName || ''}`.trim()
            : `${appointment.patient.user.firstName || ''} ${appointment.patient.user.lastName || ''}`.trim(),
        bookedFor: appointment.bookedFor,
      }));

      logger.info(`${spanId} Retrieved ${formattedAppointments.length} scheduled appointments`);
      return formattedAppointments;
    } catch (error) {
      logger.error(`${spanId} Error fetching scheduled appointments: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // get Appointment History
  static async getAppointmentHistory(userId, type) {
    const logger = logWithTraceId();
    const spanId = `[GET-APPOINTMENT-HISTORY-SERVICE]`;
    logger.info(
      `${spanId} Fetching appointment history for user ${userId}${type ? ` with type filter: ${type}` : ''}`
    );
    try {
      // Build the where clause - start with base conditions
      const whereClause = {
        patientId: userId,
        status: {
          in: [
            'CHECKED_IN',
            'NO_SHOW',
            'SERVED',
            'ENGAGED',
            'CANCELLED',
            'CANCELLED_BY_DOCTOR',
            'FAILED',
          ],
        },
      };

      // Add type filtering if provided
      if (type === 'hospital') {
        // Filter appointments where slot has a hospitalId
        whereClause.schedule = {
          hospitalId: { not: null },
        };
      } else if (type === 'doctor') {
        // Filter appointments where slot has a clinicId
        whereClause.schedule = {
          clinicId: { not: null },
        };
      }
      // If no type provided, return all appointments (no additional filter)

      const appointments = await prisma.appointment.findMany({
        where: whereClause,
        select: {
          id: true,
          status: true,
          tokenNo: true,
          bookedFor: true,
          doctor: {
            select: {
              userId: true,
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  profilePhoto: true,
                },
              },
              specialties: {
                select: {
                  specialty: {
                    select: {
                      name: true,
                    },
                  },
                },
              },
              education: {
                select: {
                  degree: true,
                  graduationType: true,
                },
                orderBy: {
                  completionYear: 'desc',
                },
              },
            },
          },
          schedule: {
            select: {
              date: true,
              startTime: true,
              endTime: true,
            },
          },
          dependent: {
            select: {
              firstName: true,
              lastName: true,
            },
          },
          patient: {
            select: {
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                },
              },
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      // Format the response
      const formattedAppointments = appointments.map((appointment) => ({
        appointmentId: appointment.id,
        status: appointment.status,
        doctorName:
          `${appointment.doctor.user.firstName || ''} ${appointment.doctor.user.lastName || ''}`.trim(),
        doctorPhoto: appointment.doctor.user.profilePhoto,
        speciality: appointment.doctor.specialties.map((s) => s.specialty.name),
        degrees: appointment.doctor.education.map((edu) => edu.degree),
        appointmentDate: appointment.schedule.date,
        appointmentTime: {
          startTime: appointment.schedule.startTime,
          endTime: appointment.schedule.endTime,
        },
        tokenNo: appointment.status === 'CONFIRMED' ? appointment.tokenNo : null,
        patientName:
          appointment.bookedFor === 'DEPENDENT' && appointment.dependent
            ? `${appointment.dependent.firstName || ''} ${appointment.dependent.lastName || ''}`.trim()
            : `${appointment.patient.user.firstName || ''} ${appointment.patient.user.lastName || ''}`.trim(),
        bookedFor: appointment.bookedFor,
        rating: appointment.status === 'SERVED' ? appointment.rating || null : null,
      }));

      logger.info(
        `${spanId} Retrieved ${formattedAppointments.length} appointment history records`
      );
      return formattedAppointments;
    } catch (error) {
      logger.error(`${spanId} Error fetching appointment history: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Get pending appointments for doctor by hospital id
  // If no doctorId is provided, returns all pending appointments for the hospital
  // If both doctorId and hospitalId are provided, returns appointments for that specific doctor
  static async getPendingAppointmentsByDoctorAndHospital(doctorId, hospitalId) {
    const logger = logWithTraceId();
    const spanId = `[GET-PENDING-APPOINTMENTS-DOCTOR-HOSPITAL-SERVICE]`;

    // Validate hospitalId is required
    if (!hospitalId) {
      logger.warn(`${spanId} Missing hospitalId`);
      throw ApiResponse.error(400, 'hospitalId is required');
    }

    const logMessage = doctorId
      ? `${spanId} Fetching pending appointments for doctor ${doctorId} at hospital ${hospitalId}`
      : `${spanId} Fetching all pending appointments for hospital ${hospitalId}`;

    logger.info(logMessage);

    try {
      // Build the where clause conditionally
      const whereClause = {
        status: 'PENDING',
        schedule: {
          hospitalId,
          hospital: { deletedAt: null },
        },
        doctor: { deletedAt: null },
      };

      // Only add doctorId filter if it's provided
      if (doctorId) {
        whereClause.doctorId = doctorId;
      }

      // Fetch pending appointments with related data
      const appointments = await prisma.appointment.findMany({
        where: whereClause,
        include: {
          patient: {
            select: {
              dob: true,
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  phone: true,
                  emailId: true,
                  gender: true,
                },
              },
            },
          },
          dependent: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              gender: true,
              dob: true,
              relation: true,
              phone: true,
              emailId: true,
            },
          },
          doctor: {
            select: {
              user: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                },
              },
            },
          },
          schedule: {
            select: {
              id: true,
              date: true,
              startTime: true,
              endTime: true,
            },
          },
        },
        orderBy: {
          createdAt: 'asc',
        },
      });

      // Format the response with proper patient/dependent details
      const formattedAppointments = appointments.map((appointment) => {
        const isDependent = appointment.bookedFor === 'DEPENDENT';

        // Prepare patient/dependent details based on bookedFor
        let patientDetails;
        if (isDependent && appointment.dependent) {
          patientDetails = {
            firstName: appointment.dependent.firstName,
            lastName: appointment.dependent.lastName,
            gender: appointment.dependent.gender,
            dob: appointment.dependent.dob,
            phone: appointment.dependent.phone || appointment.patient?.user?.phone,
            emailId: appointment.dependent.emailId || appointment.patient?.user?.emailId,
            relation: appointment.dependent.relation,
            bookedBy:
              `${appointment.patient?.user?.firstName || ''} ${appointment.patient?.user?.lastName || ''}`.trim(),
          };
        } else if (appointment.patient?.user) {
          patientDetails = {
            firstName: appointment.patient.user.firstName,
            lastName: appointment.patient.user.lastName,
            gender: appointment.patient.user.gender,
            dob: appointment.patient.dob,
            phone: appointment.patient.user.phone,
            emailId: appointment.patient.user.emailId,
          };
        }

        return {
          id: appointment.id,
          patientId: appointment.patientId,
          status: appointment.status,
          bookedFor: appointment.bookedFor,
          bookingType: appointment.bookingType,
          type: appointment.type,
          reason: appointment.reason,
          paymentStatus: appointment.paymentStatus,
          createdAt: appointment.createdAt,

          // Patient or Dependent details
          patientDetails,

          // Doctor details
          doctor: {
            doctorId: appointment.doctor?.user?.id,
            firstName: appointment.doctor?.user?.firstName,
            lastName: appointment.doctor?.user?.lastName,
          },

          // Schedule details
          schedule: {
            slotId: appointment.schedule?.id,
            date: appointment.schedule?.date,
            startTime: appointment.schedule?.startTime,
            endTime: appointment.schedule?.endTime,
          },
        };
      });

      const successMessage = doctorId
        ? `${spanId} Retrieved ${formattedAppointments.length} pending appointments for doctor ${doctorId} at hospital ${hospitalId}`
        : `${spanId} Retrieved ${formattedAppointments.length} pending appointments for hospital ${hospitalId}`;

      logger.info(successMessage);
      return formattedAppointments;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error fetching pending appointments: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Get pending appoinments for clinic by clinic id
  static async getPendingAppointmentsByClinic(clinicId) {
    const logger = logWithTraceId();
    const spanId = `[GET-PENDING-APPOINTMENTS-CLINIC-SERVICE]`;
    logger.info(`${spanId} Fetching pending appointments for clinic ${clinicId}`);
    try {
      // STEP 1: Verify clinic exists
      const clinic = await prisma.clinic.findFirst({
        where: { id: clinicId, deletedAt: null },
      });

      if (!clinic) {
        logger.warn(`${spanId} Clinic ${clinicId} not found`);
        throw ApiResponse.error(404, 'Clinic not found');
      }

      // STEP 2: Fetch pending appointments for the clinic
      const appointments = await prisma.appointment.findMany({
        where: {
          status: 'PENDING',
          schedule: {
            clinicId,
            clinic: { deletedAt: null },
          },
          doctor: { deletedAt: null },
        },
        include: {
          patient: {
            select: {
              dob: true,
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  phone: true,
                  emailId: true,
                  gender: true,
                },
              },
            },
          },
          dependent: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              gender: true,
              dob: true,
              relation: true,
              phone: true,
              emailId: true,
            },
          },
          doctor: {
            select: {
              user: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                },
              },
            },
          },
          schedule: {
            select: {
              id: true,
              date: true,
              startTime: true,
              endTime: true,
            },
          },
        },
        orderBy: {
          createdAt: 'asc',
        },
      });

      // STEP 3: Format the response with proper patient/dependent details
      const formattedAppointments = appointments.map((appointment) => {
        const isDependent = appointment.bookedFor === 'DEPENDENT';

        // Helper function to format time to 12-hour format with AM/PM
        const formatTime = (timeString) => {
          if (!timeString) return '';

          const date = new Date(timeString);
          let hours = date.getUTCHours();
          let minutes = date.getUTCMinutes();

          const ampm = hours >= 12 ? 'pm' : 'am';
          hours = hours % 12;
          hours = hours ? hours : 12; // the hour '0' should be '12'
          minutes = minutes < 10 ? '0' + minutes : minutes;

          return `${hours}:${minutes} ${ampm}`;
        };

        // Prepare patient/dependent details based on bookedFor
        let patientDetails;
        if (isDependent && appointment.dependent) {
          patientDetails = {
            firstName: appointment.dependent.firstName,
            lastName: appointment.dependent.lastName,
            gender: appointment.dependent.gender,
            dob: appointment.dependent.dob,
            phone: appointment.dependent.phone || appointment.patient?.user?.phone,
            emailId: appointment.dependent.emailId || appointment.patient?.user?.emailId,
            relation: appointment.dependent.relation,
            bookedBy:
              `${appointment.patient?.user?.firstName || ''} ${appointment.patient?.user?.lastName || ''}`.trim(),
          };
        } else if (appointment.patient?.user) {
          patientDetails = {
            firstName: appointment.patient.user.firstName,
            lastName: appointment.patient.user.lastName,
            gender: appointment.patient.user.gender,
            dob: appointment.patient.dob,
            phone: appointment.patient.user.phone,
            emailId: appointment.patient.user.emailId,
          };
        }

        return {
          id: appointment.id,
          patientId: appointment.patientId,
          status: appointment.status,
          bookedFor: appointment.bookedFor,
          bookingType: appointment.bookingType,
          type: appointment.type,
          reason: appointment.reason,
          paymentStatus: appointment.paymentStatus,
          createdAt: appointment.createdAt,

          // Patient or Dependent details
          patientDetails,

          // Doctor details
          doctor: {
            doctorId: appointment.doctor?.user?.id,
            firstName: appointment.doctor?.user?.firstName,
            lastName: appointment.doctor?.user?.lastName,
          },

          // Schedule details
          schedule: {
            slotId: appointment.schedule?.id,
            date: appointment.schedule?.date,
            // startTime: formatTime(appointment.schedule?.startTime),
            // endTime: formatTime(appointment.schedule?.endTime),
            startTime: appointment.schedule?.startTime,
            endTime: appointment.schedule?.endTime,
          },
        };
      });

      logger.info(
        `${spanId} Retrieved ${formattedAppointments.length} pending appointments for clinic ${clinicId}`
      );
      return formattedAppointments;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error fetching pending appointments: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Approve an appointment
  static async approveAppointment(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[APPROVE-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Approving appointment ${appointmentId}`);
    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // STEP 1: Fetch the appointment
          const appointment = await tx.appointment.findUnique({
            where: { id: appointmentId },
          });
          // STEP 2: Validate appointment status
          if (!appointment) {
            logger.warn(`${spanId} Appointment ${appointmentId} not found`);
            throw ApiResponse.error(404, 'Appointment not found');
          }
          // STEP 3: Only PENDING appointments can be approved
          if (appointment.status !== 'PENDING') {
            logger.warn(`${spanId} Only PENDING appointments can be approved`);
            throw ApiResponse.error(400, 'Only PENDING appointments can be approved');
          }
          // STEP 4 : Get token number for the appointment
          const getTokenNo = await TokenService.getTokenNoForApprovedAppointment(
            tx,
            appointment.doctorId,
            appointment.doctorSlotScheduleId,
            appointment.patientId
          );
          // If no tokens are available, throw error
          if (getTokenNo === null) {
            logger.warn(
              `${spanId} No available tokens for slot ${appointment.doctorSlotScheduleId}`
            );
            throw ApiResponse.error(400, 'No available tokens for this slot');
          }
          // STEP 5: Update appointment with token number and CONFIRMED status
          console.log('Get Token No:', getTokenNo);
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: { status: 'CONFIRMED', tokenNo: getTokenNo },
          });
          return updatedAppointment;
        },
        {
          timeout: 10000,
        }
      );
      logger.info(`${spanId} Appointment ${appointmentId} approved successfully`);

      // Send notification to patient that appointment has been approved/confirmed
      await sendNotification({
        userId: result.patientId,
        type: NotificationTypes.APPOINTMENT_CONFIRMED,
        payload: { appointmentId: result.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });

      // Send initial SLOT_LIVE_UPDATE to trigger lock screen notification immediately after manual approval
      setImmediate(async () => {
        try {
          const appointmentDetails = await prisma.appointment.findFirst({
            where: { id: result.id, deletedAt: null },
            select: {
              tokenNo: true,
              patientId: true,
              doctor: {
                select: {
                  user: { select: { firstName: true, lastName: true } },
                },
              },
              schedule: {
                select: {
                  startTime: true,
                  clinic: { select: { name: true } },
                  hospital: { select: { name: true } },
                },
              },
            },
          });

          if (!appointmentDetails) return;

          const doctorFirstName = appointmentDetails.doctor?.user?.firstName || '';
          const doctorLastName = appointmentDetails.doctor?.user?.lastName || '';
          const doctorName = `Dr. ${doctorFirstName} ${doctorLastName}`.trim();
          const hospitalName =
            appointmentDetails.schedule?.clinic?.name ||
            appointmentDetails.schedule?.hospital?.name ||
            'eClinic-Q';
          const slotStartTime = appointmentDetails.schedule?.startTime;

          await sendNotification({
            userId: result.patientId,
            type: NotificationTypes.SLOT_LIVE_UPDATE,
            priority: 'high',
            channels: ['push'],
            data: {
              appointmentId: result.id,
              doctorName,
              hospitalName,
              yourToken: (result.tokenNo || appointmentDetails.tokenNo || 0).toString(),
              currentToken: '0',
              estimatedTime: slotStartTime ? new Date(slotStartTime).toISOString() : new Date().toISOString(),
              waitTimeMinutes: '0',
            },
          });
          logger.info(`${spanId} Initial SLOT_LIVE_UPDATE sent for manually approved appointment ${result.id}`);
        } catch (err) {
          logger.warn(`${spanId} Failed to send initial SLOT_LIVE_UPDATE for approved appointment:`, err);
        }
      });

      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error approving appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Reject an appointment
  static async rejectAppointment(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[REJECT-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Rejecting appointment ${appointmentId}`);
    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // STEP 1: Fetch the appointment
          const appointment = await tx.appointment.findUnique({
            where: { id: appointmentId },
          });
          // STEP 2: Validate appointment status
          if (!appointment) {
            logger.warn(`${spanId} Appointment ${appointmentId} not found`);
            throw ApiResponse.error(404, 'Appointment not found');
          }
          // STEP 3: Only PENDING appointments can be rejected
          if (appointment.status !== 'PENDING') {
            logger.warn(`${spanId} Only PENDING appointments can be rejected`);
            throw ApiResponse.error(400, 'Only PENDING appointments can be rejected');
          }
          // STEP 4: Update appointment status to CANCELLED
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: { status: 'CANCELLED' },
          });

          // STEP 5: Decrease booked tokens since this was a pending appointment
          await TokenService.decreaseBookedToken(
            tx,
            appointment.doctorId,
            appointment.doctorSlotScheduleId
          );

          return updatedAppointment;
        },
        {
          timeout: 10000,
        }
      );

      logger.info(`${spanId} Appointment ${appointmentId} rejected successfully`);
      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error rejecting appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Book Walk-In Appointment - Direct booking without payment (for SELF only)
  static async bookWalkInAppointment(appointmentData) {
    const logger = logWithTraceId();
    const spanId = `[BOOK-WALK-IN-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Booking walk-in appointment`);
    const { patientId, reason, slotId, bookingType } = appointmentData;

    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // STEP 1: Verify slot exists and get doctor info
          const slot = await tx.doctorSlotSchedule.findUnique({
            where: { id: slotId },
          });
          if (!slot) {
            logger.warn(`${spanId} Slot ${slotId} not found`);
            throw ApiResponse.error(404, 'Slot not found');
          }
          if (slot.slotStatus === 'CANCELLED') {
            logger.warn(`${spanId} Slot ${slotId} is cancelled`);
            throw ApiResponse.error(400, 'Slot is cancelled');
          }

          const doctorId = slot.doctorId;

          // STEP 2: Check if patient has already booked an appointment for the same slot
          const existingAppointment = await tx.appointment.findFirst({
            where: {
              patientId,
              doctorSlotScheduleId: slotId,
              bookedFor: 'SELF',
              status: {
                in: ['PENDING', 'CONFIRMED', 'CHECKED_IN', 'SERVED', 'NO_SHOW', 'ENGAGED'],
              },
            },
          });
          if (existingAppointment) {
            logger.warn(
              `${spanId} Patient ${patientId} has already booked an appointment for slot ${slotId}`
            );
            throw ApiResponse.error(400, 'You have already booked an appointment for this slot');
          }

          // STEP 3: Get token number for the appointment
          const tokenNo = await TokenService.getTokenNoForApprovedAppointment(
            tx,
            doctorId,
            slotId,
            patientId
          );

          // STEP 4: Create appointment with CONFIRMED status
          const appointment = await tx.appointment.create({
            data: {
              patientId,
              doctorId,
              bookedFor: 'SELF',
              doctorSlotScheduleId: slotId,
              reason,
              type: 'WALK_IN',
              bookingType: bookingType || 'NEW',
              status: 'CONFIRMED',
              paymentStatus: 'COMPLETED',
              tokenNo,
            },
          });

          logger.info(`${spanId} Walk-in appointment created with token: ${tokenNo}`);

          // STEP 5: Create/Update HospitalClinicPatientMapping
          if (slot.clinicId) {
            await tx.hospitalClinicPatientMapping.upsert({
              where: {
                clinicId_patientId: {
                  clinicId: slot.clinicId,
                  patientId,
                },
              },
              create: {
                clinicId: slot.clinicId,
                patientId,
              },
              update: {
                updatedAt: new Date(),
              },
            });
            logger.info(`${spanId} Mapped patient ${patientId} to clinic ${slot.clinicId}`);
          } else if (slot.hospitalId) {
            await tx.hospitalClinicPatientMapping.upsert({
              where: {
                hospitalId_patientId: {
                  hospitalId: slot.hospitalId,
                  patientId,
                },
              },
              create: {
                hospitalId: slot.hospitalId,
                patientId,
              },
              update: {
                updatedAt: new Date(),
              },
            });
            logger.info(`${spanId} Mapped patient ${patientId} to hospital ${slot.hospitalId}`);
          }

          return appointment;
        },
        {
          timeout: 10000,
        }
      );

      logger.info(`${spanId} Walk-in appointment booked successfully: ${result.id}`);

      // Send notification to patient that walk-in appointment is confirmed
      await sendNotification({
        userId: result.patientId,
        type: NotificationTypes.WALK_IN_APPOINTMENT_CONFIRMED,
        payload: { appointmentId: result.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });

      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error booking walk-in appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Book Walk-In Appointment for New Patient - Register patient and book appointment
  static async bookWalkInAppointmentForNewPatient(appointmentData) {
    const logger = logWithTraceId();
    const spanId = `[BOOK-WALK-IN-NEW-PATIENT-SERVICE]`;
    logger.info(`${spanId} Booking walk-in appointment for new patient`);
    const {
      firstName,
      lastName,
      phone,
      emailId,
      dob,
      gender,
      bloodGroup,
      reason,
      slotId,
      bookingType,
    } = appointmentData;

    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // STEP 1: Check if user with phone already exists
          const existingUser = await tx.user.findUnique({
            where: { phone },
          });
          if (existingUser) {
            logger.warn(`${spanId} User with phone ${phone} already exists`);
            throw ApiResponse.error(400, 'User with this phone number already exists');
          }

          // STEP 2: Check if email already exists (if provided)
          if (emailId) {
            const existingEmail = await tx.user.findUnique({
              where: { emailId },
            });
            if (existingEmail) {
              logger.warn(`${spanId} User with email ${emailId} already exists`);
              throw ApiResponse.error(400, 'User with this email already exists');
            }
          }

          // STEP 3: Verify slot exists and get doctor info
          const slot = await tx.doctorSlotSchedule.findUnique({
            where: { id: slotId },
          });
          if (!slot) {
            logger.warn(`${spanId} Slot ${slotId} not found`);
            throw ApiResponse.error(404, 'Slot not found');
          }
          if (slot.slotStatus === 'CANCELLED') {
            logger.warn(`${spanId} Slot ${slotId} is cancelled`);
            throw ApiResponse.error(400, 'Slot is cancelled');
          }

          const doctorId = slot.doctorId;

          // STEP 4: Create User account with default password
          const defaultPassword = 'default@123';
          const hashedPassword = await bcrypt.hash(defaultPassword, 10);
          const user = await tx.user.create({
            data: {
              firstName,
              lastName,
              phone,
              emailId: emailId || null,
              gender: gender || null,
              password: hashedPassword,
              phoneVerified: false,
              emailIdVerified: false,
              isActive: true,
            },
          });

          logger.info(`${spanId} User created with ID: ${user.id}`);

          // STEP 5: Create Patient record
          const patientCodeNumber = Math.floor(100000 + Math.random() * 900000);
          const patientCode = `PAT${patientCodeNumber}`;

          const patient = await tx.patient.create({
            data: {
              userId: user.id,
              patientCode,
              dob: new Date(dob),
              bloodGroup: bloodGroup || null,
            },
          });

          logger.info(`${spanId} Patient created with code: ${patientCode}`);

          // STEP 6: Assign PATIENT role
          const patientRole = await tx.role.findFirst({
            where: { name: 'PATIENT' },
          });

          if (patientRole) {
            await tx.userRole.create({
              data: {
                userId: user.id,
                roleId: patientRole.id,
              },
            });
            logger.info(`${spanId} PATIENT role assigned to user ${user.id}`);
          }

          // STEP 7: Get token number for the appointment
          const tokenNo = await TokenService.getTokenNoForApprovedAppointment(
            tx,
            doctorId,
            slotId,
            user.id
          );

          // STEP 8: Create appointment with CONFIRMED status
          const appointment = await tx.appointment.create({
            data: {
              patientId: user.id,
              doctorId,
              bookedFor: 'SELF',
              doctorSlotScheduleId: slotId,
              reason,
              type: 'WALK_IN',
              bookingType: bookingType || 'NEW',
              status: 'CONFIRMED',
              paymentStatus: 'COMPLETED',
              tokenNo,
            },
          });

          logger.info(
            `${spanId} Walk-in appointment created for new patient with token: ${tokenNo}`
          );

          // STEP 9: Create/Update HospitalClinicPatientMapping
          if (slot.clinicId) {
            await tx.hospitalClinicPatientMapping.upsert({
              where: {
                clinicId_patientId: {
                  clinicId: slot.clinicId,
                  patientId: user.id,
                },
              },
              create: {
                clinicId: slot.clinicId,
                patientId: user.id,
              },
              update: {
                updatedAt: new Date(),
              },
            });
            logger.info(`${spanId} Mapped new patient ${user.id} to clinic ${slot.clinicId}`);
          } else if (slot.hospitalId) {
            await tx.hospitalClinicPatientMapping.upsert({
              where: {
                hospitalId_patientId: {
                  hospitalId: slot.hospitalId,
                  patientId: user.id,
                },
              },
              create: {
                hospitalId: slot.hospitalId,
                patientId: user.id,
              },
              update: {
                updatedAt: new Date(),
              },
            });
            logger.info(`${spanId} Mapped new patient ${user.id} to hospital ${slot.hospitalId}`);
          }

          return {
            user,
            patient,
            appointment,
            tokenNo,
            patientCode,
          };
        },
        {
          timeout: 15000, // Increased timeout for multiple operations
        }
      );

      logger.info(
        `${spanId} Walk-in appointment booked successfully for new patient: ${result.patient.patientCode}`
      );

      // Send notification to new patient that walk-in appointment is confirmed
      await sendNotification({
        userId: result.user.id,
        type: NotificationTypes.WALK_IN_APPOINTMENT_CONFIRMED,
        payload: { appointmentId: result.appointment.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });

      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error booking walk-in appointment for new patient: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // reschedule an appointment - Doctor/admin/Frontdesk
  static async rescheduleAppointmentByStaff(data) {
    const logger = logWithTraceId();
    const spanId = `[RESCHEDULE-APPOINTMENT-BY-STAFF-SERVICE]`;
    const { appointmentId, newSlotId } = data;
    logger.info(`${spanId} Rescheduling appointment by staff`);
    try {
      const result = await prisma.$transaction(
        async (tx) => {
          // Fetch the existing appointment
          const existingAppointment = await tx.appointment.findUnique({
            where: { id: appointmentId },
          });
          if (!existingAppointment) {
            logger.warn(`${spanId} Appointment ${appointmentId} not found`);
            throw ApiResponse.error(404, 'Appointment not found');
          }
          if (existingAppointment.status === 'CANCELLED') {
            logger.warn(`${spanId} Cannot reschedule a cancelled appointment ${appointmentId}`);
            throw ApiResponse.error(400, 'Cannot reschedule a cancelled appointment');
          }
          if (existingAppointment.isRescheduled) {
            logger.warn(`${spanId} Appointment ${appointmentId} is already rescheduled once`);
            throw ApiResponse.error(400, 'Appointment is already rescheduled once');
          }
          // Checking that user has not already booked an appointment for the new slot
          const duplicateAppointment = await tx.appointment.findFirst({
            where: {
              patientId: existingAppointment.patientId,
              dependentId: existingAppointment.dependentId,
              doctorSlotScheduleId: newSlotId,
              bookedFor: existingAppointment.bookedFor,
              status: 'CONFIRMED',
            },
          });
          if (duplicateAppointment) {
            logger.warn(
              `${spanId} Patient ${existingAppointment.patientId} has already booked an appointment for slot ${newSlotId}`
            );
            throw ApiResponse.error(400, 'You have already booked an appointment for this slot');
          }
          // Verify new slot exists and belongs to the same doctor
          const newSlot = await tx.doctorSlotSchedule.findUnique({
            where: { id: newSlotId },
          });
          if (!newSlot || newSlot.doctorId !== existingAppointment.doctorId) {
            throw ApiResponse.error(400, 'Invalid slot for the appointment doctor');
          }
          const doctorId = existingAppointment.doctorId;
          await TokenService.decreaseBookedToken(
            tx,
            doctorId,
            existingAppointment.doctorSlotScheduleId
          );
          await TokenService.increaseBookedToken(
            tx,
            doctorId,
            newSlotId,
            existingAppointment.patientId
          );
          const getTokenNo = await TokenService.getTokenNoForApprovedAppointment(
            tx,
            doctorId,
            newSlotId,
            existingAppointment.patientId
          );
          if (getTokenNo === null) {
            logger.warn(`${spanId} No available tokens for slot ${newSlotId}`);
            throw ApiResponse.error(400, 'No available tokens for this slot');
          }
          // Update the appointment with the new slot and token number
          const updatedAppointment = await tx.appointment.update({
            where: { id: appointmentId },
            data: {
              doctorSlotScheduleId: newSlotId,
              tokenNo: getTokenNo,
              status: 'CONFIRMED',
              isRescheduled: true,
            },
          });
          await TokenService.updateToken(tx, existingAppointment.doctorSlotScheduleId);
          return updatedAppointment;
        },
        {
          timeout: 10000,
        }
      );
      logger.info(`${spanId} Appointment rescheduled successfully by staff`);
      return result;
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error rescheduling appointment by staff: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // change appointment status to CHECKED_IN
  static async checkInAppointment(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[CHECK-IN-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Checking in appointment ${appointmentId}`);
    try {
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: 'CHECKED_IN', checkInTimeStamp: new Date() },
      });

      // Publish event to Redis Stream for immediate ETA update
      try {
        await redisService.xadd(
          'slot_event_stream',
          '*',
          'eventType',
          'APPOINTMENT_CHECKIN',
          'slotId',
          updatedAppointment.doctorSlotScheduleId,
          'doctorId',
          updatedAppointment.doctorId,
          'appointmentId',
          updatedAppointment.id,
          'token',
          updatedAppointment.tokenNo.toString(),
          'timestamp',
          new Date().toISOString()
        );
        logger.info(`${spanId} Published APPOINTMENT_CHECKIN event to Redis`);
      } catch (redisError) {
        logger.error(`${spanId} Failed to publish Redis event: ${redisError.message}`);
        // Don't fail the request if Redis fails, just log it
      }

      // Emit dashboard WebSocket event
      dashboardEvents.emitQueueUpdate(
        updatedAppointment.doctorSlotScheduleId,
        'PATIENT_CHECKED_IN',
        { appointmentId: updatedAppointment.id }
      );

      logger.info(`${spanId} Appointment ${appointmentId} checked in successfully`);

      // Cache appointment metadata for ETA API (Async)
      (async () => {
        try {
          const fullDetails = await prisma.appointment.findUnique({
            where: { id: updatedAppointment.id },
            select: {
              doctorSlotScheduleId: true,
              status: true,
              tokenNo: true,
              doctor: { select: { avgDurationMinutes: true } },
              schedule: { select: { startTime: true, date: true } },
            },
          });
          if (fullDetails) {
            await cacheAppointmentMeta(updatedAppointment.id, fullDetails);
          }
        } catch (cacheErr) {
          logger.warn(`${spanId} Failed to cache appointment meta`, cacheErr);
        }
      })();
      // Send notification to patient that appointment is checked in
      await sendNotification({
        userId: updatedAppointment.patientId,
        type: NotificationTypes.APPOINTMENT_CHECKED_IN,
        payload: { appointmentId: updatedAppointment.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });
      return updatedAppointment;
    } catch (error) {
      logger.error(`${spanId} Error checking in appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // change appointment status to SERVED
  static async markAppointmentAsServed(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[MARK-APPOINTMENT-SERVED-SERVICE]`;
    logger.info(`${spanId} Marking appointment ${appointmentId} as SERVED`);
    try {
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: 'SERVED', servedTimeStamp: new Date() },
      });

      // Emit dashboard WebSocket event
      dashboardEvents.emitQueueUpdate(updatedAppointment.doctorSlotScheduleId, 'PATIENT_SERVED', {
        appointmentId: updatedAppointment.id,
      });

      logger.info(`${spanId} Appointment ${appointmentId} marked as SERVED successfully`);
      return updatedAppointment;
    } catch (error) {
      logger.error(`${spanId} Error marking appointment as SERVED: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // change appointment status to NO_SHOW
  static async markAppointmentAsNoShow(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[MARK-APPOINTMENT-NO-SHOW-SERVICE]`;
    logger.info(`${spanId} Marking appointment ${appointmentId} as NO_SHOW`);
    try {
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: 'NO_SHOW' },
      });

      // Emit dashboard WebSocket event
      dashboardEvents.emitQueueUpdate(updatedAppointment.doctorSlotScheduleId, 'PATIENT_NO_SHOW', {
        appointmentId: updatedAppointment.id,
      });

      logger.info(`${spanId} Appointment ${appointmentId} marked as NO_SHOW successfully`);
      // Send notification to patient that appointment is marked as NO_SHOW
      await sendNotification({
        userId: updatedAppointment.patientId,
        type: NotificationTypes.APPOINTMENT_NO_SHOW,
        payload: { appointmentId: updatedAppointment.id },
      }).catch((err) => {
        logger.warn(`${spanId} Failed to queue notification:`, err);
      });
      return updatedAppointment;
    } catch (error) {
      logger.error(`${spanId} Error marking appointment as NO_SHOW: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // change status to ENGAGED
  static async markAppointmentAsEngaged(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[MARK-APPOINTMENT-ENGAGED-SERVICE]`;
    logger.info(`${spanId} Marking appointment ${appointmentId} as ENGAGED`);
    try {
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: 'ENGAGED', engagedTimeStamp: new Date() },
      });

      // Emit dashboard WebSocket event
      dashboardEvents.emitQueueUpdate(updatedAppointment.doctorSlotScheduleId, 'PATIENT_ENGAGED', {
        appointmentId: updatedAppointment.id,
      });

      logger.info(`${spanId} Appointment ${appointmentId} marked as ENGAGED successfully`);
      return updatedAppointment;
    } catch (error) {
      logger.error(`${spanId} Error marking appointment as ENGAGED: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // GET - All Appointments by Slot with Patient/Dependent Details
  static async getAppointmentsBySlot(slotId) {
    const logger = logWithTraceId();
    const spanId = '[GET-APPOINTMENTS-BY-SLOT-SERVICE]';
    logger.info(`${spanId} Fetching appointments for slot ${slotId}`);

    try {
      // Fetch all appointments with required statuses
      const appointments = await prisma.appointment.findMany({
        where: {
          doctorSlotScheduleId: slotId,
          status: {
            in: [
              'CONFIRMED',
              'CHECKED_IN',
              'NO_SHOW',
              'ENGAGED',
              'SERVED',
              'CANCELLED',
              'CANCELLED_BY_DOCTOR',
            ],
          },
        },
        include: {
          patient: {
            include: {
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                  gender: true,
                  phone: true,
                  emailId: true,
                },
              },
            },
          },
          dependent: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              gender: true,
              dob: true,
              relation: true,
              phone: true,
              emailId: true,
            },
          },
          schedule: {
            select: {
              startTime: true,
              endTime: true,
              date: true,
              clinicId: true,
              hospitalId: true,
            },
          },
          doctor: {
            select: {
              clinics: {
                select: {
                  clinicId: true,
                  avgDurationMinutes: true,
                },
              },
              hospitals: {
                select: {
                  hospitalId: true,
                  avgDurationMinutes: true,
                },
              },
            },
          },
        },
        orderBy: {
          tokenNo: 'asc',
        },
      });

      // Get avgDurationMinutes from doctor's clinic/hospital mapping
      let avgDurationMinutes = 10; // default fallback
      if (appointments.length > 0) {
        const firstAppointment = appointments[0];
        const schedule = firstAppointment.schedule;
        const doctor = firstAppointment.doctor;

        if (schedule?.clinicId && doctor?.clinics) {
          const clinicMapping = doctor.clinics.find((c) => c.clinicId === schedule.clinicId);
          avgDurationMinutes = clinicMapping?.avgDurationMinutes || 10;
        } else if (schedule?.hospitalId && doctor?.hospitals) {
          const hospitalMapping = doctor.hospitals.find(
            (h) => h.hospitalId === schedule.hospitalId
          );
          avgDurationMinutes = hospitalMapping?.avgDurationMinutes || 10;
        }
      }

      // Get slot start time as base for expected time calculation
      const slotStartTime =
        appointments.length > 0 && appointments[0].schedule?.startTime
          ? new Date(appointments[0].schedule.startTime)
          : null;

      // Format the appointments based on bookedFor
      const formattedAppointments = appointments.map((appointment) => {
        const isDependent = appointment.bookedFor === 'DEPENDENT';

        // Calculate age
        let age = null;
        let dob = null;

        if (isDependent && appointment.dependent) {
          dob = new Date(appointment.dependent.dob);
        } else if (appointment.patient) {
          dob = new Date(appointment.patient.dob);
        }

        if (dob) {
          const today = new Date();
          age = today.getFullYear() - dob.getFullYear();
          const monthDiff = today.getMonth() - dob.getMonth();
          if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
            age--;
          }
        }

        // Prepare patient/dependent details
        let patientDetails;
        if (isDependent && appointment.dependent) {
          patientDetails = {
            name: `${appointment.dependent.firstName} ${appointment.dependent.lastName || ''}`.trim(),
            firstName: appointment.dependent.firstName,
            lastName: appointment.dependent.lastName,
            gender: appointment.dependent.gender,
            age: age,
            dob: appointment.dependent.dob,
            phone: appointment.dependent.phone || appointment.patient?.user?.phone,
            emailId: appointment.dependent.emailId || appointment.patient?.user?.emailId,
            relation: appointment.dependent.relation,
            bookedBy:
              `${appointment.patient?.user?.firstName || ''} ${appointment.patient?.user?.lastName || ''}`.trim(),
          };
        } else if (appointment.patient?.user) {
          patientDetails = {
            name: `${appointment.patient.user.firstName} ${appointment.patient.user.lastName || ''}`.trim(),
            firstName: appointment.patient.user.firstName,
            lastName: appointment.patient.user.lastName,
            gender: appointment.patient.user.gender,
            age: age,
            dob: appointment.patient.dob,
            phone: appointment.patient.user.phone,
            emailId: appointment.patient.user.emailId,
          };
        }

        // Calculate expected time based on token number and avgDurationMinutes
        // Token 1 starts at slotStartTime, Token 2 starts at slotStartTime + avgDurationMinutes, etc.
        let expectedTime = null;
        if (slotStartTime && appointment.tokenNo) {
          const tokensBeforeThis = appointment.tokenNo - 1;
          const waitMinutes = tokensBeforeThis * avgDurationMinutes;
          expectedTime = new Date(slotStartTime.getTime() + waitMinutes * 60 * 1000);
        }

        // Build the appointment response
        const appointmentResponse = {
          id: appointment.id,
          tokenNo: appointment.tokenNo,
          patientDetails,
          appointmentType: appointment.bookingType, // NEW or FOLLOW_UP
          bookingMode: appointment.type, // ONLINE or WALK_IN
          expectedTime: expectedTime ? expectedTime.toISOString() : null,
          reason: appointment.reason,
          status: appointment.status,
          bookedFor: appointment.bookedFor,
          createdAt: appointment.createdAt,
          updatedAt: appointment.updatedAt,
        };

        // Add appointment start/end time for ENGAGED and SERVED appointments
        if (appointment.status === 'SERVED') {
          appointmentResponse.appointmentStartTime = appointment.engagedTimeStamp || null;
          appointmentResponse.appointmentEndTime = appointment.servedTimeStamp || null;
        }

        return appointmentResponse;
      });

      // Grace period constant (30 minutes in milliseconds)
      const GRACE_PERIOD_MINUTES = 30;
      const GRACE_PERIOD_MS = GRACE_PERIOD_MINUTES * 60 * 1000;

      // Filter NO_SHOW appointments into within and outside grace period
      const noShowAppointments = formattedAppointments.filter((apt) => apt.status === 'NO_SHOW');
      const noShowWithinGracePeriod = noShowAppointments.filter((apt) => {
        if (!apt.expectedTime || !apt.updatedAt) return false;
        const expectedTime = new Date(apt.expectedTime).getTime();
        const markedNoShowAt = new Date(apt.updatedAt).getTime();
        const delayMs = markedNoShowAt - expectedTime;
        return delayMs <= GRACE_PERIOD_MS;
      });
      const noShowOutsideGracePeriod = noShowAppointments.filter((apt) => {
        if (!apt.expectedTime || !apt.updatedAt) return true; // If no time info, consider outside
        const expectedTime = new Date(apt.expectedTime).getTime();
        const markedNoShowAt = new Date(apt.updatedAt).getTime();
        const delayMs = markedNoShowAt - expectedTime;
        return delayMs > GRACE_PERIOD_MS;
      });

      // Group appointments by status for easy filtering
      const groupedAppointments = {
        checkedIn: formattedAppointments.filter((apt) => apt.status === 'CHECKED_IN'),
        inWaiting: formattedAppointments.filter((apt) => apt.status === 'CONFIRMED'),
        engaged: formattedAppointments.filter((apt) => apt.status === 'SERVED'),
        noShow: {
          withinGracePeriod: noShowWithinGracePeriod,
          outsideGracePeriod: noShowOutsideGracePeriod,
          all: noShowAppointments,
        },
        admitted: formattedAppointments.filter((apt) => apt.isAdmitted === true),
        all: formattedAppointments,
      };

      // Add counts
      const result = {
        counts: {
          checkedIn: groupedAppointments.checkedIn.length,
          inWaiting: groupedAppointments.inWaiting.length,
          engaged: groupedAppointments.engaged.length,
          noShow: {
            withinGracePeriod: noShowWithinGracePeriod.length,
            outsideGracePeriod: noShowOutsideGracePeriod.length,
            total: noShowAppointments.length,
          },
          admitted: groupedAppointments.admitted.length,
          all: formattedAppointments.length,
        },
        appointments: groupedAppointments,
      };

      logger.info(
        `${spanId} Fetched ${formattedAppointments.length} appointments for slot ${slotId}`
      );
      return result;
    } catch (error) {
      logger.error(`${spanId} Error fetching appointments by slot: ${error.message}`);
      if (error instanceof ApiResponse) throw error;
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // admit patient - change appointment status to ADMITTED
  static async admitPatient(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[ADMIT-PATIENT-SERVICE]`;
    logger.info(`${spanId} Admitting patient for appointment ${appointmentId}`);
    try {
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { isAdmitted: true },
      });

      // Emit dashboard WebSocket event
      dashboardEvents.emitQueueUpdate(updatedAppointment.doctorSlotScheduleId, 'PATIENT_ADMITTED', {
        appointmentId: updatedAppointment.id,
      });

      logger.info(`${spanId} Patient admitted for appointment ${appointmentId} successfully`);
      return updatedAppointment;
    } catch (error) {
      logger.error(`${spanId} Error admitting patient: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // mark pattient paid
  static async markAppointmentAsPaid(appointmentId) {
    const logger = logWithTraceId();
    const spanId = `[MARK-APPOINTMENT-PAID-SERVICE]`;
    logger.info(`${spanId} Marking appointment ${appointmentId} as PAID`);
    try {
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { isPaid: true },
      });
      logger.info(`${spanId} Appointment ${appointmentId} marked as PAID successfully`);
      return updatedAppointment;
    } catch (error) {
      logger.error(`${spanId} Error marking appointment as PAID: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  // Rate an appointment (1-5 stars) and add review comment
  static async rateAppointment(userId, appointmentId, rating, reviewComment = null) {
    const logger = logWithTraceId();
    const spanId = `[RATE-APPOINTMENT-SERVICE]`;
    logger.info(`${spanId} Rating appointment ${appointmentId} with ${rating} stars`);
    try {
      // Fetch the appointment
      const appointment = await prisma.appointment.findUnique({
        where: { id: appointmentId },
        select: {
          id: true,
          patientId: true,
          status: true,
          doctorId: true,
        },
      });

      if (!appointment) {
        logger.warn(`${spanId} Appointment ${appointmentId} not found`);
        throw ApiResponse.error(404, 'Appointment not found');
      }

      // Verify the patient owns this appointment
      if (appointment.patientId !== userId) {
        logger.warn(
          `${spanId} User ${userId} is not authorized to rate appointment ${appointmentId}`
        );
        throw ApiResponse.error(403, 'You are not authorized to rate this appointment');
      }

      // Only allow rating for SERVED appointments
      if (appointment.status !== 'SERVED') {
        logger.warn(
          `${spanId} Appointment ${appointmentId} status is ${appointment.status}, cannot rate`
        );
        throw ApiResponse.error(400, 'Only completed appointments can be rated');
      }

      // Update appointment with rating and reviewComment
      const updatedAppointment = await prisma.appointment.update({
        where: { id: appointmentId },
        data: {
          rating,
          reviewComment
        },
      });

      // Update doctor's average rating (Async or Sync)
      // Logic: Fetch all ratings for this doctor and compute average
      (async () => {
        try {
          const stats = await prisma.appointment.aggregate({
            where: {
              doctorId: appointment.doctorId,
              rating: { not: null }
            },
            _avg: {
              rating: true
            }
          });

          if (stats._avg.rating) {
            await prisma.doctor.update({
              where: { userId: appointment.doctorId },
              data: { rating: stats._avg.rating }
            });
          }
        } catch (avgErr) {
          console.error('Error updating doctor average rating:', avgErr);
        }
      })();

      logger.info(`${spanId} Appointment ${appointmentId} rated successfully with ${rating} stars`);
      return {
        id: updatedAppointment.id,
        rating: updatedAppointment.rating,
        reviewComment: updatedAppointment.reviewComment
      };
    } catch (error) {
      if (error instanceof ApiResponse) {
        throw error;
      }
      logger.error(`${spanId} Error rating appointment: ${error.message}`);
      throw ApiResponse.error(500, `Internal Server Error`, null);
    }
  }

  /**
   * @method getPatientHomeAppointmentBanners
   * @description Fetches appointment banners for patient home page
   * Shows different appointment states: requested, upcoming, active, and reschedule requests
   * Only returns today's and future appointments
   */
  static async getPatientHomeAppointmentBanners(patientId) {
    const logger = logWithTraceId();
    const spanId = '[GET-PATIENT-HOME-APPOINTMENT-BANNERS-SERVICE]';
    logger.info(`${spanId} - Fetching appointment banners for patient ${patientId}`);

    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Fetch all relevant appointments (today and future only)
      const appointments = await prisma.appointment.findMany({
        where: {
          patientId,
          status: {
            in: ['PENDING', 'CONFIRMED', 'CHECKED_IN', 'CANCELLED_BY_DOCTOR'],
          },
          schedule: {
            date: {
              gte: today, // Only today and future appointments
            },
          },
        },
        include: {
          doctor: {
            include: {
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                },
              },
              specialties: {
                include: {
                  specialty: {
                    select: {
                      name: true,
                    },
                  },
                },
                take: 1,
              },
            },
          },
          patient: {
            include: {
              user: {
                select: {
                  firstName: true,
                  lastName: true,
                },
              },
            },
          },
          schedule: {
            include: {
              hospital: {
                select: {
                  name: true,
                },
              },
              clinic: {
                select: {
                  name: true,
                },
              },
            },
          },
          dependent: {
            select: {
              firstName: true,
              lastName: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      logger.info(`${spanId} - Found ${appointments.length} appointments`);

      const banners = [];

      for (const appointment of appointments) {
        const slotDate = new Date(appointment.schedule.date);
        slotDate.setHours(0, 0, 0, 0);

        const isToday = slotDate.getTime() === today.getTime();
        const isFuture = slotDate > today;

        let bannerType;
        let additionalData = {};

        if (appointment.status === 'PENDING') {
          bannerType = 'REQUESTED';
        } else if (appointment.status === 'CANCELLED_BY_DOCTOR') {
          bannerType = 'RESCHEDULE';
          additionalData.cancellationReason = appointment.cancellationReason;
        } else if (appointment.status === 'CONFIRMED' || appointment.status === 'CHECKED_IN') {
          if (
            isToday &&
            (appointment.schedule.slotStatus === 'STARTED' ||
              appointment.schedule.slotStatus === 'DELAYED' ||
              appointment.schedule.slotStatus === 'PAUSED')
          ) {
            bannerType = 'ACTIVE';
            additionalData.currentToken = appointment.schedule.currentToken;
            additionalData.slotStatus = appointment.schedule.slotStatus;
          } else if (isFuture || isToday) {
            bannerType = 'UPCOMING';
          } else {
            continue; // Skip past appointments
          }
        } else {
          continue; // Skip other statuses
        }

        // Format time from DateTime to HH:MM AM/PM
        const formatTime = (timeString) => {
          if (!timeString) return null;
          const time = new Date(timeString);
          return time.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: true,
          });
        };

        // Format date to readable format
        const formatDate = (dateString) => {
          if (!dateString) return null;
          const date = new Date(dateString);
          return date.toLocaleDateString('en-US', {
            day: '2-digit',
            month: 'short',
          });
        };

        const doctorName = `Dr. ${appointment.doctor.user.firstName} ${appointment.doctor.user.lastName}`;
        const patientName =
          appointment.bookedFor === 'DEPENDENT' && appointment.dependent
            ? `${appointment.dependent.firstName} ${appointment.dependent.lastName}`
            : appointment.patient?.user
              ? `${appointment.patient.user.firstName} ${appointment.patient.user.lastName}`
              : null;

        banners.push({
          type: bannerType,
          appointmentId: appointment.id,
          doctorName,
          doctorSpecialization: appointment.doctor.specialties[0]?.specialty.name || null,
          tokenNumber: appointment.tokenNo,
          appointmentDate: appointment.schedule.date,
          appointmentDateFormatted: formatDate(appointment.schedule.date),
          appointmentTime: formatTime(appointment.schedule.startTime),
          hospitalName:
            appointment.schedule.hospital?.name || appointment.schedule.clinic?.name || null,
          bookedFor: appointment.bookedFor,
          patientName,
          status: appointment.status,
          ...additionalData,
        });
      }

      // Prioritize: ACTIVE > REQUESTED > RESCHEDULE > UPCOMING
      const priority = { ACTIVE: 1, REQUESTED: 2, RESCHEDULE: 3, UPCOMING: 4 };
      banners.sort((a, b) => priority[a.type] - priority[b.type]);

      logger.info(`${spanId} - Returning ${banners.length} banners`);

      return { banners };
    } catch (error) {
      logger.error(`${spanId} - Error fetching appointment banners:`, error);
      if (error instanceof ApiResponse) {
        throw error;
      }
      throw ApiResponse.error('Failed to fetch appointment banners', error?.message, 500);
    }
  }
}
export default AppointmentService;
