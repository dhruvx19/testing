import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/models/slot.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/slot_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/review_details_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/date_selector.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/doctor_info_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/time_slot_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_location_change_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart'
    hide DoctorInfoCard;
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class ClinicVisitSlotScreen extends StatefulWidget {
  final String doctorId;
  final String? hospitalId;
  final String? clinicId;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? appointmentId;
  final AppointmentDetailModel? previousAppointment;
  final bool isReschedule;
  final Doctor? doctor;

  const ClinicVisitSlotScreen({
    super.key,
    required this.doctorId,
    this.hospitalId,
    this.clinicId,
    this.doctorName,
    this.doctorSpecialization,
    this.appointmentId,
    this.previousAppointment,
    this.isReschedule = false,
    this.doctor,
  }) : assert(
         hospitalId != null || clinicId != null,
         'Either hospitalId or clinicId must be provided',
       );

  @override
  State<ClinicVisitSlotScreen> createState() => _ClinicVisitSlotScreenState();
}

class _ClinicVisitSlotScreenState extends State<ClinicVisitSlotScreen> {
  final SlotService _slotService = SlotService();
  final DoctorService _doctorService = DoctorService();
  final PatientService _patientService = PatientService();

  String? selectedSlot;
  String selectedDateLabel = 'Today';
  DateTime? selectedDate;
  bool _isButtonPressed = false;
  bool _isLoading = false;
  bool _isLoadingWeeklySlots = false;
  bool _isHoldingToken = false;
  String? _errorMessage;

  List<Slot> _slots = [];
  Map<String, List<Slot>> _groupedSlots = {};
  final Map<DateTime, int> _weeklyTokenCounts = {};

  String? _selectedHospitalId;
  String? _selectedClinicId;

  Doctor? _doctor;
  String? _currentLocationName;
  String? _currentLocationAddress;
  String? _currentDistance;
  bool _isLoadingDoctorDetails = false;
  String? _currentTokenNumber;

  PatientDetailsData? _currentUserDetails;

  String? _cachedAuthToken;
  SharedPreferences? _cachedPrefs;

  @override
  void initState() {
    super.initState();
    _selectedHospitalId = widget.hospitalId;
    _selectedClinicId = widget.clinicId;
    _initializeDates();

    if (widget.doctor != null) {
      _doctor = widget.doctor;
      _updateCurrentLocationDetails().then((_) {
        if (mounted) {
          setState(() {
            _isLoadingDoctorDetails = false;
          });
        }
      });
    }

    _fetchWeeklySlots();
    _fetchSlots();

    if (widget.doctor == null) {
      _fetchDoctorDetails();
    }
    _fetchCurrentUserDetails();
    _fetchCurrentTokenNumber();
  }

  void _initializeDates() {
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    selectedDateLabel = _formatDateLabel(selectedDate!);
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]}, ${date.day} ${_getMonthName(date.month)}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchCurrentTokenNumber() async {
    try {
      // Ensure auth token is retrieved
      _cachedPrefs ??= await SharedPreferences.getInstance();
      _cachedAuthToken ??= _cachedPrefs!.getString('auth_token');

      final response = await _doctorService.getDoctorDetailsById(
        doctorId: widget.doctorId,
        authToken: _cachedAuthToken,
      );

      if (mounted && response.success && response.data != null) {
        setState(() {
          _currentTokenNumber = response.data!.currentTokenNumber?.toString();
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchWeeklySlots() async {
    setState(() {
      _isLoadingWeeklySlots = true;
    });

    try {
      final response = await _slotService.findWeeklySlots(
        doctorId: widget.doctorId,
        hospitalId: _selectedHospitalId,
        clinicId: _selectedClinicId,
      );

      if (mounted) {
        setState(() {
          _isLoadingWeeklySlots = false;
          if (response.success) {
            _weeklyTokenCounts.clear();
            for (final weeklySlot in response.data) {
              final dateOnly = DateTime(
                weeklySlot.date.year,
                weeklySlot.date.month,
                weeklySlot.date.day,
              );
              _weeklyTokenCounts[dateOnly] = weeklySlot.totalAvailableTokens;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeeklySlots = false;
        });
      }
    }
  }

  Future<void> _fetchSlots() async {
    if (selectedDate == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _slots = [];
      _groupedSlots = {};
      selectedSlot = null;
    });

    try {
      final response = await _slotService.findSlotsByDoctorAndDate(
        doctorId: widget.doctorId,
        hospitalId: _selectedHospitalId,
        clinicId: _selectedClinicId,
        date: _formatDateForApi(selectedDate!),
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _slots = response.data;
            _groupSlots();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch slots: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  DateTime _convertToIST(DateTime utcTime) {
    final utcDateTime = utcTime.isUtc
        ? utcTime
        : DateTime.utc(
            utcTime.year,
            utcTime.month,
            utcTime.day,
            utcTime.hour,
            utcTime.minute,
            utcTime.second,
          );
    return utcDateTime.add(const Duration(hours: 5, minutes: 30));
  }

  DateTime _getSlotDateTime(DateTime slotTime, DateTime selectedDate) {
    final istTime = _convertToIST(slotTime);
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      istTime.hour,
      istTime.minute,
      istTime.second,
    );
  }

  int _getHourInIST(DateTime slotTimeUTC) {
    final utcTime = slotTimeUTC.isUtc
        ? slotTimeUTC
        : DateTime.utc(
            slotTimeUTC.year,
            slotTimeUTC.month,
            slotTimeUTC.day,
            slotTimeUTC.hour,
            slotTimeUTC.minute,
            slotTimeUTC.second,
          );

    final istTime = utcTime.add(const Duration(hours: 5, minutes: 30));

    return istTime.hour;
  }

  void _groupSlots() {
    _groupedSlots.clear();

    if (selectedDate == null) return;

    for (final slot in _slots) {
      final hourIST = _getHourInIST(slot.startTime);

      String period;
      if (hourIST >= 5 && hourIST < 12) {
        period = 'Morning';
      } else if (hourIST >= 12 && hourIST < 17) {
        period = 'Afternoon';
      } else if (hourIST >= 17 && hourIST < 21) {
        period = 'Evening';
      } else {
        period = 'Night';
      }

      if (!_groupedSlots.containsKey(period)) {
        _groupedSlots[period] = [];
      }
      _groupedSlots[period]!.add(slot);
    }
  }

  String _formatTime(DateTime timeIST) {
    final hour = timeIST.hour;
    final minute = timeIST.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr$period';
  }

  String _formatTimeRange(DateTime startUTC, DateTime endUTC) {
    if (selectedDate == null) return '';

    final startIST = _getSlotDateTime(startUTC, selectedDate!);
    final endIST = _getSlotDateTime(endUTC, selectedDate!);

    final startFormatted = _formatTime(startIST);
    final endFormatted = _formatTime(endIST);
    return '$startFormatted - $endFormatted';
  }

  String _getIconPath(String period) {
    switch (period) {
      case 'Morning':
        return EcliniqIcons.morning.assetPath;
      case 'Afternoon':
        return EcliniqIcons.afternoon.assetPath;
      case 'Evening':
        return EcliniqIcons.evening.assetPath;
      case 'Night':
        return EcliniqIcons.night.assetPath;
      default:
        return EcliniqIcons.morning.assetPath;
    }
  }

  String _getDefaultTimeRange(String period) {
    if (selectedDate == null) return '';

    DateTime startTime;
    DateTime endTime;

    switch (period) {
      case 'Morning':
        startTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          5,
          0,
        );
        endTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          12,
          0,
        );
        break;
      case 'Afternoon':
        startTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          12,
          0,
        );
        endTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          17,
          0,
        );
        break;
      case 'Evening':
        startTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          17,
          0,
        );
        endTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          21,
          0,
        );
        break;
      case 'Night':
        startTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          21,
          0,
        );
        endTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          23,
          59,
        );
        break;
      default:
        startTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          5,
          0,
        );
        endTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          12,
          0,
        );
    }

    final startFormatted = _formatTime(startTime);
    final endFormatted = _formatTime(endTime);
    return '$startFormatted - $endFormatted';
  }

  bool _isSlotDisabled(List<Slot> slots) {
    if (slots.isEmpty) return true;

    final hasAvailableSlot = slots.any(
      (slot) =>
          slot.availableTokens > 0 &&
          slot.slotStatus != 'COMPLETED' &&
          slot.slotStatus != 'CANCELLED',
    );

    return !hasAvailableSlot;
  }

  void _onSlotSelected(String slotId) {
    setState(() {
      selectedSlot = slotId;
    });
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
      selectedDateLabel = _formatDateLabel(date);
    });
    _fetchSlots();
  }

  Future<void> _onReviewVisit() async {
    if (selectedSlot == null || _isHoldingToken) return;

    final slot = _slots.firstWhere((s) => s.id == selectedSlot);

    setState(() {
      _isHoldingToken = true;
      _errorMessage = null;
    });

    try {
      _cachedPrefs ??= await SharedPreferences.getInstance();
      _cachedAuthToken ??= _cachedPrefs!.getString('auth_token');

      if (_cachedAuthToken == null || _cachedAuthToken!.isEmpty) {
        if (mounted) {
          setState(() {
            _isHoldingToken = false;
            _errorMessage = 'Authentication required. Please login again.';
          });
          _showErrorSnackBar('Authentication required. Please login again.');
        }
        return;
      }

      final holdTokenResponse = await _slotService.holdToken(
        slotId: slot.id,
        authToken: _cachedAuthToken!,
      );

      if (mounted) {
        if (holdTokenResponse.success && holdTokenResponse.data != null) {
          final hospitalIdFromSlot = slot.hospitalId.isNotEmpty
              ? slot.hospitalId
              : _selectedHospitalId;
          final clinicIdFromSlot =
              slot.clinicId != null && slot.clinicId!.isNotEmpty
              ? slot.clinicId
              : _selectedClinicId;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewDetailsScreen(
                selectedSlot: _formatTimeRange(slot.startTime, slot.endTime),
                selectedDate: selectedDateLabel,
                doctorId: slot.doctorId.isNotEmpty
                    ? slot.doctorId
                    : widget.doctorId,
                hospitalId: hospitalIdFromSlot,
                clinicId: clinicIdFromSlot,
                slotId: slot.id,
                doctorName: widget.doctorName,
                doctorSpecialization: widget.doctorSpecialization,
                appointmentId: widget.appointmentId,
                previousAppointment: widget.previousAppointment,
                isReschedule: widget.isReschedule,

                doctor: _doctor,
                locationName: _currentLocationName,
                locationAddress: _currentLocationAddress,
                locationDistance: _currentDistance,

                currentUserDetails: _currentUserDetails,
              ),
            ),
          );
        } else {
          final errorMsg = holdTokenResponse.message.isNotEmpty
              ? holdTokenResponse.message
              : 'Failed to reserve slot. Please try again.';
          setState(() {
            _errorMessage = errorMsg;
          });
          _showErrorSnackBar(errorMsg);
        }
        setState(() {
          _isHoldingToken = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isHoldingToken = false;
          _errorMessage = 'Failed to reserve slot: ${e.toString()}';
        });
        _showErrorSnackBar('Failed to reserve slot. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _fetchDoctorDetails() async {
    setState(() {
      _isLoadingDoctorDetails = true;
    });

    try {
      _cachedPrefs ??= await SharedPreferences.getInstance();
      _cachedAuthToken ??= _cachedPrefs!.getString('auth_token');

      final response = await _doctorService.getDoctorDetailsForBooking(
        doctorId: widget.doctorId,
        authToken: _cachedAuthToken,
      );

      print('🔍 API Response - Success: ${response.success}');
      if (response.data != null) {
        print('🔍 Doctor: ${response.data!.name}');
        print('🔍 Hospitals count: ${response.data!.hospitals.length}');
        print('🔍 Clinics count: ${response.data!.clinics.length}');
      }

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _doctor = response.data;
            _isLoadingDoctorDetails = false;
          });
          // Update location details after state is set
          await _updateCurrentLocationDetails();
          if (mounted) {
            setState(() {});
          }
        } else {
          setState(() {
            _isLoadingDoctorDetails = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDoctorDetails = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentUserDetails() async {
    setState(() {});

    try {
      _cachedPrefs ??= await SharedPreferences.getInstance();
      _cachedAuthToken ??= _cachedPrefs!.getString('auth_token');

      if (_cachedAuthToken == null || _cachedAuthToken!.isEmpty) {
        setState(() {});
        return;
      }

      final response = await _patientService.getPatientDetails(
        authToken: _cachedAuthToken!,
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _currentUserDetails = response.data;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _updateCurrentLocationDetails() async {
    if (_doctor == null) return;

    // Debug logging
    print('🏥 Doctor has ${_doctor!.hospitals.length} hospitals and ${_doctor!.clinics.length} clinics');

    // Get user's current location for distance calculation
    final storedLocation = await LocationStorageService.getStoredLocation();
    double? userLat = storedLocation?['latitude'] as double?;
    double? userLng = storedLocation?['longitude'] as double?;

    // Fallback to Bangalore coordinates if user location not available
    if (userLat == null || userLng == null) {
      userLat = 12.9716;
      userLng = 77.5946;
      print('📍 User location (fallback): lat=$userLat, lng=$userLng');
    } else {
      print('📍 User location (stored): lat=$userLat, lng=$userLng');
    }

    if (_selectedHospitalId != null) {
      final hospital = _doctor!.hospitals.firstWhere(
        (h) => h.id == _selectedHospitalId,
        orElse: () => _doctor!.hospitals.isNotEmpty
            ? _doctor!.hospitals.first
            : DoctorHospital(id: '', name: ''),
      );
      
      print('🏥 Hospital: ${hospital.name}, lat=${hospital.latitude}, lng=${hospital.longitude}, distance=${hospital.distance}');
      
      if (hospital.id.isNotEmpty) {
        _currentLocationName = hospital.name;
        _currentLocationAddress =
            '${hospital.city ?? ""}, ${hospital.state ?? ""}';
        
        // Calculate distance dynamically using user's location and hospital coordinates
        if (userLat != null && userLng != null && 
            hospital.latitude != null && hospital.longitude != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            userLat,
            userLng,
            hospital.latitude!,
            hospital.longitude!,
          );
          final distanceInKm = distanceInMeters / 1000;
          print('📏 Calculated distance: ${distanceInKm.toStringAsFixed(1)} Km');
          // Show minimum 0.2 Km if too close (better UX than showing 0.0)
          _currentDistance = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
        } else if (hospital.distance != null && hospital.distance! > 0) {
          // Fallback to API distance if available
          final distanceInKm = hospital.distance! / 1000;
          print('📏 API distance: ${distanceInKm.toStringAsFixed(1)} Km');
          // Show minimum 0.2 Km if too close
          _currentDistance = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
        } else {
          print('❌ No distance data available');
          // Don't show distance if location data is unavailable
          _currentDistance = null;
        }
        
        print('✅ Final distance to display: $_currentDistance');
      }
    } else if (_selectedClinicId != null) {
      final clinic = _doctor!.clinics.firstWhere(
        (c) => c.id == _selectedClinicId,
        orElse: () => _doctor!.clinics.isNotEmpty
            ? _doctor!.clinics.first
            : DoctorClinic(id: '', name: ''),
      );
      print('🏥 Clinic: ${clinic.name}, lat=${clinic.latitude}, lng=${clinic.longitude}, distance=${clinic.distance}');
      
      if (clinic.id.isNotEmpty) {
        _currentLocationName = clinic.name;
        _currentLocationAddress = '${clinic.city ?? ""}, ${clinic.state ?? ""}';
        
        // Calculate distance dynamically using user's location and clinic coordinates
        if (userLat != null && userLng != null && 
            clinic.latitude != null && clinic.longitude != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            userLat,
            userLng,
            clinic.latitude!,
            clinic.longitude!,
          );
          final distanceInKm = distanceInMeters / 1000;
          print('📏 Calculated distance: ${distanceInKm.toStringAsFixed(1)} Km');
          // Show minimum 0.2 Km if too close
          _currentDistance = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
        } else if (clinic.distance != null && clinic.distance! > 0) {
          // Fallback to API distance if available
          final distanceInKm = clinic.distance! / 1000;
          print('📏 API distance: ${distanceInKm.toStringAsFixed(1)} Km');
          // Show minimum 0.2 Km if too close
          _currentDistance = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
        } else {
          print('❌ No distance data available');
          // Don't show distance if location data is unavailable
          _currentDistance = null;
        }
        
        print('✅ Final distance to display: $_currentDistance');
      }
    }
  }

  void _onChangeLocation() async {
    if (_doctor == null) {
      if (_isLoadingDoctorDetails) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading doctor details...'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      await _fetchDoctorDetails();
      if (_doctor == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load doctor details. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final List<DoctorLocationOption> options = [];

    // Get user's location for distance calculation
    final storedLocation = await LocationStorageService.getStoredLocation();
    double? userLat = storedLocation?['latitude'] as double?;
    double? userLng = storedLocation?['longitude'] as double?;

    // Fallback to Bangalore coordinates if user location not available
    if (userLat == null || userLng == null) {
      userLat = 12.9716;
      userLng = 77.5946;
    }

    for (var clinic in _doctor!.clinics) {
      String? distanceStr;
      
      // Calculate distance dynamically
      if (userLat != null && userLng != null && 
          clinic.latitude != null && clinic.longitude != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLng,
          clinic.latitude!,
          clinic.longitude!,
        );
        final distanceInKm = distanceInMeters / 1000;
        // Show minimum 0.2 Km if too close
        distanceStr = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
      } else if (clinic.distance != null && clinic.distance! > 0) {
        final distanceInKm = clinic.distance! / 1000;
        // Show minimum 0.2 Km if too close
        distanceStr = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
      }
      
      options.add(
        DoctorLocationOption(
          id: clinic.id,
          name: clinic.name,
          address: '${clinic.city ?? ""}, ${clinic.state ?? ""}',
          type: 'Clinic',
          distance: distanceStr,
        ),
      );
    }

    for (var hospital in _doctor!.hospitals) {
      String? distanceStr;
      
      // Calculate distance dynamically
      if (userLat != null && userLng != null && 
          hospital.latitude != null && hospital.longitude != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLng,
          hospital.latitude!,
          hospital.longitude!,
        );
        final distanceInKm = distanceInMeters / 1000;
        // Show minimum 0.2 Km if too close
        distanceStr = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
      } else if (hospital.distance != null && hospital.distance! > 0) {
        final distanceInKm = hospital.distance! / 1000;
        // Show minimum 0.2 Km if too close
        distanceStr = distanceInKm < 0.2 ? '0.2' : distanceInKm.toStringAsFixed(1);
      }
      
      options.add(
        DoctorLocationOption(
          id: hospital.id,
          name: hospital.name,
          address: '${hospital.city ?? ""}, ${hospital.state ?? ""}',
          type: 'Hospital',
          distance: distanceStr,
        ),
      );
    }

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No locations available for this doctor.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final selected = await EcliniqBottomSheet.show(
      context: context,
      child: DoctorLocationChangeSheet(
        doctorName: _doctor!.name,
        locations: options,
        selectedLocationId: _selectedHospitalId ?? _selectedClinicId,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        if (selected.type == 'Hospital') {
          _selectedHospitalId = selected.id;
          _selectedClinicId = null;
        } else {
          _selectedClinicId = selected.id;
          _selectedHospitalId = null;
        }

        selectedSlot = null;
        _isLoading = true;
        _isLoadingWeeklySlots = true;
      });

      // Update location details with calculated distance
      await _updateCurrentLocationDetails();
      if (mounted) {
        setState(() {});
      }

      _fetchSlots();
      _fetchWeeklySlots();
    }
  }

  Widget _buildShimmerSlots() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: EcliniqTextStyles.getResponsiveSize(context, 16),
      ),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          );
        }),
      ),
    );
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
        const Divider(height: 0.5, thickness: 0.5, color: Color(0xffD6D6D6)),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 48),
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load slots',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSlots,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2372EC),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No slots available for this date',
              style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                  .copyWith(
                    color: const Color(0xff424242),
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please choose another day',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1565C0).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select a different date above',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    final periods = ['Morning', 'Afternoon', 'Evening', 'Night'];

    if (selectedDate == null) return const SizedBox.shrink();

    // Filter out periods with no slots
    final availablePeriods = periods.where((period) {
      final slots = _groupedSlots[period] ?? [];
      return slots.isNotEmpty;
    }).toList();

    if (availablePeriods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: EcliniqTextStyles.getResponsiveSize(context, 16),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: availablePeriods.length,
        itemBuilder: (context, index) {
          final period = availablePeriods[index];
          final slots = _groupedSlots[period] ?? [];

          // Since we filtered, slots should never be empty here
          slots.sort((a, b) => a.startTime.compareTo(b.startTime));

          final earliestStartUTC = slots
              .map((s) => s.startTime)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final latestEndUTC = slots
              .map((s) => s.endTime)
              .reduce((a, b) => a.isAfter(b) ? a : b);

          final timeRange = _formatTimeRange(earliestStartUTC, latestEndUTC);
          final totalAvailable = slots.fold<int>(
            0,
            (sum, slot) => sum + slot.availableTokens,
          );

          // Grey out only if there are slots but no available tokens
          final isDisabled = totalAvailable == 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: EcliniqTextStyles.getResponsiveSize(context, 12),
            ),
            child: TimeSlotCard(
              title: period,
              time: timeRange,
              available: totalAvailable,
              iconPath: _getIconPath(period),
              isSelected:
                  !isDisabled &&
                  selectedSlot != null &&
                  slots.any((s) => s.id == selectedSlot),
              isDisabled: isDisabled,
              onTap: () {
                if (!isDisabled && slots.isNotEmpty) {
                  _onSlotSelected(slots.first.id);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviousAppointmentBanner() {
    final appointment = widget.previousAppointment!;

    String dateLabel = 'Today';
    String dateDisplay = '';

    try {
      final dateStr = appointment.timeInfo.date;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime? appointmentDate;
      try {
        final parts = dateStr.split(',');
        if (parts.length == 2) {
          final datePart = parts[0].trim();
          final yearPart = parts[1].trim();
          final monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final dateParts = datePart.split(' ');
          if (dateParts.length == 2) {
            final day = int.tryParse(dateParts[0]);
            final monthName = dateParts[1];
            final month = monthNames.indexOf(monthName) + 1;
            final year = int.tryParse(yearPart);
            if (day != null && month > 0 && year != null) {
              appointmentDate = DateTime(year, month, day);
            }
          }
        }
      } catch (e) {
        try {
          appointmentDate = DateTime.parse(dateStr);
        } catch (e2) {
          appointmentDate = today;
        }
      }

      if (appointmentDate != null) {
        final dateOnly = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
        );
        final tomorrow = today.add(const Duration(days: 1));

        if (dateOnly == today) {
          dateLabel = 'Today';
        } else if (dateOnly == tomorrow) {
          dateLabel = 'Tomorrow';
        } else {
          final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          dateLabel = weekdays[dateOnly.weekday - 1];
        }

        final monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        dateDisplay = '${dateOnly.day} ${monthNames[dateOnly.month - 1]}';
      } else {
        dateLabel = 'Today';
        final monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        dateDisplay = '${today.day} ${monthNames[today.month - 1]}';
      }
    } catch (e) {
      final now = DateTime.now();
      dateLabel = 'Today';
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      dateDisplay = '${now.day} ${monthNames[now.month - 1]}';
    }

    final tokenText = appointment.tokenNumber != null
        ? 'Your Token #${appointment.tokenNumber}'
        : 'Your booking';
    final timeText = appointment.timeInfo.time.isNotEmpty
        ? ' (Time: ${appointment.timeInfo.time})'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(color: Color(0xffF8FAFF)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(0xff3EAF3F),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  dateLabel,
                  style: EcliniqTextStyles.responsiveBody2xSmallRegular(
                    context,
                  ).copyWith(fontWeight: FontWeight.w400, color: Colors.white),
                ),
                Text(
                  dateDisplay,
                  style: EcliniqTextStyles.responsiveHeadlineLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    'You already have a confirmed booking',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff424242),
                        ),

                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$tokenText$timeText',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context)
                      .copyWith(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff424242),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: EcliniqTextStyles.getResponsiveIconSize(context, 16),
          color: const Color(0xFF424242),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(color: const Color(0xFF626060)),
        ),
        Text(
          value,
          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
            color: const Color(0xFF424242),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewVisitButton() {
    final isButtonEnabled = selectedSlot != null && !_isHoldingToken;

    return SizedBox(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          if (isButtonEnabled) {
            setState(() {
              _isButtonPressed = true;
            });
          }
        },
        onTapUp: (_) {
          if (isButtonEnabled) {
            setState(() {
              _isButtonPressed = false;
            });
            _onReviewVisit();
          }
        },
        onTapCancel: () {
          setState(() {
            _isButtonPressed = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: _isButtonPressed
                ? const Color(0xFF0E4395)
                : isButtonEnabled
                ? EcliniqButtonType.brandPrimary.backgroundColor(context)
                : EcliniqButtonType.brandPrimary.disabledBackgroundColor(
                    context,
                  ),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isHoldingToken)
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 20),
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 20),

                  child: EcliniqLoader(size: 20, color: Colors.white),
                )
              else
                Text(
                  'Review Visit',
                  style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                      .copyWith(
                        color: _isButtonPressed
                            ? Colors.white
                            : isButtonEnabled
                            ? Colors.white
                            : Colors.grey,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.isReschedule ? 'Reschedule Visit Slot' : 'Clinic Visit Slot',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
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
                  EcliniqIcons.questionCircleFilled.assetPath,
                  width: EcliniqTextStyles.getResponsiveSize(context, 24.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSize(context, 4.0),
                ),
                Text(
                  'Help',
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                      .copyWith(
                        color: const Color(0xFF424242),
                        fontWeight: FontWeight.w400,
                      ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
          child: Container(
            color: Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isReschedule && widget.previousAppointment != null)
                    _buildPreviousAppointmentBanner(),
                  if (_isLoadingDoctorDetails)
                    _buildDoctorInfoShimmer()
                  else
                    DoctorInfoCard(
                      doctor: _doctor,
                      doctorName: widget.doctorName,
                      specialization: widget.doctorSpecialization,
                      locationName: _currentLocationName,
                      locationAddress: _currentLocationAddress,
                      locationDistance: _currentDistance,
                      onChangeLocation: _onChangeLocation,
                    ),
                  if (_currentTokenNumber != null) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: EcliniqTextStyles.getResponsiveSize(
                          context,
                          16,
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffF8FAFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Token Number Currently Running',
                              style: EcliniqTextStyles.responsiveTitleXLarge(
                                context,
                              ).copyWith(color: Color(0xff626060)),
                            ),
                            SizedBox(width: 14),
                            _AnimatedDot(),
                            SizedBox(width: 4),
                            Text(
                              _currentTokenNumber!,
                              style:
                                  EcliniqTextStyles.responsiveHeadlineLargeBold(
                                    context,
                                  ).copyWith(
                                    color: Color(0xFF3EAF3F),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: EcliniqTextStyles.getResponsiveSize(
                        context,
                        16,
                      ),
                    ),
                    child: DateSelector(
                      selectedDate: selectedDateLabel,
                      selectedDateValue: selectedDate,
                      onDateChanged: _onDateChanged,
                      tokenCounts: _weeklyTokenCounts,
                      isLoading: _isLoadingWeeklySlots,
                    ),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveHeight(context, 12),
                  ),
                  const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Color(0xffD6D6D6),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveHeight(context, 24),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: EcliniqTextStyles.getResponsiveSize(
                        context,
                        16,
                      ),
                    ),
                    child: Text(
                      'Select Below Slots',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(
                        context,
                      ).copyWith(color: Color(0xff424242)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    _buildShimmerSlots()
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else if (_groupedSlots.isEmpty && !_isLoadingDoctorDetails)
                    _buildEmptyState()
                  else if (_groupedSlots.isNotEmpty)
                    _buildSlotsList()
                  else
                    _buildShimmerSlots(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          if (selectedSlot != null)
            Container(
              padding: EdgeInsets.all(
                EcliniqTextStyles.getResponsiveSize(context, 16),
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                color: Colors.white,
              ),
              child: SafeArea(child: _buildReviewVisitButton()),
            ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot();

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Color(0xff3EAF3F),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
