import { redisService } from '../../externalSystems/redis/redis.js';
import prisma from '../../config/database.js';
import { logWithTraceId } from '../../utils/logger.js';
import { config } from '../../config/enviroment.js';
import ActiveSlotTracker from '../../utils/activeSlotTracker.js';
import { storeAppointmentEta } from '../../utils/etaCache.js';
import { sendNotification } from '../../queues/notificationQueue.js';
import { NotificationTypes } from '../../utils/notificationTypes.js';

const STREAM_KEY = 'slot_event_stream';
const GROUP = 'eta_consumers';
const CONSUMER = `eta_consumer_${process.pid}`;
const PERIODIC_UPDATE_INTERVAL = Number(process.env.ETA_UPDATE_INTERVAL_MS) || 5 * 60 * 1000; // Default 5 minutes

class ETAWorker {
  constructor() {
    this.logger = logWithTraceId();
    this.isRunning = false;
    this.periodicUpdateInterval = null;
  }

  /**
   * Ensure consumer group exists for the stream
   */
  async ensureGroup() {
    try {
      await redisService.xgroupCreate(STREAM_KEY, GROUP, '0', true);
      this.logger.info('[ETA-WORKER] Consumer group created or already exists');
    } catch (err) {
      if (!err.message.includes('BUSYGROUP')) {
        this.logger.error('[ETA-WORKER] Error creating consumer group:', err);
        throw err;
      }
    }
  }

  /**
   * Fetch pending appointments for a slot (only CONFIRMED and CHECKED_IN)
   */
  async fetchPendingAppointments(slotId) {
    const appointments = await prisma.appointment.findMany({
      where: {
        doctorSlotScheduleId: slotId,
        status: {
          in: ['CONFIRMED', 'CHECKED_IN'],
        },
      },
      orderBy: {
        tokenNo: 'asc',
      },
      select: {
        id: true,
        tokenNo: true,
        patientId: true,
      },
    });
    return appointments;
  }

  /**
   * Get doctor's average duration in minutes
   */
  async getDoctorAvgMinutes(doctorId) {
    const doctor = await prisma.doctor.findUnique({
      where: { userId: doctorId },
      select: { avgDurationMinutes: true },
    });

    if (doctor?.avgDurationMinutes) {
      return Number(doctor.avgDurationMinutes);
    }

    // Fallback to environment variable or default 10 minutes
    return Number(process.env.BASE_AVG_DURATION_MINUTES || 10);
  }

  /**
   * STANDARDIZED: Calculate positions ahead and wait time
   * This ensures event-driven and periodic paths produce identical results
   *
   * @param {number} tokenNo - Patient's token number
   * @param {number} currentToken - Doctor's current token (0 if idle)
   * @param {number} avgDuration - Average duration per patient in minutes
   * @returns {object} - { positionsAhead, waitMinutes }
   */
  calculatePositionsAndWait(tokenNo, currentToken, avgDuration) {
    // Calculate positions ahead (how many people before this patient)
    const positionsAhead = tokenNo - currentToken - 1;

    // If doctor is idle (currentToken=0), first patient still waits avgDuration
    // If doctor is busy (currentToken>0), calculate based on queue
    const effectivePositions = currentToken === 0 ? 1 : positionsAhead + 1;
    const waitMinutes = Math.max(0, effectivePositions * avgDuration);

    return {
      positionsAhead: Math.max(0, positionsAhead + 1), // For display (always >= 1)
      waitMinutes: Math.round(waitMinutes),
    };
  }

  /**
   * STANDARDIZED: Construct slot start datetime from date and time objects
   *
   * @param {Date|string} slotDate - Slot date
   * @param {Date|string} slotTime - Slot time
   * @returns {Date} - Combined slot start datetime
   */
  constructSlotStart(slotDate, slotTime) {
    const slotStart = new Date(slotDate);
    const timeParts = new Date(slotTime).toISOString().split('T')[1];
    slotStart.setHours(
      parseInt(timeParts.substring(0, 2)),
      parseInt(timeParts.substring(3, 5)),
      0,
      0
    );
    return slotStart;
  }

  /**
   * STANDARDIZED: Calculate base time for ETA calculations
   * Priority: eventSlotStartTime > slot.date+startTime > now
   *
   * @param {object} slot - Slot object with date and startTime
   * @param {string} eventSlotStartTime - Optional slot start time from event
   * @returns {Date} - Base time for ETA calculation
   */
  getBaseTime(slot, eventSlotStartTime = null) {
    let baseTime = new Date();

    // Priority 1: Use event-provided slot start time if available
    if (eventSlotStartTime) {
      const eventStart = new Date(eventSlotStartTime);
      if (eventStart > baseTime) {
        baseTime = eventStart;
      }
    }
    // Priority 2: Construct from slot.date + slot.startTime
    else if (slot?.date && slot?.startTime) {
      const slotStart = this.constructSlotStart(slot.date, slot.startTime);
      if (slotStart > baseTime) {
        baseTime = slotStart;
      }
    }

    return baseTime;
  }

  /**
   * STANDARDIZED: Check if slot is paused and get pause duration
   *
   * @param {string} slotId - Slot ID
   * @param {string} slotStatus - Current slot status
   * @returns {number} - Pause duration in minutes (0 if not paused)
   */
  async getPauseDuration(slotId, slotStatus) {
    if (slotStatus !== 'PAUSED') {
      return 0;
    }

    const redisKey = `pause_duration:${slotId}`;
    const cachedDuration = await redisService.get(redisKey);
    return cachedDuration ? parseInt(cachedDuration) : 5; // Default 5 minutes
  }

  /**
   * SIMPLIFIED: Store slot status in Redis for polling API
   * Replaces WebSocket publishing with simple caching
   */
  async storeSlotStatus(slotId, doctorId, slotStatus, currentToken) {
    const key = `slot:status:${slotId}`;
    const data = {
      slotId,
      doctorId,
      slotStatus,
      currentToken,
      lastUpdated: new Date().toISOString(),
    };

    try {
      await redisService.setex(key, 86400, JSON.stringify(data)); // 24 hour TTL
      this.logger.info(`[ETA-WORKER] Stored slot status in Redis: ${key}`);
    } catch (err) {
      this.logger.error('[ETA-WORKER] Failed to store slot status:', err);
    }
  }

  /**
   * Calculate ETA for all pending appointments
   * REFACTORED: Uses standardized helper functions for consistency
   */
  async calculateAndPublishETA(eventData) {
    const {
      eventType,
      doctorId,
      slotId,
      token,
      timestamp,
      slotStartTime,
      delayMinutes,
      currentToken: eventCurrentToken,
      isOutOfOrder,
    } = eventData;

    this.logger.info(`[ETA-WORKER] Processing event: ${eventType}`, {
      doctorId,
      slotId,
      token,
      delayMinutes,
      isOutOfOrder,
    });

    // Skip calculation only for SLOT_ENDED events
    if (eventType === 'SLOT_ENDED') {
      this.logger.info(`[ETA-WORKER] Skipping ETA calculation for ${eventType}`);
      return;
    }

    // FIX #3: Fetch slot info to check pause status
    const slot = await prisma.doctorSlotSchedule.findUnique({
      where: { id: slotId },
      select: {
        id: true,
        slotStatus: true,
        date: true,
        startTime: true,
      },
    });

    if (!slot) {
      this.logger.warn(`[ETA-WORKER] Slot ${slotId} not found`);
      return;
    }

    // Fetch all pending appointments
    const pendingAppointments = await this.fetchPendingAppointments(slotId);

    if (pendingAppointments.length === 0) {
      this.logger.info('[ETA-WORKER] No pending appointments found');
      return;
    }

    // Get doctor's average duration
    const avgDurationMinutes = await this.getDoctorAvgMinutes(doctorId);

    // FIX #2: Use standardized base time calculation
    let baseTime = this.getBaseTime(slot, slotStartTime);

    // FIX #3: Add pause duration if slot is paused
    const pauseDuration = await this.getPauseDuration(slotId, slot.slotStatus);
    if (pauseDuration > 0) {
      baseTime = new Date(baseTime.getTime() + pauseDuration * 60 * 1000);
      this.logger.info(`[ETA-WORKER] Added ${pauseDuration} minutes pause to base time`);
    }

    // Parse additional delay if present (for SLOT_STARTED with delay or SESSION_PAUSED)
    const additionalDelayMinutes = delayMinutes ? Number(delayMinutes) : 0;
    if (additionalDelayMinutes > 0) {
      baseTime = new Date(baseTime.getTime() + additionalDelayMinutes * 60 * 1000);
    }

    const updates = [];

    // Use eventCurrentToken if provided (handles out-of-order), otherwise use token
    const effectiveCurrentToken = eventCurrentToken
      ? Number(eventCurrentToken)
      : token
        ? Number(token)
        : 0;
    const servingToken = token ? Number(token) : 0;

    // If SESSION_ENDED or SESSION_STARTED, send completion notification to the current patient
    if ((eventType === 'SESSION_ENDED' || eventType === 'SESSION_STARTED') && servingToken > 0) {
      // Find the appointment for the current/completed token
      const completedAppointment = await prisma.appointment.findFirst({
        where: {
          doctorSlotScheduleId: slotId,
          tokenNo: servingToken,
        },
        select: {
          id: true,
          patientId: true,
          status: true,
        },
      });

      if (completedAppointment) {
        if (eventType === 'SESSION_STARTED') {
          // Patient is currently being served
          updates.push({
            appointmentId: completedAppointment.id,
            patientId: completedAppointment.patientId,
            token: servingToken,
            eta: new Date().toISOString(),
            waitMinutes: 0,
            positionsAhead: 0,
            status: 'engaged', // Currently with doctor
          });

          // Store in Redis
          await storeAppointmentEta(slotId, completedAppointment.id, {
            appointmentId: completedAppointment.id,
            patientId: completedAppointment.patientId,
            token: servingToken,
            eta: new Date().toISOString(),
            waitMinutes: 0,
            positionsAhead: 0,
            status: 'engaged',
          });
        } else if (eventType === 'SESSION_ENDED' && completedAppointment.status === 'SERVED') {
          // Patient session completed
          updates.push({
            appointmentId: completedAppointment.id,
            patientId: completedAppointment.patientId,
            token: servingToken,
            eta: new Date().toISOString(),
            waitMinutes: 0,
            positionsAhead: 0,
            status: 'completed', // Session finished
          });

          // Store in Redis
          await storeAppointmentEta(slotId, completedAppointment.id, {
            appointmentId: completedAppointment.id,
            patientId: completedAppointment.patientId,
            token: servingToken,
            eta: new Date().toISOString(),
            waitMinutes: 0,
            positionsAhead: 0,
            status: 'completed',
          });
        }
      }
    }

    // FIX #7: Handle out-of-order sessions properly
    for (const appointment of pendingAppointments) {
      const appointmentToken = Number(appointment.tokenNo);

      // If this is the token being served out-of-order
      if (isOutOfOrder && appointmentToken === servingToken) {
        updates.push({
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          token: appointmentToken,
          eta: new Date().toISOString(),
          waitMinutes: 0,
          positionsAhead: 0,
          status: 'engaged',
        });

        await storeAppointmentEta(slotId, appointment.id, {
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          token: appointmentToken,
          eta: new Date().toISOString(),
          waitMinutes: 0,
          positionsAhead: 0,
          status: 'engaged',
        });
        continue;
      }

      // Skip tokens that are completed
      if (effectiveCurrentToken > 0 && appointmentToken < effectiveCurrentToken) {
        continue;
      }

      // FIX #1 & #10: Use standardized calculation
      const { positionsAhead, waitMinutes } = this.calculatePositionsAndWait(
        appointmentToken,
        effectiveCurrentToken,
        avgDurationMinutes
      );

      const etaDate = new Date(baseTime.getTime() + waitMinutes * 60 * 1000);
      const isServing = effectiveCurrentToken > 0 && appointmentToken === effectiveCurrentToken;

      updates.push({
        appointmentId: appointment.id,
        patientId: appointment.patientId,
        token: appointmentToken,
        eta: etaDate.toISOString(),
        waitMinutes,
        positionsAhead,
        status: isServing ? 'engaged' : 'waiting',
      });

      // Persist to Redis hash for fast API lookup
      await storeAppointmentEta(slotId, appointment.id, {
        appointmentId: appointment.id,
        patientId: appointment.patientId,
        token: appointmentToken,
        eta: etaDate.toISOString(),
        waitMinutes,
        positionsAhead,
        status: isServing ? 'engaged' : 'waiting',
      });

      // Only fire lock screen updates if queue actually started
      if (effectiveCurrentToken > 0) {
        // Send silent FCM update for lock screen (SLOT_LIVE_UPDATE)
        sendNotification({
          userId: appointment.patientId,
          type: NotificationTypes.SLOT_LIVE_UPDATE,
          priority: 'high',
          channels: ['push'], // Silent data-only push
          data: {
            appointmentId: appointment.id,
            doctorName: eventData.doctorName || 'Your Doctor',
            hospitalName: eventData.hospitalName || 'eClinic-Q',
            yourToken: appointmentToken.toString(),
            currentToken: effectiveCurrentToken.toString(),
            estimatedTime: etaDate.toISOString(),
            waitTimeMinutes: waitMinutes.toString(),
          },
        }).catch((err) => {
          this.logger.warn(`[ETA-WORKER] Failed to queue SLOT_LIVE_UPDATE for ${appointment.id}:`, err);
        });
      }
    }

    // SIMPLIFIED: Store slot status in Redis (no WebSocket publishing)
    await this.storeSlotStatus(slotId, doctorId, slot.slotStatus, effectiveCurrentToken);

    this.logger.info(
      `[ETA-WORKER] Updated ${pendingAppointments.length} appointments for slot ${slotId}`
    );
  }

  /**
   * Handle a single message from the stream
   */
  async handleMessage(id, fields) {
    try {
      // Convert fields array to object
      const eventData = {};
      for (let i = 0; i < fields.length; i += 2) {
        eventData[fields[i]] = fields[i + 1];
      }

      await this.calculateAndPublishETA(eventData);

      // Acknowledge the message
      await redisService.xack(STREAM_KEY, GROUP, id);
    } catch (err) {
      this.logger.error(`[ETA-WORKER] Error handling message: ${err.message}`, err.stack);
      // Still acknowledge to avoid infinite retries
      await redisService.xack(STREAM_KEY, GROUP, id);
    }
  }

  /**
   * Claim and process pending messages (failure recovery)
   */
  async claimAndProcessPending() {
    try {
      const pendingInfo = await redisService.xpending(STREAM_KEY, GROUP, '-', '+', 10);

      for (const entry of pendingInfo) {
        const [msgId, consumer, msSince] = entry;

        // Claim messages idle for more than 60 seconds
        if (msSince > 60_000) {
          try {
            const claimed = await redisService.xclaim(STREAM_KEY, GROUP, CONSUMER, 60_000, msgId);

            if (claimed && claimed.length > 0) {
              const [id, fields] = claimed[0];
              await this.handleMessage(id, fields);
            }
          } catch (err) {
            this.logger.error('[ETA-WORKER] Error claiming message:', err);
          }
        }
      }
    } catch (err) {
      this.logger.error('[ETA-WORKER] Error processing pending messages:', err);
    }
  }

  /**
   * Update ETAs for all active slots (periodic background job)
   * OPTIMIZED: Uses Redis-based active slot tracking instead of DB query
   */
  async updateAllActiveSlotETAs() {
    try {
      this.logger.info('[ETA-WORKER-PERIODIC] Starting periodic ETA update');

      // OPTIMIZED: Get active slot IDs from Redis instead of DB
      const activeSlotIds = await ActiveSlotTracker.getActiveSlotIds();

      if (activeSlotIds.length === 0) {
        this.logger.info('[ETA-WORKER-PERIODIC] No active slots found');
        return;
      }

      this.logger.info(
        `[ETA-WORKER-PERIODIC] Found ${activeSlotIds.length} active slots to update`
      );

      // OPTIMIZED: Batch query appointment counts to find slots with waiting patients
      const appointmentCounts = await prisma.appointment.groupBy({
        by: ['doctorSlotScheduleId'],
        where: {
          doctorSlotScheduleId: { in: activeSlotIds },
          status: {
            in: ['CONFIRMED', 'CHECKED_IN'],
          },
        },
        _count: { id: true },
      });

      // Filter to slots that have waiting patients
      const slotsWithPatients = appointmentCounts
        .filter(({ _count }) => _count.id > 0)
        .map(({ doctorSlotScheduleId }) => doctorSlotScheduleId);

      if (slotsWithPatients.length === 0) {
        this.logger.info('[ETA-WORKER-PERIODIC] No waiting patients found in active slots');
        return;
      }

      this.logger.info(
        `[ETA-WORKER-PERIODIC] Found ${slotsWithPatients.length} slots with waiting patients`
      );

      // OPTIMIZED: Only fetch slot details for slots with patients
      const activeSlots = await prisma.doctorSlotSchedule.findMany({
        where: {
          id: { in: slotsWithPatients },
        },
        select: {
          id: true,
          doctorId: true,
          currentToken: true,
          slotStatus: true,
          startTime: true,
          date: true,
        },
      });

      this.logger.info(`[ETA-WORKER-PERIODIC] Processing ${activeSlots.length} active slots`);

      // OPTIMIZED: Batch fetch ALL appointments for these slots in ONE query
      // This prevents opening N connections for N slots
      const allAppointments = await prisma.appointment.findMany({
        where: {
          doctorSlotScheduleId: { in: slotsWithPatients },
          status: { in: ['CONFIRMED', 'CHECKED_IN'] },
        },
        include: {
          doctor: {
            select: { avgDurationMinutes: true },
          },
        },
        orderBy: { tokenNo: 'asc' },
      });

      // Group appointments by slot ID for processing
      const appointmentsBySlot = {};
      allAppointments.forEach((app) => {
        if (!appointmentsBySlot[app.doctorSlotScheduleId]) {
          appointmentsBySlot[app.doctorSlotScheduleId] = [];
        }
        appointmentsBySlot[app.doctorSlotScheduleId].push(app);
      });

      // Process each slot using in-memory appointments
      for (const slot of activeSlots) {
        const slotAppointments = appointmentsBySlot[slot.id] || [];
        await this.recalculateSlotETAs(slot, slotAppointments);
      }

      this.logger.info('[ETA-WORKER-PERIODIC] Periodic ETA update completed');
    } catch (err) {
      this.logger.error('[ETA-WORKER-PERIODIC] Error updating ETAs:', err);
    }
  }

  /**
   * REFACTORED: Recalculate ETAs using provided appointments (no DB query)
   * Now uses standardized helpers for consistency
   */
  async recalculateSlotETAs(slot, preFetchedAppointments = null) {
    try {
      let appointments = preFetchedAppointments;

      // Fallback to DB query if not provided (for backward compatibility or single calls)
      if (!appointments) {
        appointments = await prisma.appointment.findMany({
          where: {
            doctorSlotScheduleId: slot.id,
            status: { in: ['CONFIRMED', 'CHECKED_IN'] },
            tokenNo: { gte: slot.currentToken > 0 ? slot.currentToken : 1 },
          },
          include: {
            doctor: {
              select: { avgDurationMinutes: true },
            },
          },
          orderBy: { tokenNo: 'asc' },
        });
      } else {
        // Filter pre-fetched appointments for those waiting or currently engaged
        appointments = appointments.filter((app) => app.tokenNo >= slot.currentToken);
      }

      if (appointments.length === 0) {
        return; // No waiting patients
      }

      // FIX #2: Use standardized base time calculation
      let baseTime = this.getBaseTime(slot);

      // FIX #3: Add pause duration if slot is paused
      const pauseDuration = await this.getPauseDuration(slot.id, slot.slotStatus);
      if (pauseDuration > 0) {
        baseTime = new Date(baseTime.getTime() + pauseDuration * 60 * 1000);
        this.logger.info(
          `[ETA-WORKER-PERIODIC] Added ${pauseDuration} minutes pause for slot ${slot.id}`
        );
      }

      const updates = [];
      const avgDurationMinutes = appointments[0]?.doctor?.avgDurationMinutes || 10;

      for (const appointment of appointments) {
        // FIX #1 & #10: Use standardized calculation
        const { positionsAhead, waitMinutes } = this.calculatePositionsAndWait(
          appointment.tokenNo,
          slot.currentToken,
          avgDurationMinutes
        );

        const etaDate = new Date(baseTime.getTime() + waitMinutes * 60 * 1000);

        updates.push({
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          token: appointment.tokenNo,
          eta: etaDate.toISOString(),
          waitMinutes,
          positionsAhead,
          status: appointment.status,
        });

        // Persist to Redis hash for fast API lookup
        await storeAppointmentEta(slot.id, appointment.id, {
          appointmentId: appointment.id,
          patientId: appointment.patientId,
          token: appointment.tokenNo,
          eta: etaDate.toISOString(),
          waitMinutes,
          positionsAhead,
          status: appointment.status,
        });

        // Only fire if the queue has actually started
        if (slot.currentToken > 0) {
          // Send silent FCM update for lock screen (SLOT_LIVE_UPDATE)
          sendNotification({
            userId: appointment.patientId,
            type: NotificationTypes.SLOT_LIVE_UPDATE,
            priority: 'high',
            channels: ['push'], // Silent data-only push
            data: {
              appointmentId: appointment.id,
              doctorName: slot.doctorName || 'Your Doctor',
              hospitalName: slot.hospitalName || 'eClinic-Q',
              yourToken: appointment.tokenNo.toString(),
              currentToken: slot.currentToken.toString(),
              estimatedTime: etaDate.toISOString(),
              waitTimeMinutes: waitMinutes.toString(),
            },
          }).catch((err) => {
            this.logger.warn(`[ETA-WORKER-PERIODIC] Failed to queue SLOT_LIVE_UPDATE for ${appointment.id}:`, err);
          });
        }
      }

      // SIMPLIFIED: Store slot status in Redis (no WebSocket publishing)
      if (updates.length > 0) {
        await this.storeSlotStatus(slot.id, slot.doctorId, slot.slotStatus, slot.currentToken);

        this.logger.info(
          `[ETA-WORKER-PERIODIC] Updated ${updates.length} appointments for slot ${slot.id}`
        );
      }
    } catch (err) {
      this.logger.error(`[ETA-WORKER-PERIODIC] Error recalculating slot ${slot.id}:`, err);
    }
  }

  /**
   * Start periodic ETA updates
   */
  startPeriodicUpdates() {
    // Update ETAs every 2 minutes
    this.periodicUpdateInterval = setInterval(async () => {
      await this.updateAllActiveSlotETAs();
    }, PERIODIC_UPDATE_INTERVAL);

    this.logger.info(
      `[ETA-WORKER] Periodic ETA updates started (every ${PERIODIC_UPDATE_INTERVAL / 60000} minutes)`
    );
  }

  /**
   * Stop periodic ETA updates
   */
  stopPeriodicUpdates() {
    if (this.periodicUpdateInterval) {
      clearInterval(this.periodicUpdateInterval);
      this.periodicUpdateInterval = null;
      this.logger.info('[ETA-WORKER] Periodic ETA updates stopped');
    }
  }

  /**
   * Main worker loop
   */
  async run() {
    await this.ensureGroup();
    this.isRunning = true;

    this.logger.info('[ETA-WORKER] Started - Listening for slot events');

    // Sync active slots from DB to Redis (recovery)
    await ActiveSlotTracker.syncActiveSlotsFromDB();

    // Start periodic ETA updates
    this.startPeriodicUpdates();

    while (this.isRunning) {
      try {
        // Read from stream with blocking
        const result = await redisService.xreadgroup(
          'GROUP',
          GROUP,
          CONSUMER,
          'BLOCK',
          2000,
          'COUNT',
          10,
          'STREAMS',
          STREAM_KEY,
          '>'
        );

        if (!result) {
          // No new messages, check for pending/claimed messages
          await this.claimAndProcessPending();
          continue;
        }

        // Process messages
        const [, messages] = result[0];
        for (const [id, fields] of messages) {
          await this.handleMessage(id, fields);
        }
      } catch (err) {
        this.logger.error('[ETA-WORKER] Error in run loop:', err);
        // Wait a bit before retrying
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
    }
  }

  /**
   * Stop the worker
   */
  stop() {
    this.isRunning = false;
    this.stopPeriodicUpdates();
    this.logger.info('[ETA-WORKER] Stopping...');
  }
}

// Create and export singleton instance
const etaWorker = new ETAWorker();

// Handle graceful shutdown
process.on('SIGINT', () => {
  etaWorker.stop();
});

process.on('SIGTERM', () => {
  etaWorker.stop();
});

export default etaWorker;
