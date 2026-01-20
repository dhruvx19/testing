import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/models/payment.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/payment_service.dart';
import 'package:ecliniq/ecliniq_api/wallet_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/easy_way_book.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/payment_method_selection_screen.dart'
    show PaymentMethodBottomSheet;
import 'package:ecliniq/ecliniq_modules/screens/booking/request_sent.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/doctor_info_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart'
    hide DoctorInfoCard;
import 'package:ecliniq/ecliniq_services.dart/phonepe_service.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/select_member_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final Doctor? doctor;
  final String? locationName;
  final String? locationAddress;
  final String? locationDistance;
  final PatientDetailsData? currentUserDetails;

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
    this.doctor,
    this.locationName,
    this.locationAddress,
    this.locationDistance,
    this.currentUserDetails,
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
  final DoctorService _doctorService = DoctorService();
  final PatientService _patientService = PatientService();
  final PaymentService _paymentService = PaymentService();
  final PhonePeService _phonePeService = PhonePeService();
  final WalletService _walletService = WalletService();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _referByController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool receiveUpdates = true;
  bool _isBooking = false;
  String? _patientId;
  String? _authToken;
  String? _hospitalAddress;
  DependentData? _selectedDependent;

  Doctor? _doctor;
  String? _currentLocationName;
  String? _currentLocationAddress;
  String? _currentDistance;
  bool _isLoadingDoctorDetails = false;

  PatientDetailsData? _currentUserDetails;
  bool _isLoadingUserDetails = false;

  // Payment-related state
  bool _useWallet = false;
  double _walletBalance = 0.0;
  double _consultationFee = 500.0;
  double _serviceFee = 0.0;
  bool _isProcessingPayment = false;
  String? _selectedPaymentMethod;
  String?
  _selectedPaymentMethodPackage; // Store package name for payment processing

  @override
  void initState() {
    super.initState();
    _loadPatientId();
    _fetchHospitalAddress();

    // Use passed user details if available, otherwise fetch
    if (widget.currentUserDetails != null) {
      _currentUserDetails = widget.currentUserDetails;
      _patientId = widget.currentUserDetails!.userId;
      _isLoadingUserDetails = false;
    } else {
      _fetchCurrentUserDetails();
    }

    if (widget.doctor != null) {
      _doctor = widget.doctor;
      // Set serviceFee from widget.doctor if available
      debugPrint('========== SERVICE FEE FROM WIDGET ==========');
      debugPrint('widget.doctor?.serviceFee: ${widget.doctor?.serviceFee}');
      debugPrint(
        'widget.doctor?.serviceFee type: ${widget.doctor?.serviceFee.runtimeType}',
      );

      if (_doctor?.serviceFee != null && _doctor!.serviceFee! > 0) {
        _serviceFee = _doctor!.serviceFee!;
        debugPrint('ServiceFee from widget set to: $_serviceFee');
      } else {
        _serviceFee = 0.0;
        debugPrint('ServiceFee from widget set to 0.0 (was null or <= 0)');
      }
      debugPrint('=============================================');
      _currentLocationName = widget.locationName;
      _currentLocationAddress = widget.locationAddress;
      _currentDistance = widget.locationDistance;
      _updateCurrentLocationDetails();
    } else {
      _fetchDoctorDetails();
    }

    _reasonController.addListener(() {
      setState(() {});
    });

    if (widget.isReschedule && widget.previousAppointment != null) {
      // Pre-fill reason if available
    }
  }

  Future<void> _fetchHospitalAddress() async {
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
      // Silently fail
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
    final authToken = prefs.getString('auth_token');

    setState(() {
      _authToken = authToken;
      _patientId =
          prefs.getString('patient_id') ??
          prefs.getString('patientId') ??
          prefs.getString('user_id');
    });

    await _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    if (_authToken == null || _authToken!.isEmpty) {
      setState(() {
        _walletBalance = 0.0;
      });
      return;
    }

    try {
      final response = await _walletService.getBalance(authToken: _authToken!);
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _walletBalance = response.data!.balance;
          } else {
            _walletBalance = 0.0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletBalance = 0.0;
        });
      }
      debugPrint('Failed to fetch wallet balance: $e');
    }
  }

  Future<void> _fetchCurrentUserDetails() async {
    setState(() {
      _isLoadingUserDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        setState(() {
          _isLoadingUserDetails = false;
        });
        return;
      }

      // Fetch patient details
      final response = await _patientService.getPatientDetails(
        authToken: authToken,
      );

      // Fetch dependents to get self data
      final dependentsResponse = await _patientService.getDependents(
        authToken: authToken,
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _currentUserDetails = response.data;
            _patientId = response.data!.userId;
          }

          // Auto-select self if available
          if (dependentsResponse.success && dependentsResponse.self != null) {
            _selectedDependent = dependentsResponse.self;
          }

          _isLoadingUserDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserDetails = false;
        });
      }
      debugPrint('Failed to fetch current user details: $e');
    }
  }

  String _formatUserSubtitle() {
    if (_currentUserDetails == null) {
      return '';
    }

    final user = _currentUserDetails!;
    final parts = <String>[];

    if (user.dob != null) {
      final dob = user.dob!;
      final day = dob.day.toString().padLeft(2, '0');
      final month = dob.month.toString().padLeft(2, '0');
      parts.add('$day/$month/${dob.year}');
    }

    final age = user.age;
    if (age != null) {
      parts.add('($age)');
    }

    return parts.join(', ');
  }

  String _getCurrentUserName() {
    if (_selectedDependent != null) {
      return _selectedDependent!.fullName;
    }
    return _currentUserDetails?.fullName ?? 'User';
  }

  String _getCurrentUserSubtitle() {
    if (_selectedDependent != null) {
      return _formatDependentSubtitle(_selectedDependent!);
    }
    return _formatUserSubtitle();
  }

  /// Extract error message from response errors
  /// Handles errors as List of objects with 'message' field or as String
  String _extractErrorMessage(dynamic errors, String defaultMessage) {
    if (errors == null) {
      return defaultMessage;
    }

    // If errors is a List
    if (errors is List) {
      if (errors.isEmpty) {
        return defaultMessage;
      }
      
      // Extract messages from error objects
      final messages = errors
          .where((error) => error is Map && error['message'] != null)
          .map((error) => error['message'].toString())
          .where((msg) => msg.isNotEmpty)
          .toList();
      
      if (messages.isNotEmpty) {
        return messages.join(', ');
      }
      
      // If no message field, try to convert first item to string
      return errors.first.toString();
    }

    // If errors is a Map with 'message' field
    if (errors is Map && errors['message'] != null) {
      return errors['message'].toString();
    }

    // If errors is a String
    if (errors is String) {
      return errors;
    }

    // Fallback to string representation
    return errors.toString();
  }

  Future<void> _openSelectMemberBottomSheet() async {
    final selectedDependent = await EcliniqBottomSheet.show<DependentData>(
      context: context,
      child: SelectMemberBottomSheet(
        currentlySelectedDependent: _selectedDependent,
      ),
    );

    if (selectedDependent != null && mounted) {
      // Use post-frame callback to avoid state updates during layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // If self is selected, clear _selectedDependent to use _currentUserDetails
            // Otherwise, set the selected dependent which will update gender, age, and DOB
            if (selectedDependent.isSelf) {
              _selectedDependent = null;
            } else {
              _selectedDependent = selectedDependent;
            }
            // This will trigger a rebuild and update appointment details
            // including name, gender, age, and DOB through _buildPatientInfo()
          });
        }
      });
    }
  }

  Future<void> _fetchDoctorDetails() async {
    setState(() {
      _isLoadingDoctorDetails = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      final response = await _doctorService.getDoctorDetailsForBooking(
        doctorId: widget.doctorId,
        authToken: authToken,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _doctor = response.data;

            // Set serviceFee from API response
            debugPrint('========== SERVICE FEE PARSING ==========');
            debugPrint('_doctor?.serviceFee: ${_doctor?.serviceFee}');
            debugPrint(
              '_doctor?.serviceFee type: ${_doctor?.serviceFee.runtimeType}',
            );

            if (_doctor?.serviceFee != null && _doctor!.serviceFee! > 0) {
              _serviceFee = _doctor!.serviceFee!;
              debugPrint('ServiceFee set to: $_serviceFee');
            } else {
              _serviceFee = 0.0;
              debugPrint('ServiceFee set to 0.0 (was null or <= 0)');
            }
            debugPrint('Final _serviceFee: $_serviceFee');
            debugPrint('==========================================');

            // Update consultation fee from doctor data if available
            if (widget.hospitalId != null && _doctor != null) {
              final hospital = _doctor!.hospitals.firstWhere(
                (h) => h.id == widget.hospitalId,
                orElse: () => _doctor!.hospitals.isNotEmpty
                    ? _doctor!.hospitals.first
                    : DoctorHospital(id: '', name: ''),
              );
              if (hospital.consultationFee != null) {
                _consultationFee = hospital.consultationFee!;
              }
            } else if (widget.clinicId != null && _doctor != null) {
              final clinic = _doctor!.clinics.firstWhere(
                (c) => c.id == widget.clinicId,
                orElse: () => _doctor!.clinics.isNotEmpty
                    ? _doctor!.clinics.first
                    : DoctorClinic(id: '', name: ''),
              );
              if (clinic.consultationFee != null) {
                _consultationFee = clinic.consultationFee!;
              }
            }
            _updateCurrentLocationDetails();
            _isLoadingDoctorDetails = false;
          });
        } else {
          setState(() {
            _isLoadingDoctorDetails = false;
          });
          debugPrint('Failed to fetch doctor details: ${response.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDoctorDetails = false;
        });
      }
      debugPrint('Failed to fetch doctor details: $e');
    }
  }

  void _updateCurrentLocationDetails() {
    if (_doctor == null) return;

    if (widget.hospitalId != null) {
      final hospital = _doctor!.hospitals.firstWhere(
        (h) => h.id == widget.hospitalId,
        orElse: () => _doctor!.hospitals.isNotEmpty
            ? _doctor!.hospitals.first
            : DoctorHospital(id: '', name: ''),
      );
      if (hospital.id.isNotEmpty) {
        _currentLocationName = hospital.name;
        _currentLocationAddress =
            '${hospital.city ?? ""}, ${hospital.state ?? ""}';
        _currentDistance = hospital.distance?.toStringAsFixed(1);
      }
    } else if (widget.clinicId != null) {
      final clinic = _doctor!.clinics.firstWhere(
        (c) => c.id == widget.clinicId,
        orElse: () => _doctor!.clinics.isNotEmpty
            ? _doctor!.clinics.first
            : DoctorClinic(id: '', name: ''),
      );
      if (clinic.id.isNotEmpty) {
        _currentLocationName = clinic.name;
        _currentLocationAddress = '${clinic.city ?? ""}, ${clinic.state ?? ""}';
        _currentDistance = clinic.distance?.toStringAsFixed(1);
      }
    }
  }

  Widget _buildDoctorInfoShimmer() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  ShimmerLoading(
                    width: 70,
                    height: 70,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: 200,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerLoading(
                          width: 150,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerLoading(
                          width: 180,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ShimmerLoading(
                    width: 100,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 8),
                  ShimmerLoading(
                    width: 60,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ShimmerLoading(
                    width: 150,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ShimmerLoading(
                    width: 200,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xffF8FAFF),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              ShimmerLoading(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 8),
              ShimmerLoading(
                width: 30,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 8),
              ShimmerLoading(
                width: 200,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const Divider(height: 2, thickness: 0.3, color: Colors.grey),
        const SizedBox(height: 14),
      ],
    );
  }

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

  int _calculateAgeFromDob(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  PatientInfo _buildPatientInfo() {
    if (_selectedDependent != null) {
      String capitalize(String s) => s.isEmpty
          ? s
          : s[0].toUpperCase() +
                (s.length > 1 ? s.substring(1).toLowerCase() : '');

      String dobStr = '';
      if (_selectedDependent!.dob != null) {
        final dd = _selectedDependent!.dob!;
        final day = dd.day.toString().padLeft(2, '0');
        final month = dd.month.toString().padLeft(2, '0');
        dobStr = '$day/$month/${dd.year}';
      }

      final age = _calculateAgeFromDob(_selectedDependent!.dob);
      
      // Capitalize gender properly
      final gender = capitalize(_selectedDependent!.gender);

      return PatientInfo(
        name: _selectedDependent!.fullName,
        gender: gender,
        dateOfBirth: dobStr,
        age: age,
        isSelf: _selectedDependent!.isSelf,
      );
    } else {
      String dobStr = '';
      if (_currentUserDetails?.dob != null) {
        final dob = _currentUserDetails!.dob!;
        final day = dob.day.toString().padLeft(2, '0');
        final month = dob.month.toString().padLeft(2, '0');
        dobStr = '$day/$month/${dob.year}';
      }

      final age = _calculateAgeFromDob(_currentUserDetails?.dob);

      return PatientInfo(
        name: _currentUserDetails?.fullName ?? 'User',
        gender: 'Male', // PatientDetailsData doesn't have gender field
        dateOfBirth: dobStr,
        age: age,
        isSelf: true,
      );
    }
  }

  AppointmentTimeInfo _buildAppointmentTimeInfo() {
    return AppointmentTimeInfo(
      date: widget.selectedDate,
      time: widget.selectedSlot,
      displayDate: widget.selectedDate,
      consultationType: 'In-Clinic Consultation',
    );
  }

  ClinicInfo _buildClinicInfo() {
    final locationName =
        _currentLocationName ?? widget.locationName ?? 'Clinic';
    final locationAddress =
        _currentLocationAddress ?? widget.locationAddress ?? '';
    final distance = _currentDistance != null
        ? double.tryParse(_currentDistance!) ?? 0.0
        : 0.0;

    // Extract city and pincode from address if available
    String city = '';
    String pincode = '';
    if (locationAddress.isNotEmpty) {
      final addressParts = locationAddress.split(',');
      if (addressParts.length > 1) {
        city = addressParts[addressParts.length - 2].trim();
      }
      if (addressParts.isNotEmpty) {
        final lastPart = addressParts.last.trim();
        if (RegExp(r'^\d{6}$').hasMatch(lastPart)) {
          pincode = lastPart;
        }
      }
    }

    return ClinicInfo(
      name: locationName,
      address: locationAddress,
      city: city,
      pincode: pincode,
      latitude: 0.0,
      longitude: 0.0,
      distanceKm: distance,
    );
  }

  // Replace your build method's body with this:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leadingWidth: 58,
        titleSpacing: 0,
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
            'Review Details',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              EcliniqRouter.push(ProfileHelpPage());
            },
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.questionCircleWhite.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 4),
                 Text(
                  'Help',
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Fixed DoctorInfoCard at the top (not scrollable)
          RepaintBoundary(
            child: _isLoadingDoctorDetails
                ? _buildDoctorInfoShimmer()
                : DoctorInfoCard(
                    doctor: _doctor,
                    doctorName: widget.doctorName,
                    specialization: widget.doctorSpecialization,
                    locationName: _currentLocationName,
                    locationAddress: _currentLocationAddress,
                    locationDistance: _currentDistance,
                  ),
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(
                    child: Padding(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: AppointmentDetailsSection(
                        patient: _buildPatientInfo(),
                        timeInfo: _buildAppointmentTimeInfo(),
                        onEditPatient: _openSelectMemberBottomSheet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    child: Padding(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: ClinicLocationCard(clinic: _buildClinicInfo()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Reason for Visit',
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 16,
                      vertical: 0,
                    ),
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
                            hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                              color: Color(0xffD6D6D6),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xff626060),
                                width: 0.5,
                              ),
                            ),
                            focusColor: Color(0xff626060),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xff626060),
                                width: 0.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xff626060),
                                width: 0.5,
                              ),
                            ),
                            contentPadding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                              context,
                              horizontal: 12,
                              vertical: 14,
                            ),
                            counterText: '',
                            suffixText: '${_reasonController.text.length}/150',
                            suffixStyle: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              color: Color(0xff8E8E8E),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),
                  Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: Text(
                      'Refer By',
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: TextFormField(
                      key: const ValueKey('refer_by_field'),
                      controller: _referByController,
                      decoration: InputDecoration(
                        hintText: 'Enter Who Refer you',
                        hintStyle:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                          color: Color(0xffD6D6D6),
                        
                          fontWeight: FontWeight.w400,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff626060),
                            width: 0.5,
                          ),
                        ),
                        focusColor: Color(0xff626060),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff626060),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xff626060),
                            width: 0.5,
                          ),
                        ),
                        contentPadding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                          context,
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet checkbox section (only for new appointments)
                  RepaintBoundary(
                    child: Container(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Consultation Fee',
                                style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                                    .copyWith(color: Color(0xff626060)),
                              ),
                              Text(
                                'Pay at Clinic',
                                style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                                    .copyWith(color: Color(0xff424242)),
                              ),
                            ],
                          ),
                          if (_serviceFee > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Service Fee & Tax',
                                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
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
                                Text(
                                  '₹${_serviceFee.toStringAsFixed(0)}',
                                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                                      .copyWith(color: Color(0xff424242)),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Service Fee & Tax',
                                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
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
                                      style: EcliniqTextStyles.responsiveHeadlineXLMedium(context)
                                          .copyWith(color: Color(0xff8E8E8E)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Free',
                                      style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                          .copyWith(color: Color(0xff54B955)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We care for you and provide a free booking',
                              style: EcliniqTextStyles.responsiveButtonSmall(context).copyWith(
                                color: Color(0xff54B955),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const SizedBox(height: 4),
                          Container(
                            height: 0.5,
                            color: const Color(0xffB8B8B8),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _serviceFee > 0
                                    ? 'Total Payable Now'
                                    : 'Total Payable',
                                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                                  color: Color(0xff424242),
                                ),
                              ),
                              Text(
                                _serviceFee > 0
                                    ? '₹${_serviceFee.toStringAsFixed(0)}'
                                    : '₹00.00',
                                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                                  color: Color(0xff424242),
                                  fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Fixed button/bottom bar at bottom
          if (_serviceFee > 0)
            _buildPaymentBottomBar()
          else
            Container(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
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
              child: SafeArea(child: _buildConfirmVisitButtonForZeroFee()),
            ),
        ],
      ),
    );
  }

  Future<void> _onConfirmVisit() async {
    if (_isBooking) return;

    if (!widget.isReschedule && _reasonController.text.trim().isEmpty) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Reason required',
          subtitle: 'Please enter a reason for visit',
          duration: const Duration(seconds: 4),
      
      );
      return;
    }

    // Check if payment method is selected when service fee > 0 and wallet is not used
    if (_serviceFee > 0 && !_useWallet && _selectedPaymentMethodPackage == null) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Payment Method Required',
          subtitle: 'Please select a payment method',
          duration: const Duration(seconds: 4),
     
      );
      return;
    }

    await _loadPatientId();

    final finalPatientId = _currentUserDetails?.userId ?? _patientId;

    if (finalPatientId == null || finalPatientId.isEmpty) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Patient ID Required',
          subtitle: 'Unable to get patient information. Please try again.',
          duration: const Duration(seconds: 4),
       
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      if (widget.isReschedule && widget.appointmentId != null) {
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
                  patientName: _getCurrentUserName(),
                  patientSubtitle: _getCurrentUserSubtitle(),
                  patientBadge: _selectedDependent?.formattedRelation ?? 'You',
                ),
              ),
            );
          } else {
            setState(() {
              _isBooking = false;
            });

            String errorMessage = 'Failed to reschedule appointment';
            if (response.errors != null) {
              errorMessage = _extractErrorMessage(response.errors, errorMessage);
            } else if (response.message.isNotEmpty) {
              errorMessage = response.message;
            }

              CustomErrorSnackBar.show(
                context: context,
                title: 'Reschedule Failed',
                subtitle: errorMessage,
                duration: const Duration(seconds: 4),
           
            );
          }
        }
      } else {
        // Book new appointment
        // Check if selected member is a dependent (not self)
        final isDependent =
            _selectedDependent != null && !_selectedDependent!.isSelf;
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
            final responseDataJson = response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : null;

            // Debug logging
            if (responseDataJson != null) {
            }

            // Check if payment data is present (new backend format)
            if (responseDataJson != null &&
                responseDataJson.containsKey('paymentRequired') &&
                responseDataJson['paymentRequired'] == true) {
              final paymentData = BookingPaymentData.fromJson(responseDataJson);

              // Check if total amount is 0, gateway amount is 0, service fee was 0, or wallet is used
              // If any of these conditions are true, skip payment and go directly to request sent screen
              if (paymentData.totalAmount == 0 || 
                  paymentData.gatewayAmount == 0 ||
                  _serviceFee == 0 ||
                  _useWallet) {
                // No payment required or wallet payment, go directly to request sent screen
                final appointmentData = response.data is AppointmentData
                    ? response.data as AppointmentData
                    : null;
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
                      patientName: _getCurrentUserName(),
                      patientSubtitle: _getCurrentUserSubtitle(),
                      patientBadge:
                          _selectedDependent?.formattedRelation ?? 'You',
                      merchantTransactionId: paymentData.merchantTransactionId,
                      paymentMethod: paymentData.provider,
                      totalAmount: paymentData.totalAmount,
                      walletAmount: paymentData.walletAmount,
                      gatewayAmount: paymentData.gatewayAmount,
                    ),
                  ),
                );
                return;
              }

              if (paymentData.requiresGateway) {

                // Validate payment data
                if (paymentData.requestPayload == null ||
                    paymentData.requestPayload!.isEmpty) {
                  if (paymentData.token == null || paymentData.token!.isEmpty) {
                    setState(() {
                      _isBooking = false;
                    });

                    CustomErrorSnackBar.show(
                        context: context,
                        title: 'Payment Error',
                        subtitle:
                            'Payment data is missing. Please try booking again.',
                        duration: const Duration(seconds: 4),
                    
                    );
                    return;
                  }

                  if (paymentData.orderId == null ||
                      paymentData.orderId!.isEmpty) {
                    setState(() {
                      _isBooking = false;
                    });

                      CustomErrorSnackBar.show(
                        context: context,
                        title: 'Payment Error',
                        subtitle:
                            'Order ID is missing. Please try booking again.',
                        duration: const Duration(seconds: 4),
                 
                    );
                    return;
                  }
                }

                // Use the pre-selected payment method or default to Google Pay if service fee was 0
                String? paymentPackage = _selectedPaymentMethodPackage;
                if (paymentPackage == null && _serviceFee == 0) {
                  // Default to Google Pay when service fee was 0 but payment is required
                  paymentPackage = 'com.google.android.apps.nbu.paisa.user';
                }

                if (paymentPackage != null) {
                  if (paymentPackage == 'WALLET') {
                    // Wallet-only payment, go to request sent
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
                          patientName: _getCurrentUserName(),
                          patientSubtitle: _getCurrentUserSubtitle(),
                          patientBadge:
                              _selectedDependent?.formattedRelation ?? 'You',
                          merchantTransactionId:
                              paymentData.merchantTransactionId,
                          paymentMethod: paymentData.provider,
                          totalAmount: paymentData.totalAmount,
                          walletAmount: paymentData.walletAmount,
                          gatewayAmount: paymentData.gatewayAmount,
                        ),
                      ),
                    );
                  } else {
                    // UPI payment, process payment with loader
                    await _processUPIPayment(
                      paymentData: paymentData,
                      selectedUPIPackage: paymentPackage,
                    );
                  }
                } else {
                  // No payment method selected and service fee > 0, show error
                  setState(() {
                    _isBooking = false;
                  });

           
                    CustomErrorSnackBar.show(
                      context: context,
                      title: 'Payment Method Required',
                      subtitle: 'Please select a payment method',
                      duration: const Duration(seconds: 4),
                
                  );
                }
              } else {
                // Wallet-only payment
                final appointmentData = response.data is AppointmentData
                    ? response.data as AppointmentData
                    : null;
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
                      patientName: _getCurrentUserName(),
                      patientSubtitle: _getCurrentUserSubtitle(),
                      patientBadge:
                          _selectedDependent?.formattedRelation ?? 'You',
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
              // Legacy response format
              final appointmentData = response.data is AppointmentData
                  ? response.data as AppointmentData
                  : null;
              final appointmentId =
                  appointmentData?.id ?? responseDataJson?['id'] ?? '';

              final verifyRequest = VerifyAppointmentRequest(
                appointmentId: appointmentId,
                merchantTransactionId:
                    'LEGACY_${DateTime.now().millisecondsSinceEpoch}',
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
                    patientName: _getCurrentUserName(),
                    patientSubtitle: _getCurrentUserSubtitle(),
                    patientBadge:
                        _selectedDependent?.formattedRelation ?? 'You',
                  ),
                ),
              );
            }
          } else {
            setState(() {
              _isBooking = false;
            });

            String errorMessage = 'Failed to book appointment';
            if (response.errors != null) {
              errorMessage = _extractErrorMessage(response.errors, errorMessage);
            } else if (response.message.isNotEmpty) {
              errorMessage = response.message;
            }

        
CustomErrorSnackBar.show(
                context: context,
                title: 'Booking Failed',
                subtitle: errorMessage,
                duration: const Duration(seconds: 4),
             
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });


          CustomErrorSnackBar.show(
            context: context,
            title: widget.isReschedule ? 'Reschedule Failed' : 'Booking Failed',
            subtitle: e.toString().replaceFirst('Exception: ', ''),
            duration: const Duration(seconds: 4),
        
        );
      }
    }
  }


  Widget _buildConfirmVisitButtonForZeroFee() {
    final isButtonEnabled = !_isBooking;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isButtonEnabled ? _onConfirmVisit : null,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
        ),
        child: Container(
          width: double.infinity,
          height: EcliniqTextStyles.getResponsiveButtonHeight(
            context,
            baseHeight: 52.0,
          ),
          decoration: BoxDecoration(
            boxShadow: _isBooking
                ? [] // No shadow when loading
                : [
                    BoxShadow(
                      color: Color(0x4D2372EC),
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
            color: isButtonEnabled
                ? const Color(0xFF2372EC)
                : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
            ),
          ),
          child: Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 12,
              top: 6,
              bottom: 6,
              right: 12,
            ),
            child: _isBooking
                ? const Center(
                    child: EcliniqLoader(size: 24, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₹00.00',
                              style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'Total',
                              style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                                fontWeight: FontWeight.w300,
                                color: isButtonEnabled
                                    ? Colors.white
                                    : const Color(0xff8E8E8E),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right side - Confirm Visit and arrow
                      Row(
                        children: [
                          Text(
                            'Confirm Visit',
                            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                              color: Colors.white,
                            ),
                          ),

                          Transform.rotate(
                            angle: 1.5708,
                            child: SvgPicture.asset(
                              EcliniqIcons.arrowUp.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                              colorFilter: ColorFilter.mode(
                                isButtonEnabled
                                    ? Colors.white
                                    : const Color(0xff8E8E8E),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }


 Widget _buildPaymentBottomBar() {
  return Container(
    padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
      context,
      left: 16,
      right: 16,
      top: 16,
      bottom: 28,
    ),
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wallet balance checkbox
        Row(
          children: [
            Image.asset(
              EcliniqIcons.upcharCoinSmall1.assetPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Upchar-Q Coin Balance : ₹${_walletBalance.toStringAsFixed(2)}',
                style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                  color: Color(0xff424242),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _useWallet = !_useWallet;
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _useWallet
                      ? const Color(0xFF2372EC)
                      : Colors.transparent,
                  border: Border.all(
                    color: _useWallet
                        ? const Color(0xFF2372EC)
                        : const Color(0xFF8E8E8E),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _useWallet
                    ? Icon(
                        Icons.check,
                        size: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 0.5, color: const Color(0xffB8B8B8)),
        const SizedBox(height: 8),
        // Payment method selector and button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Payment method selector
            Expanded(
              child: GestureDetector(
                onTap: _isBooking ? null : () => _showPaymentMethodBottomSheet(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon and "Pay using" in same row
                    Row(
                      children: [
                        if (_selectedPaymentMethodPackage != null)
                          Image.asset(
                            _getIconForPackage(
                              _selectedPaymentMethodPackage!,
                            ),
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.payment,
                                size: 20,
                                color: Color(0xFF2372EC),
                              );
                            },
                          )
                        else
                          Image.asset(
                            EcliniqIcons.googlePay.assetPath,
                            width: 20,
                            height: 20,
                          ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pay using',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              color: Color(0xff424242),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          EcliniqIcons.arrowUp.assetPath,
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            Color(0xff626060),
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Payment method name below
                    Text(
                      _selectedPaymentMethod ?? 'Google Pay UPI',
                      style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                        fontWeight: FontWeight.w300,
                        color: _selectedPaymentMethod != null
                            ? Color(0xff424242)
                            : Color(0xff8E8E8E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right side - Pay & Confirm button
            GestureDetector(
              onTap: _isBooking ? null : () => _onConfirmVisit(),
              child: Container(
                height: EcliniqTextStyles.getResponsiveButtonHeight(
                  context,
                  baseHeight: 52.0,
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D2372EC),
                      offset: Offset(2, 2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                  color: const Color(0xFF2372EC),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                  ),
                ),
                child: Padding(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                    context,
                    left: 12,
                    top: 6,
                    bottom: 6,
                    right: 12,
                  ),
                  child: _isBooking
                      ? SizedBox(
                          width: 180, // Fixed width for loading state
                          child: const Center(
                            child: EcliniqLoader(size: 24, color: Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Amount and Total
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${_serviceFee.toStringAsFixed(0)}',
                                    style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total',
                                    style: EcliniqTextStyles.responsiveBodyMediumProminent(context).copyWith(
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 34),
                            // Pay & Confirm text
                            Expanded(
                              child: Text(
                                'Pay & Confirm',
                                style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            Transform.rotate(
                              angle: 1.5708,
                              child: SvgPicture.asset(
                                EcliniqIcons.arrowUp.assetPath,
                                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  String _getIconForPackage(String packageName) {
    final paymentMethods = [
      {'packageName': 'in.org.npci.upiapp', 'icon': EcliniqIcons.bhimPay},
      {
        'packageName': 'com.google.android.apps.nbu.paisa.user',
        'icon': EcliniqIcons.googlePay,
      },
      {'packageName': 'com.phonepe.app', 'icon': EcliniqIcons.phonePe},
      {'packageName': 'com.phonepe.simulator', 'icon': EcliniqIcons.phonePe},
    ];

    final method = paymentMethods.firstWhere(
      (m) => m['packageName'] == packageName,
      orElse: () => {'icon': EcliniqIcons.googlePay},
    );
    return (method['icon'] as EcliniqIcons).assetPath;
  }

  Future<void> _showPaymentMethodBottomSheet() async {
    final selectedMethod = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodBottomSheet(
        walletBalance: _walletBalance,
        useWallet: _useWallet,
        serviceFee: _serviceFee,
        isBooking: _isBooking,
        selectedPaymentMethod: _selectedPaymentMethod,
        currentSelectedMethod: _selectedPaymentMethod,
        currentSelectedPackage: _selectedPaymentMethodPackage,
        onWalletToggle: (value) {
          setState(() {
            _useWallet = value;
          });
        },
        onConfirm: () {
          // Payment confirmation is handled in _onConfirmVisit
          // This callback can be used for additional actions if needed
        },
      ),
    );

    if (mounted) {
      setState(() {
        if (selectedMethod != null) {
          _selectedPaymentMethod = selectedMethod['name'] as String?;
          _selectedPaymentMethodPackage =
              selectedMethod['packageName'] as String?;
          if (selectedMethod.containsKey('useWallet')) {
            _useWallet = selectedMethod['useWallet'] as bool;
          }
        } else {
          // If bottom sheet closed without selection, default to Google Pay
          if (_selectedPaymentMethodPackage == null) {
            _selectedPaymentMethod = 'Gpay';
            _selectedPaymentMethodPackage =
                'com.google.android.apps.nbu.paisa.user';
          }
        }
      });
    }
  }

  Future<void> _processUPIPayment({
    required BookingPaymentData paymentData,
    required String selectedUPIPackage,
  }) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Initialize PhonePe SDK if not already initialized
      if (!_phonePeService.isInitialized) {
        final prefs = await SharedPreferences.getInstance();
        final userId =
            prefs.getString('user_id') ??
            'user_${DateTime.now().millisecondsSinceEpoch}';

        const merchantId = 'M237OHQ3YCVAO_2511191950';
        const isProduction =
            false; // Change to true if you have real PhonePe app installed

        final initialized = await _phonePeService.initialize(
          isProduction: isProduction,
          merchantId: merchantId,
          flowId: userId,
          enableLogs: !isProduction,
        );

        if (!initialized) {
          throw PhonePeException('Failed to initialize PhonePe SDK');
        }
      }

      // Open UPI app if specific app selected
      if (selectedUPIPackage != 'com.phonepe.app' &&
          selectedUPIPackage != 'com.phonepe.simulator') {
        try {
          final uri = Uri.parse('package:$selectedUPIPackage');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        } catch (e) {
          debugPrint('Error opening UPI app: $e');
        }
      }

      // Start PhonePe payment
      final result = await _phonePeService.startPayment(
        requestPayload: paymentData.requestPayload,
        token: paymentData.token,
        orderId: paymentData.orderId,
        appSchema: 'ecliniq',
      );

      if (result.success || result.status != 'INCOMPLETE') {
        // Verify payment
        final statusData = await _paymentService.pollPaymentUntilComplete(
          paymentData.merchantTransactionId,
          onStatusUpdate: (status) {
            debugPrint('Payment status: ${status.status}');
          },
        );

        if (statusData != null && statusData.isSuccess) {
          // Verify appointment
          final verifyRequest = VerifyAppointmentRequest(
            appointmentId: paymentData.appointmentId,
            merchantTransactionId: paymentData.merchantTransactionId,
          );

          final verifyResponse = await _appointmentService.verifyAppointment(
            request: verifyRequest,
            authToken: _authToken,
          );

          if (mounted) {
            setState(() {
              _isProcessingPayment = false;
            });

            if (verifyResponse.success && verifyResponse.data != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentRequestScreen(
                    doctorName: widget.doctorName,
                    doctorSpecialization: widget.doctorSpecialization,
                    selectedSlot: widget.selectedSlot,
                    selectedDate: widget.selectedDate,
                    hospitalAddress: _hospitalAddress,
                    tokenNumber: verifyResponse.data!.tokenNo.toString(),
                    patientName: _getCurrentUserName(),
                    patientSubtitle: _getCurrentUserSubtitle(),
                    patientBadge:
                        _selectedDependent?.formattedRelation ?? 'You',
                    merchantTransactionId: paymentData.merchantTransactionId,
                    paymentMethod: paymentData.provider,
                    totalAmount: paymentData.totalAmount,
                    walletAmount: paymentData.walletAmount,
                    gatewayAmount: paymentData.gatewayAmount,
                  ),
                ),
              );
            } else {
             
          CustomErrorSnackBar.show(
                  context: context,
                  title: 'Payment Verification Failed',
                  subtitle: verifyResponse.message,
                  duration: const Duration(seconds: 4),
           
              );
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isProcessingPayment = false;
            });

    CustomErrorSnackBar.show(
                context: context,
                title: 'Payment Failed',
                subtitle: statusData?.status == 'FAILED'
                    ? 'Payment failed. Please try again.'
                    : 'Payment verification timed out. Please check My Visits.',
                duration: const Duration(seconds: 4),
              
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });

       CustomErrorSnackBar.show(
              context: context,
              title: 'Payment Cancelled',
              subtitle: 'Payment was cancelled. You can try booking again.',
              duration: const Duration(seconds: 4),
          
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
       
        CustomErrorSnackBar.show(
            context: context,
            title: 'Payment Error',
            subtitle: e.toString().replaceFirst('Exception: ', ''),
            duration: const Duration(seconds: 4),
      
        );
      }
    }
  }
}

