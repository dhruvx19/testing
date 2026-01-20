import 'dart:async';

import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/cancel_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/cancellation_policy_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/reschedule_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/provider/eta_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingConfirmedDetail extends StatefulWidget {
  final String appointmentId;
  final AppointmentDetailModel?
  appointment; // Optional for backward compatibility

  const BookingConfirmedDetail({
    super.key,
    required this.appointmentId,
    this.appointment,
  });

  @override
  State<BookingConfirmedDetail> createState() => _BookingConfirmedDetailState();
}

class _BookingConfirmedDetailState extends State<BookingConfirmedDetail> {
  AppointmentDetailModel? _appointment;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentTokenNumber;
  String? _expectedTime;
  bool _isLoadingETA = false;
  final _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    // If appointment is provided, use it directly (backward compatibility)
    if (widget.appointment != null) {
      _appointment = widget.appointment;
      _isLoading = false;
      _currentTokenNumber = _appointment!.currentTokenNumber;
      _expectedTime = _appointment!.expectedTime;
      _connectToWebSocket();
    } else {
      _loadAppointmentDetails();
    }
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication required. Please login again.';
          });
        }
        return;
      }

      final response = await _appointmentService.getAppointmentDetail(
        appointmentId: widget.appointmentId,
        authToken: authToken,
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message;
        });
        return;
      }

      // Convert API response to UI model
      final appointmentDetail = AppointmentDetailModel.fromApiData(
        response.data!,
      );

      if (!mounted) return;

      setState(() {
        _appointment = appointmentDetail;
        _isLoading = false;
        _currentTokenNumber = appointmentDetail.currentTokenNumber;
        _expectedTime = appointmentDetail.expectedTime;
      });

      _connectToWebSocket();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load appointment details: $e';
        });
      }
    }
  }

  Future<void> _connectToWebSocket() async {
    final etaProvider = Provider.of<ETAProvider>(context, listen: false);

    try {
      setState(() {
        _isLoadingETA = true;
      });

      // Connect to appointment room for real-time ETA updates
      await etaProvider.connectToAppointment(
        appointmentId: _appointment?.id ?? widget.appointmentId,
      );

      // Listen to ETA updates
      etaProvider.addListener(_onETAUpdate);

      setState(() {
        _isLoadingETA = false;
      });
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
      setState(() {
        _isLoadingETA = false;
      });
    }
  }

  void _onETAUpdate() {
    final etaProvider = Provider.of<ETAProvider>(context, listen: false);
    final etaUpdate = etaProvider.currentETA;

    if (etaUpdate != null && mounted) {
      setState(() {
        // Update expected time from ETA
        if (etaUpdate.eta != null) {
          try {
            final etaDate = DateTime.parse(etaUpdate.eta!);
            final timeFormat = DateFormat('hh:mm a');
            _expectedTime = timeFormat.format(etaDate);
          } catch (e) {
            print('Error parsing ETA date: $e');
          }
        }

        // Update status message if available
        if (etaUpdate.message != null) {
          // You can show a snackbar or update UI with the message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(etaUpdate.message!),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }

    // Also check for slot display updates (current token)
    final slotUpdate = etaProvider.currentSlotDisplay;
    if (slotUpdate != null && mounted) {
      setState(() {
        _currentTokenNumber = slotUpdate.currentToken.toString();
      });
    }
  }

  @override
  void dispose() {
    final etaProvider = Provider.of<ETAProvider>(context, listen: false);
    etaProvider.removeListener(_onETAUpdate);
    // Don't disconnect here - let the provider manage connection lifecycle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 58,
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Booking Details',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
        actions: [
          Row(
            children: [
              SvgPicture.asset(
                EcliniqIcons.questionCircleFilled.assetPath,
                width: 24,
                height: 24,
              ),
              Text(
                ' Help',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  color: Color(0xff424242),
                
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(width: 20),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _appointment == null
          ? _buildErrorWidget()
          : _buildContent(),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Status header shimmer
          Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            child: ShimmerLoading(borderRadius: BorderRadius.circular(12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor info card shimmer
                SizedBox(
                  height: 150,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Appointment details shimmer
                SizedBox(
                  height: 200,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Clinic location shimmer
                SizedBox(
                  height: 120,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 24),
                // Payment details shimmer
                SizedBox(
                  height: 100,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load appointment details',
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith( color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadAppointmentDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Fixed StatusHeader
        StatusHeader(
          status: _appointment!.status,
          tokenNumber: _appointment!.tokenNumber,
          expectedTime: _expectedTime ?? _appointment!.expectedTime,
          currentTokenNumber:
              _currentTokenNumber ?? _appointment!.currentTokenNumber,
        ),
        // Scrollable content starting from DoctorInfoCard
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAppointmentDetails,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DoctorInfoCard(
                      doctor: _appointment!.doctor,
                      clinic: _appointment!.clinic,
                      currentTokenNumber:
                          _currentTokenNumber ?? _appointment!.currentTokenNumber,
                    ),
                    // const SizedBox(height: 12),

                    // Show ETA connection status
                    // if (_isLoadingETA)
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(vertical: 8.0),
                    //     child: Row(
                    //       children: [
                    //         SizedBox(
                    //           width: 16,
                    //           height: 16,
                    //           child: EcliniqLoader(
                    //             size: 16,
                    //             color: Colors.blue,
                    //           ),
                    //         ),
                    //         const SizedBox(width: 8),
                    //         Text(
                    //           'Connecting for live updates...',
                    //           style: TextStyle(
                    //             fontSize: 12,
                    //             color: Colors.grey[600],
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),

                    // Show WebSocket connection status
                    const SizedBox(height: 24),
                    AppointmentDetailsSection(
                      patient: _appointment!.patient,
                      timeInfo: _appointment!.timeInfo,
                    ),
                    const SizedBox(height: 24),
                    ClinicLocationCard(clinic: _appointment!.clinic),
                    const SizedBox(height: 16),
                    Divider(color: Color(0xffB8B8B8), thickness: 0.5, height: 1),
                    const SizedBox(height: 24),

                    PaymentDetailsCard(payment: _appointment!.payment),
                    const SizedBox(height: 48),
                    _buildBottomButtons(context),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BookingActionButton(
            label: 'Reschedule',
            icon: EcliniqIcons.rescheduleIcon,
            type: BookingButtonType.reschedule,
            onPressed: () async {
              // Check if appointment is already rescheduled
              final isAlreadyRescheduled = _appointment?.isRescheduled ?? false;
              if (isAlreadyRescheduled) {
              
             CustomErrorSnackBar.show(
                    context: context,
                    title: 'Cannot Reschedule',
                    subtitle:
                        'This appointment has already been rescheduled. You cannot reschedule it again.',
                    duration: const Duration(seconds: 3),
                 
                );
                return;
              }

              final result = await EcliniqBottomSheet.show<bool>(
                context: context,
                child: RescheduleBottomSheet(appointment: _appointment!),
              );

              if (result == true && mounted && _appointment != null) {
                // Navigate to slot screen for reschedule
                final appointment = _appointment!;
                if (appointment.doctorId != null &&
                    (appointment.hospitalId != null ||
                        appointment.clinicId != null)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClinicVisitSlotScreen(
                        doctorId: appointment.doctorId!,
                        hospitalId: appointment.hospitalId,
                        clinicId: appointment.clinicId,
                        doctorName: appointment.doctor.name,
                        doctorSpecialization: appointment.doctor.specialization,
                        appointmentId: appointment.id,
                        previousAppointment: appointment,
                        isReschedule: true,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),
          BookingActionButton(
            label: 'Cancel Booking',
            icon: EcliniqIcons.rescheduleIcon,
            type: BookingButtonType.cancel,
            onPressed: () {
              EcliniqBottomSheet.show(
                context: context,
                child: CancelBottomSheet(
                  appointmentId: widget.appointmentId,
                  onCancelled: () async {
                    // Show shimmer loading state
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                    }

                    // Reload appointment details to get updated status
                    await _loadAppointmentDetails();

                    // Check if status changed to cancelled
                    if (mounted &&
                        _appointment != null &&
                        (_appointment!.status.toLowerCase() == 'cancelled' ||
                            _appointment!.status.toLowerCase() == 'failed')) {
                      // Navigate to cancelled detail page
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => BookingCancelledDetail(
                            appointmentId: widget.appointmentId,
                            appointment: _appointment,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: const CancellationPolicyBottomSheet(),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Cancellation Policy',
                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
            
                    color: Color(0xff424242),
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  EcliniqIcons.infoCircleBlack.assetPath,
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
