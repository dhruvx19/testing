import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/cancel_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/cancellation_policy_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/reschedule_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class BookingRequestedDetail extends StatefulWidget {
  final String appointmentId;
  final AppointmentDetailModel? appointment;

  const BookingRequestedDetail({
    super.key,
    required this.appointmentId,
    this.appointment,
  });

  @override
  State<BookingRequestedDetail> createState() => _BookingRequestedDetailState();
}

class _BookingRequestedDetailState extends State<BookingRequestedDetail> {
  AppointmentDetailModel? _appointment;
  bool _isLoading = true;
  String? _errorMessage;
  final _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();

    if (widget.appointment != null) {
      _appointment = widget.appointment;
      _isLoading = false;
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

      final appointmentDetail = AppointmentDetailModel.fromApiData(
        response.data!,
      );

      if (!mounted) return;

      setState(() {
        _appointment = appointmentDetail;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load appointment details: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: EcliniqTextStyles.getResponsiveSize(context, 56),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveSize(context, 44),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Booking Detail',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 0.5),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              EcliniqRouter.push(ProfileHelpPage());
            },
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.questionCircleFilled.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                ),
                Text(
                  ' Help',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                      .copyWith(
                        color: Color(0xff424242),

                        fontWeight: FontWeight.w400,
                      ),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 20)),
              ],
            ),
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
          Container(
            height: EcliniqTextStyles.getResponsiveHeight(context, 120),
            margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            child: ShimmerLoading(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
              ),
            ),
          ),
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 150),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),

                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 100),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),

                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 200),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),

                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 120),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),

                SizedBox(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 100),
                  child: ShimmerLoading(
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
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
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.red[300],
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
            Text(
              _errorMessage ?? 'Failed to load appointment details',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
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
        StatusHeader(
          status: _appointment!.status,
          currentTokenNumber: _appointment!.currentTokenNumber,
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DoctorInfoCard(
                    doctor: _appointment!.doctor,
                    clinic: _appointment!.clinic,
                    currentTokenNumber: _appointment!.currentTokenNumber,
                  ),

                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  _buildRequestNote(),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  AppointmentDetailsSection(
                    patient: _appointment!.patient,
                    timeInfo: _appointment!.timeInfo,
                  ),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
                  ClinicLocationCard(clinic: _appointment!.clinic),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
                  Divider(color: Color(0xffB8B8B8), thickness: 0.5, height: 1),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
                  PaymentDetailsCard(payment: _appointment!.payment),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 48)),
                  _buildBottomButtons(context),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 60)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestNote() {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E6),
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
        ),
        border: Border.all(color: const Color(0xFFBE8B00), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            EcliniqIcons.requestedIcon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12)),
          Expanded(
            child: Text(
              'Your booking request will be confirmed once the doctor approves it. You will receive your token number details via WhatsApp and SMS.',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Color(0xFF0D47A1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 6),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BookingActionButton(
            label: 'Reschedule',
            icon: EcliniqIcons.rescheduleIcon,
            type: BookingButtonType.reschedule,
            onPressed: () async {
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
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
          BookingActionButton(
            label: 'Cancel Booking',
            icon: EcliniqIcons.rescheduleCancel,
            type: BookingButtonType.cancel,
            onPressed: () {
              EcliniqBottomSheet.show(
                context: context,
                child: CancelBottomSheet(
                  appointmentId: widget.appointmentId,
                  onCancelled: () async {
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                    }

                    await _loadAppointmentDetails();

                    if (mounted &&
                        _appointment != null &&
                        (_appointment!.status.toLowerCase() == 'cancelled' ||
                            _appointment!.status.toLowerCase() == 'failed')) {
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
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
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
                  style: EcliniqTextStyles.responsiveBodySmall(context)
                      .copyWith(
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4)),
                SvgPicture.asset(
                  EcliniqIcons.infoCircleBlack.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
