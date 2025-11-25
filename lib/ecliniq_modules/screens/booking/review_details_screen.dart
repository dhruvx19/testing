import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/request_sent.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/appointment_detail_item.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/clinic_location_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/doctor_info_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/reason_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/widgets/top_bar_widgets/easy_way_book.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart' hide DoctorInfoCard, ClinicLocationCard;
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewDetailsScreen extends StatefulWidget {
  final String selectedSlot;
  final String selectedDate;
  final String doctorId;
  final String? hospitalId;
  final String? clinicId;
  final String slotId;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? appointmentId;
  final AppointmentDetailModel? previousAppointment;
  final bool isReschedule;

  const ReviewDetailsScreen({
    super.key,
    required this.selectedSlot,
    required this.selectedDate,
    required this.doctorId,
    this.hospitalId,
    this.clinicId,
    required this.slotId,
    this.doctorName,
    this.doctorSpecialization,
    this.appointmentId,
    this.previousAppointment,
    this.isReschedule = false,
  }) : assert(
          hospitalId != null || clinicId != null,
          'Either hospitalId or clinicId must be provided',
        );

  @override
  State<ReviewDetailsScreen> createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends State<ReviewDetailsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final HospitalService _hospitalService = HospitalService();
  final TextEditingController _referByController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? selectedReason;
  bool receiveUpdates = true;
  bool _isBooking = false;
  String? _patientId;
  String? _authToken;
  String? _hospitalAddress;
  DependentData? _selectedDependent;

  final List<String> reasons = [
    'Fever',
    'Cold & Cough',
    'Body Pain',
    'Skin Issues',
    'Stomach Issues',
    'Routine checkup and consultation',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientId();
    _fetchHospitalAddress();
    
    // Pre-fill reason from previous appointment if rescheduling
    if (widget.isReschedule && widget.previousAppointment != null) {
      // The reason might be stored in the appointment, but it's not in AppointmentDetailModel
      // So we'll leave it empty for now
    }
  }

  Future<void> _fetchHospitalAddress() async {
    // Only fetch hospital address if hospitalId is provided (not for clinics)
    if (widget.hospitalId == null || widget.hospitalId!.isEmpty) return;

    try {
      final response = await _hospitalService.getHospitalDetails(
        hospitalId: widget.hospitalId!,
      );

      if (mounted && response.success && response.data != null) {
        final hospitalDetail = response.data!;
        final address = hospitalDetail.address;
        final parts = <String>[];

        if (address.street != null && address.street!.isNotEmpty) {
          parts.add(address.street!);
        }
        if (address.blockNo != null && address.blockNo!.isNotEmpty) {
          parts.add(address.blockNo!);
        }
        if (hospitalDetail.city.isNotEmpty) {
          parts.add(hospitalDetail.city);
        }
        if (hospitalDetail.state.isNotEmpty) {
          parts.add(hospitalDetail.state);
        }
        if (address.landmark != null && address.landmark!.isNotEmpty) {
          parts.add('Near ${address.landmark}');
        }

        setState(() {
          _hospitalAddress = parts.isEmpty
              ? 'Address not available'
              : parts.join(', ');
        });
      }
    } catch (e) {
      // Silently fail - address will be null
    }
  }

  @override
  void dispose() {
    _referByController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId =
        prefs.getString('patient_id') ??
        prefs.getString('patientId') ??
        prefs.getString('user_id');
    final authToken = prefs.getString('auth_token');

    setState(() {
      _patientId = patientId ?? '2ccb2364-9e21-40ad-a1f2-274b73553e44';
      _authToken = authToken;
    });
  }

  Future<void> _showReasonBottomSheet(BuildContext context) async {
    final String? selected = await EcliniqBottomSheet.show<String>(
      context: context,
      child: ReasonBottomSheet(
        reasons: reasons,
        selectedReason: selectedReason,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        selectedReason = selected;
      });
    }
  }

  String _formatDependentSubtitle(DependentData d) {
    String capitalize(String s) => s.isEmpty
        ? s
        : s[0].toUpperCase() + (s.length > 1 ? s.substring(1).toLowerCase() : '');

    final gender = capitalize(d.gender);
    String dobStr = '';
    if (d.dob != null) {
      final dd = d.dob!;
      final day = dd.day.toString().padLeft(2, '0');
      final month = dd.month.toString().padLeft(2, '0');
      dobStr = '$day/$month/${dd.year}';
    }
    final parts = <String>[];
    if (gender.isNotEmpty) parts.add(gender);
    if (dobStr.isNotEmpty) parts.add(dobStr);
    final age = d.age != null ? ' (${d.age})' : '';
    return parts.join(', ') + age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.isReschedule ? 'Reschedule' : 'Review Details',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),

        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, size: 24),
            label: Text(
              'Help',
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: Color(0xff424242),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              clipBehavior: Clip.none,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(child: const DoctorInfoCard()),

                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff424242),
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: AppointmentDetailItem(
                      iconAssetPath: EcliniqIcons.user.assetPath,
                      title: _selectedDependent?.fullName ?? 'Ketan Patni',
                      subtitle: _selectedDependent != null
                          ? _formatDependentSubtitle(_selectedDependent!)
                          : 'Male, 02/02/1996 (29Y)',
                      badge: _selectedDependent?.relation ?? 'You',
                      showEdit: true,
                      onDependentSelected: (dep) {
                        setState(() {
                          _selectedDependent = dep;
                        });
                      },
                    ),
                  ),
                  Divider(
                    thickness: 0.5,
                    color: Color(0xffB8B8B8),
                    indent: 15,
                    endIndent: 15,
                  ),
                  RepaintBoundary(
                    child: AppointmentDetailItem(
                      iconAssetPath: EcliniqIcons.calendar.assetPath,
                      title: widget.selectedSlot,
                      subtitle: widget.selectedDate,
                      showEdit: false,
                    ),
                  ),
                  Divider(
                    thickness: 0.5,
                    color: Color(0xffB8B8B8),
                    indent: 15,
                    endIndent: 15,
                  ),
                  RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClinicLocationCard(
                        hospitalId: widget.hospitalId ?? '',
                        clinicId: widget.clinicId,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Reason for Visit',
                      style: EcliniqTextStyles.headlineXMedium.copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => _showReasonBottomSheet(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        key: const ValueKey('reason_field'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xff626060)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedReason ?? 'Enter Reason for Visit',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: selectedReason != null
                                      ? Colors.black
                                      : const Color(0xffD6D6D6),
                                      fontWeight: FontWeight.w400
                                ),
                              ),
                            ),
                            SvgPicture.asset(
                              EcliniqIcons.arrowDown.assetPath,
                              width: 24,
                              height: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Refer By',
                      style: EcliniqTextStyles.headlineXMedium.copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      key: const ValueKey('refer_by_field'),
                      controller: _referByController,
                      decoration: InputDecoration(
                        hintText: 'Enter Who Refer you',
                        hintStyle: const TextStyle(color: Color(0xffD6D6D6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff626060),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff626060),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: EcliniqTextStyles.headlineLarge.copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Consultation Fee',
                                style: EcliniqTextStyles.headlineXMedium
                                    .copyWith(color: Color(0xff626060)),
                              ),
                              Text(
                                'Pay at Clinic',
                                style: EcliniqTextStyles.headlineXMedium
                                    .copyWith(color: Color(0xff424242)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Service Fee & Tax',
                                    style: EcliniqTextStyles.headlineXMedium
                                        .copyWith(color: Color(0xff626060)),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Color(0xff424242),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹49',
                                    style: EcliniqTextStyles.headlineXLMedium
                                        .copyWith(color: Color(0xff8E8E8E)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Free',
                                    style: EcliniqTextStyles.headlineMedium
                                        .copyWith(color: Color(0xff54B955)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We care for you and provide a free booking',
                            style: EcliniqTextStyles.buttonSmall.copyWith(
                              color: Color(0xff54B955),
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Payable',
                                style: EcliniqTextStyles.headlineLarge.copyWith(
                                  color: Color(0xff424242),
                                ),
                              ),
                              Text(
                                'Pay at Clinic',
                                style: EcliniqTextStyles.headlineLarge.copyWith(
                                  color: Color(0xff424242),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(child: const EasyWayToBookWidget()),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(child: _buildConfirmVisitButton()),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirmVisit() async {
    if (_isBooking) {
      return;
    }

    // Reason is only required for new appointments, not for reschedule
    if (!widget.isReschedule && (selectedReason == null || selectedReason!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for visit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _loadPatientId();
    final finalPatientId = _patientId ?? '2ccb2364-9e21-40ad-a1f2-274b73553e44';

    setState(() {
      _isBooking = true;
    });

    try {
      if (widget.isReschedule && widget.appointmentId != null) {
        // Reschedule appointment
        final rescheduleRequest = RescheduleAppointmentRequest(
          appointmentId: widget.appointmentId!,
          newSlotId: widget.slotId,
        );

        final response = await _appointmentService.rescheduleAppointment(
          request: rescheduleRequest,
          authToken: _authToken,
        );

        if (mounted) {
          if (response.success && response.data != null) {
            final tokenNumber = response.data!.tokenNo.toString();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentRequestScreen(
                  doctorName: widget.doctorName,
                  doctorSpecialization: widget.doctorSpecialization,
                  selectedSlot: widget.selectedSlot,
                  selectedDate: widget.selectedDate,
                  hospitalAddress: _hospitalAddress,
                  tokenNumber: tokenNumber,
                ),
              ),
            );
          } else {
            setState(() {
              _isBooking = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Book new appointment
        final isDependent = _selectedDependent != null;
        final request = BookAppointmentRequest(
          patientId: finalPatientId,
          doctorId: widget.doctorId,
          doctorSlotScheduleId: widget.slotId,
          reason: selectedReason,
          referBy: _referByController.text.trim().isEmpty
              ? null
              : _referByController.text.trim(),
          bookedFor: isDependent ? 'DEPENDENT' : 'SELF',
          dependentId: isDependent ? _selectedDependent!.id : null,
        );

        final response = await _appointmentService.bookAppointment(
          request: request,
          authToken: _authToken,
        );

        if (mounted) {
          if (response.success && response.data != null) {
            final appointmentId = response.data!.id;
            
            // Verify appointment payment
            final verifyRequest = VerifyAppointmentRequest(
              appointmentId: appointmentId,
              paymentStatus: 'COMPLETED',
            );

            await _appointmentService.verifyAppointment(
              request: verifyRequest,
              authToken: _authToken,
            );

            final tokenNumber = response.data!.tokenNo.toString();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentRequestScreen(
                  doctorName: widget.doctorName,
                  doctorSpecialization: widget.doctorSpecialization,
                  selectedSlot: widget.selectedSlot,
                  selectedDate: widget.selectedDate,
                  hospitalAddress: _hospitalAddress,
                  tokenNumber: tokenNumber,
                ),
              ),
            );
          } else {
            setState(() {
              _isBooking = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isReschedule
                  ? 'Failed to reschedule appointment: ${e.toString()}'
                  : 'Failed to book appointment: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConfirmVisitButton() {
    final isButtonEnabled = !_isBooking;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isButtonEnabled ? _onConfirmVisit : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: isButtonEnabled
                ? EcliniqButtonType.brandPrimary.backgroundColor(context)
                : EcliniqButtonType.brandPrimary.disabledBackgroundColor(
                    context,
                  ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isBooking)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                Text(
                  widget.isReschedule ? 'Confirm Reschedule' : 'Confirm Visit',
                  style: EcliniqTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
