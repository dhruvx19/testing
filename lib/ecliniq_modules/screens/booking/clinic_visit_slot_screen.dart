import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/models/doctor_booking_response.dart';
import 'package:ecliniq/ecliniq_api/models/slot.dart';
import 'package:ecliniq/ecliniq_api/slot_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/review_details_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/date_selector.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/doctor_info_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/time_slot_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_location_change_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart'
    hide DoctorInfoCard;
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class ClinicVisitSlotScreen extends StatefulWidget {
  final String doctorId;
  final String? hospitalId;
  final String? clinicId;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? appointmentId;
  final AppointmentDetailModel? previousAppointment;
  final bool isReschedule;

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
  Map<DateTime, int> _weeklyTokenCounts = {}; // Map of date to token count

  String? _selectedHospitalId;
  String? _selectedClinicId;

  Doctor? _doctor;
  String? _currentLocationName;
  String? _currentLocationAddress;
  String? _currentDistance;
  bool _isLoadingDoctorDetails = false;

  @override
  void initState() {
    super.initState();
    _selectedHospitalId = widget.hospitalId;
    _selectedClinicId = widget.clinicId;
    _initializeDates();
    // Load slots immediately - don't wait for doctor details
    _fetchWeeklySlots();
    _fetchSlots();
    // Load doctor details in parallel (non-blocking)
    _fetchDoctorDetails();
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
              // Normalize the date to local date (remove time component)
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
      // Silently fail - weekly slots are not critical for functionality
      if (mounted) {
        setState(() {
          _isLoadingWeeklySlots = false;
        });
        debugPrint('Failed to fetch weekly slots: $e');
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
      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        if (mounted) {
          setState(() {
            _isHoldingToken = false;
            _errorMessage = 'Authentication required. Please login again.';
          });
          _showErrorSnackBar('Authentication required. Please login again.');
        }
        return;
      }

      // Call hold token API
      final holdTokenResponse = await _slotService.holdToken(
        slotId: slot.id,
        authToken: authToken,
      );

      if (mounted) {
        if (holdTokenResponse.success && holdTokenResponse.data != null) {
          // Token held successfully, navigate to review screen
          // Use hospitalId/clinicId from slot if available, otherwise fallback to widget values
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
                // Pass doctor data to avoid duplicate API call
                doctor: _doctor,
                locationName: _currentLocationName,
                locationAddress: _currentLocationAddress,
                locationDistance: _currentDistance,
              ),
            ),
          );
        } else {
          // Failed to hold token
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
      // Get auth token from SharedPreferences
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

    if (_selectedHospitalId != null) {
      final hospital = _doctor!.hospitals.firstWhere(
        (h) => h.id == _selectedHospitalId,
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
    } else if (_selectedClinicId != null) {
      final clinic = _doctor!.clinics.firstWhere(
        (c) => c.id == _selectedClinicId,
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

  void _onChangeLocation() async {
    // If doctor details are still loading, wait for them
    if (_doctor == null) {
      if (_isLoadingDoctorDetails) {
        // Show a message that we're loading doctor details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading doctor details...'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      // If not loading and doctor is null, try to fetch again
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

    // Add clinics first
    for (var clinic in _doctor!.clinics) {
      options.add(
        DoctorLocationOption(
          id: clinic.id,
          name: clinic.name,
          address: '${clinic.city ?? ""}, ${clinic.state ?? ""}',
          type: 'Clinic',
          distance: clinic.distance?.toStringAsFixed(1),
        ),
      );
    }

    // Add hospitals
    for (var hospital in _doctor!.hospitals) {
      options.add(
        DoctorLocationOption(
          id: hospital.id,
          name: hospital.name,
          address: '${hospital.city ?? ""}, ${hospital.state ?? ""}',
          type: 'Hospital',
          distance: hospital.distance?.toStringAsFixed(1),
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
        _updateCurrentLocationDetails();

        // Reset slots and fetch for new location
        selectedSlot = null;
        _isLoading = true;
        _isLoadingWeeklySlots = true;
      });

      // Fetch slots and weekly slots for the new location
      _fetchSlots();
      _fetchWeeklySlots();
    }
  }

  Widget _buildShimmerSlots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  // Avatar shimmer
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
                        // Name shimmer
                        ShimmerLoading(
                          width: 200,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        // Specialization shimmer
                        ShimmerLoading(
                          width: 150,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        // Education shimmer
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
              // Experience and rating shimmer
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
              // Location shimmer
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
              // Address shimmer
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
        // Token banner shimmer
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

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load slots',
              style: EcliniqTextStyles.titleXLarge.copyWith(
                color: Colors.grey[600],
              ),
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
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No slots available for this date',
              style: EcliniqTextStyles.headlineLarge.copyWith(
                color: const Color(0xff424242),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please choose another day',
              style: EcliniqTextStyles.titleXLarge.copyWith(
                color: Colors.grey[600],
              ),
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
                    style: EcliniqTextStyles.titleXLarge.copyWith(
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _groupedSlots.length,
        itemBuilder: (context, index) {
          final periodWithSlots = periods
              .where((p) => _groupedSlots.containsKey(p))
              .toList();
          if (index >= periodWithSlots.length) return const SizedBox.shrink();

          final period = periodWithSlots[index];
          final slots = _groupedSlots[period]!;

          slots.sort((a, b) => a.startTime.compareTo(b.startTime));

          final earliestStartUTC = slots
              .map((s) => s.startTime)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final latestEndUTC = slots
              .map((s) => s.endTime)
              .reduce((a, b) => a.isAfter(b) ? a : b);

          final totalAvailable = slots.fold<int>(
            0,
            (sum, slot) => sum + slot.availableTokens,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TimeSlotCard(
              title: period,
              time: _formatTimeRange(earliestStartUTC, latestEndUTC),
              available: totalAvailable,
              iconPath: _getIconPath(period),
              isSelected:
                  selectedSlot != null &&
                  slots.any((s) => s.id == selectedSlot),
              onTap: () {
                _onSlotSelected(slots.first.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviousAppointmentBanner() {
    final appointment = widget.previousAppointment!;

    // Parse date from timeInfo.date (format: "dd MMM, yyyy" or similar)
    String dateLabel = 'Today';
    String dateDisplay = '';

    try {
      // Try to parse the date string
      final dateStr = appointment.timeInfo.date;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Try different date formats
      DateTime? appointmentDate;
      try {
        // Try parsing as "dd MMM, yyyy" format
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
        // If parsing fails, try ISO format
        try {
          appointmentDate = DateTime.parse(dateStr);
        } catch (e2) {
          // If all parsing fails, use today
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

        // Format as "DD MMM"
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
      // Fallback to today's date
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

    // Format token and time
    final tokenText = appointment.tokenNumber != null
        ? 'Your Token #${appointment.tokenNumber}'
        : 'Your booking';
    final timeText = appointment.timeInfo.time.isNotEmpty
        ? ' (Time: ${appointment.timeInfo.time})'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text(
                  'You already have a confirmed booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff424242),
                  ),
                ),
              ),
              FittedBox(
                child: Text(
                  '$tokenText$timeText',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff424242),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Container(
    //   margin: const EdgeInsets.all(16),
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: const Color(0xFFF2F7FF),
    //     borderRadius: BorderRadius.circular(12),
    //     border: Border.all(
    //       color: const Color(0xFF96BFFF),
    //       width: 1,
    //     ),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Row(
    //         children: [
    //           Icon(
    //             Icons.info_outline,
    //             color: const Color(0xFF2372EC),
    //             size: 20,
    //           ),
    //           const SizedBox(width: 8),
    //           Text(
    //             'Previous Appointment Details',
    //             style: EcliniqTextStyles.headlineMedium.copyWith(
    //               color: const Color(0xFF2372EC),
    //               fontWeight: FontWeight.w600,
    //             ),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(height: 12),
    //       if (appointment.tokenNumber != null)
    //         _buildBannerRow(
    //           'Token No',
    //           appointment.tokenNumber!,
    //           Icons.confirmation_number,
    //         ),
    //       const SizedBox(height: 8),
    //       _buildBannerRow(
    //         'Date',
    //         appointment.timeInfo.date,
    //         Icons.calendar_today,
    //       ),
    //       const SizedBox(height: 8),
    //       _buildBannerRow(
    //         'Time',
    //         appointment.timeInfo.time,
    //         Icons.access_time,
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildBannerRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF424242)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: EcliniqTextStyles.titleXLarge.copyWith(
            color: const Color(0xFF626060),
          ),
        ),
        Text(
          value,
          style: EcliniqTextStyles.titleXLarge.copyWith(
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
      height: 52,
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
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isHoldingToken)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: EcliniqLoader(
                    size: 20,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  'Review Visit',
                  style: EcliniqTextStyles.headlineMedium.copyWith(
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
            widget.isReschedule ? 'Reschedule' : 'Clinic Visit Slot',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DateSelector(
                      selectedDate: selectedDateLabel,
                      selectedDateValue: selectedDate,
                      onDateChanged: _onDateChanged,
                      tokenCounts: _weeklyTokenCounts,
                      isLoading: _isLoadingWeeklySlots,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, thickness: 0.3, color: Colors.grey),
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Select Below Slots',
                      style: EcliniqTextStyles.headlineLarge.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Show slots independently - don't wait for doctor details
                  if (_isLoading)
                    _buildShimmerSlots()
                  else if (_errorMessage != null)
                    _buildErrorState()
                  else if (_groupedSlots.isEmpty && !_isLoadingDoctorDetails)
                    _buildEmptyState()
                  else if (_groupedSlots.isNotEmpty)
                    _buildSlotsList()
                  else
                    _buildShimmerSlots(), // Show shimmer while waiting for slots
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          if (selectedSlot != null)
            Container(
              padding: const EdgeInsets.all(16),
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
