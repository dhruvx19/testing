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
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
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
  Timer? _etaTimer;

  @override
  void initState() {
    super.initState();
    // If appointment is provided, use it directly (backward compatibility)
    if (widget.appointment != null) {
      _appointment = widget.appointment;
      _isLoading = false;
      _currentTokenNumber = _appointment!.currentTokenNumber;
      _expectedTime = _appointment!.expectedTime;
      _startEtaPolling();
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

      _startEtaPolling();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load appointment details: $e';
        });
      }
    }
  }

  void _startEtaPolling() {
    _fetchEtaOnce();
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(minutes: 3), (_) => _fetchEtaOnce());
  }

  Future<void> _fetchEtaOnce() async {
    if (!mounted) return;
    try {
      setState(() {
        _isLoadingETA = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;
      if (authToken == null) {
        setState(() {
          _isLoadingETA = false;
        });
        return;
      }

      final eta = await _appointmentService.getEtaStatus(
        appointmentId: _appointment?.id ?? widget.appointmentId,
        authToken: authToken,
      );

      if (!mounted) return;

      if (eta != null) {
        setState(() {
          // API returns tokenNo (current running token)
          final tokenNo = eta['tokenNo'];
          _currentTokenNumber = tokenNo?.toString() ?? _currentTokenNumber;
          // If appointmentStatus/slotStatus indicates completion, we could stop polling
          _isLoadingETA = false;
        });
      } else {
        setState(() {
          _isLoadingETA = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingETA = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
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
        // Current Running Token info (just after green area)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _isLoadingETA
              ? SizedBox(
                  height: 48,
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              : (_currentTokenNumber != null)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2FFF3),
                        border: Border.all(color: const Color(0xFF3EAF3F), width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.queue.assetPath,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Color(0xFF3EAF3F), BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current token running: ',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              color: const Color(0xFF3EAF3F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _currentTokenNumber ?? '-',
                            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                              color: const Color(0xFF3EAF3F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
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
