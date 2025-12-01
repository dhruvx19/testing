import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/models/payment.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/request_sent.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/payment_processing_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/appointment_detail_item.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/clinic_location_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/doctor_info_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/widgets/top_bar_widgets/easy_way_book.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart'
    hide DoctorInfoCard, ClinicLocationCard;
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _referByController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool receiveUpdates = true;
  bool _isBooking = false;
  String? _patientId;
  String? _authToken;
  String? _hospitalAddress;
  DependentData? _selectedDependent;
  
  // Payment-related state
  bool _useWallet = false;
  double _walletBalance = 0.0;
  double _consultationFee = 500.0; // Default, should be fetched from doctor data
  
  // Reason bottom sheet removed; using free-text field instead.

  @override
  void initState() {
    super.initState();
    _loadPatientId();
    _fetchHospitalAddress();
    _reasonController.addListener(() {
      setState(() {});
    });

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
    _reasonController.dispose();
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
    
    // Fetch wallet balance
    await _fetchWalletBalance();
  }
  
  Future<void> _fetchWalletBalance() async {
    // TODO: Implement API call to fetch wallet balance
    // For now, using mock data
    setState(() {
      _walletBalance = 200.0; // Mock balance
    });
  }

  // Bottom sheet for selecting reason has been removed.

  String _formatDependentSubtitle(DependentData d) {
    String capitalize(String s) => s.isEmpty
        ? s
        : s[0].toUpperCase() +
              (s.length > 1 ? s.substring(1).toLowerCase() : '');

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
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return TextFormField(
                          key: const ValueKey('reason_field'),
                          controller: _reasonController,
                          maxLength: 150,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Enter Reason for Visit',
                            hintStyle: const TextStyle(
                              color: Color(0xffD6D6D6),
                            ),
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
                            counterText: '',
                            suffixText: '${_reasonController.text.length}/150',
                            suffixStyle: const TextStyle(
                              color: Color(0xff8E8E8E),
                              fontSize: 12,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        );
                      },
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
                  // Wallet checkbox section
                  if (!widget.isReschedule) ...[
                    RepaintBoundary(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _useWallet,
                                  onChanged: (value) {
                                    setState(() {
                                      _useWallet = value ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF1976D2),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Use Wallet Balance',
                                        style: EcliniqTextStyles.headlineMedium.copyWith(
                                          color: const Color(0xff424242),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Available balance: ₹${_walletBalance.toStringAsFixed(0)}',
                                        style: EcliniqTextStyles.buttonSmall.copyWith(
                                          color: _walletBalance > 0
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                                '₹${_consultationFee.toStringAsFixed(0)}',
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
                          // Show wallet payment breakdown if using wallet
                          if (_useWallet && _walletBalance > 0) ...[
                            const Divider(height: 24),
                            Text(
                              'Payment Breakdown',
                              style: EcliniqTextStyles.headlineXMedium.copyWith(
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'From Wallet',
                                  style: EcliniqTextStyles.headlineXMedium
                                      .copyWith(color: Color(0xff626060)),
                                ),
                                Text(
                                  '₹${(_walletBalance >= _consultationFee ? _consultationFee : _walletBalance).toStringAsFixed(0)}',
                                  style: EcliniqTextStyles.headlineXMedium
                                      .copyWith(color: Color(0xFF4CAF50)),
                                ),
                              ],
                            ),
                            if (_walletBalance < _consultationFee) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Via PhonePe',
                                    style: EcliniqTextStyles.headlineXMedium
                                        .copyWith(color: Color(0xff626060)),
                                  ),
                                  Text(
                                    '₹${(_consultationFee - _walletBalance).toStringAsFixed(0)}',
                                    style: EcliniqTextStyles.headlineXMedium
                                        .copyWith(color: Color(0xFF1976D2)),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
                                _useWallet && _walletBalance >= _consultationFee
                                    ? 'Paid from Wallet'
                                    : _useWallet && _walletBalance > 0
                                        ? '₹${(_consultationFee - _walletBalance).toStringAsFixed(0)}'
                                        : '₹${_consultationFee.toStringAsFixed(0)}',
                                style: EcliniqTextStyles.headlineLarge.copyWith(
                                  color: _useWallet && _walletBalance >= _consultationFee
                                      ? Color(0xFF4CAF50)
                                      : Color(0xff424242),
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
    if (!widget.isReschedule && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomErrorSnackBar(
          context: context,
          title: 'Reason required',
          subtitle: 'Please enter a reason for visit',
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    await _loadPatientId();
    final finalPatientId = '48bc218e-152d-404b-ac3f-cda7f6340bbd';

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
                  patientName: _selectedDependent?.fullName ?? 'Ketan Patni',
                  patientSubtitle: _selectedDependent != null
                      ? _formatDependentSubtitle(_selectedDependent!)
                      : 'Male, 02/02/1996 (29Y)',
                  patientBadge: _selectedDependent?.relation ?? 'You',
                ),
              ),
            );
          } else {
            setState(() {
              _isBooking = false;
            });

            // Extract error message from response
            String errorMessage = 'Failed to reschedule appointment';
            if (response.errors != null && response.errors.toString().isNotEmpty) {
              errorMessage = response.errors.toString();
            } else if (response.message.isNotEmpty) {
              errorMessage = response.message;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              CustomErrorSnackBar(
                context: context,
                title: 'Reschedule Failed',
                subtitle: errorMessage,
                duration: const Duration(seconds: 4),
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
          reason: _reasonController.text.trim(),
          referBy: _referByController.text.trim().isEmpty
              ? null
              : _referByController.text.trim(),
          bookedFor: isDependent ? 'DEPENDENT' : 'SELF',
          dependentId: isDependent ? _selectedDependent!.id : null,
          useWallet: _useWallet,
        );

        final response = await _appointmentService.bookAppointment(
          request: request,
          authToken: _authToken,
        );

        if (mounted) {
          if (response.success && response.data != null) {
            // Try to parse payment data from response
            final responseDataJson = response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : null;

            // Debug logging for payment data
            print('========== BOOKING RESPONSE DEBUG ==========');
            print('Response success: ${response.success}');
            print('Response data type: ${response.data.runtimeType}');
            if (responseDataJson != null) {
              print('Contains requiresGateway: ${responseDataJson.containsKey("requiresGateway")}');
              print('Contains token: ${responseDataJson.containsKey("token")}');
              print('requiresGateway value: ${responseDataJson["requiresGateway"]}');
              final tokenStr = responseDataJson["token"]?.toString() ?? '';
              print('token value (first 50 chars): ${tokenStr.length > 50 ? tokenStr.substring(0, 50) : tokenStr}');
              print('token length: ${tokenStr.length}');
              print('merchantTransactionId: ${responseDataJson["merchantTransactionId"]}');
              print('totalAmount: ${responseDataJson["totalAmount"]}');
              print('walletAmount: ${responseDataJson["walletAmount"]}');
              print('gatewayAmount: ${responseDataJson["gatewayAmount"]}');
              print('provider: ${responseDataJson["provider"]}');
            } else {
              print('responseDataJson is null - data type is: ${response.data.runtimeType}');
              print('This means the backend returned AppointmentData instead of payment data');
            }
            print('============================================');

            // Check if payment data is present
            if (responseDataJson != null &&
                responseDataJson.containsKey('requiresGateway')) {
              final paymentData =
                  BookingPaymentData.fromJson(responseDataJson);

              if (paymentData.requiresGateway) {
                print('========== NAVIGATING TO PAYMENT ==========');
                print('Appointment ID: ${paymentData.appointmentId}');
                print('Merchant Txn ID: ${paymentData.merchantTransactionId}');
                print('Token present: ${paymentData.token != null}');
                print('Token length: ${paymentData.token?.length ?? 0}');
                print('Gateway amount: ${paymentData.gatewayAmount}');
                print('==========================================');
                
                // Navigate to payment processing screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProcessingScreen(
                      appointmentId: paymentData.appointmentId,
                      merchantTransactionId:
                          paymentData.merchantTransactionId,
                      token: paymentData.token ?? '',
                      totalAmount: paymentData.totalAmount,
                      walletAmount: paymentData.walletAmount,
                      gatewayAmount: paymentData.gatewayAmount,
                      provider: paymentData.provider,
                      doctorName: widget.doctorName,
                      doctorSpecialization: widget.doctorSpecialization,
                      selectedSlot: widget.selectedSlot,
                      selectedDate: widget.selectedDate,
                      hospitalAddress: _hospitalAddress,
                      patientName: _selectedDependent?.fullName ?? 'Ketan Patni',
                      patientSubtitle: _selectedDependent != null
                          ? _formatDependentSubtitle(_selectedDependent!)
                          : 'Male, 02/02/1996 (29Y)',
                      patientBadge: _selectedDependent?.relation ?? 'You',
                    ),
                  ),
                );
              } else {
                // Wallet-only payment - appointment auto-confirmed
                // Parse appointment data
                final appointmentData = response.data is AppointmentData
                    ? response.data as AppointmentData
                    : null;
                final tokenNumber =
                    appointmentData?.tokenNo.toString() ?? '--';

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
                      patientName: _selectedDependent?.fullName ?? 'Ketan Patni',
                      patientSubtitle: _selectedDependent != null
                          ? _formatDependentSubtitle(_selectedDependent!)
                          : 'Male, 02/02/1996 (29Y)',
                      patientBadge: _selectedDependent?.relation ?? 'You',
                      merchantTransactionId: paymentData.merchantTransactionId,
                      paymentMethod: paymentData.provider,
                      totalAmount: paymentData.totalAmount,
                      walletAmount: paymentData.walletAmount,
                      gatewayAmount: paymentData.gatewayAmount,
                    ),
                  ),
                );
              }
            } else {
              // Legacy response format - no payment data
              // Verify appointment with default payment status
              final appointmentData = response.data is AppointmentData
                  ? response.data as AppointmentData
                  : null;
              final appointmentId =
                  appointmentData?.id ?? responseDataJson?['id'] ?? '';

              final verifyRequest = VerifyAppointmentRequest(
                appointmentId: appointmentId,
                merchantTransactionId: 'LEGACY_${DateTime.now().millisecondsSinceEpoch}',
              );

              await _appointmentService.verifyAppointment(
                request: verifyRequest,
                authToken: _authToken,
              );

              final tokenNumber = appointmentData?.tokenNo.toString() ?? '--';

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
                    patientName: _selectedDependent?.fullName ?? 'Ketan Patni',
                    patientSubtitle: _selectedDependent != null
                        ? _formatDependentSubtitle(_selectedDependent!)
                        : 'Male, 02/02/1996 (29Y)',
                    patientBadge: _selectedDependent?.relation ?? 'You',
                  ),
                ),
              );
            }
          } else {
            setState(() {
              _isBooking = false;
            });

            // Extract error message from response
            String errorMessage = 'Failed to book appointment';
            if (response.errors != null && response.errors.toString().isNotEmpty) {
              errorMessage = response.errors.toString();
            } else if (response.message.isNotEmpty) {
              errorMessage = response.message;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              CustomErrorSnackBar(
                context: context,
                title: 'Booking Failed',
                subtitle: errorMessage,
                duration: const Duration(seconds: 4),
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
          CustomErrorSnackBar(
            context: context,
            title: widget.isReschedule ? 'Reschedule Failed' : 'Booking Failed',
            subtitle: e.toString().replaceFirst('Exception: ', ''),
            duration: const Duration(seconds: 4),
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
                  _getButtonText(),
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
  
  String _getButtonText() {
    if (widget.isReschedule) {
      return 'Confirm Reschedule';
    }
    
    if (_useWallet && _walletBalance >= _consultationFee) {
      // Full wallet payment
      return 'Pay ₹${_consultationFee.toStringAsFixed(0)} with Wallet';
    } else if (_useWallet && _walletBalance > 0) {
      // Hybrid payment
      final gatewayAmount = _consultationFee - _walletBalance;
      return 'Pay ₹${gatewayAmount.toStringAsFixed(0)} (₹${_walletBalance.toStringAsFixed(0)} from Wallet)';
    } else {
      // Full gateway payment or no payment
      return 'Proceed to Payment';
    }
  }
}
