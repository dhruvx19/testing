import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/ratings/rate_your_exp_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class AppointmentDetailModel {
  final String id;
  final String status;
  final String? tokenNumber;
  final String? expectedTime;
  final String? currentTokenNumber;
  final DoctorInfo doctor;
  final PatientInfo patient;
  final AppointmentTimeInfo timeInfo;
  final ClinicInfo clinic;
  final PaymentInfo payment;
  final int? rating;
  final String? doctorId;
  final String? hospitalId;
  final String? clinicId;
  final bool? _isRescheduled;

  AppointmentDetailModel({
    required this.id,
    required this.status,
    this.tokenNumber,
    this.expectedTime,
    this.currentTokenNumber,
    required this.doctor,
    required this.patient,
    required this.timeInfo,
    required this.clinic,
    required this.payment,
    this.rating,
    this.doctorId,
    this.hospitalId,
    this.clinicId,
    bool? isRescheduled,
  }) : _isRescheduled = isRescheduled;

  bool get isRescheduled => _isRescheduled ?? false;

  factory AppointmentDetailModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDetailModel(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      tokenNumber: json['token_number'],
      expectedTime: json['expected_time'],
      currentTokenNumber: json['current_token_number'],
      doctor: DoctorInfo.fromJson(json['doctor'] ?? {}),
      patient: PatientInfo.fromJson(json['patient'] ?? {}),
      timeInfo: AppointmentTimeInfo.fromJson(json['time_info'] ?? {}),
      clinic: ClinicInfo.fromJson(json['clinic'] ?? {}),
      payment: PaymentInfo.fromJson(json['payment'] ?? {}),
      rating: json['rating'],
      doctorId: json['doctor_id'],
      hospitalId: json['hospital_id'],
      clinicId: json['clinic_id'],
      isRescheduled: json['is_rescheduled'] == null
          ? null
          : (json['is_rescheduled'] == true ||
                json['is_rescheduled'] == 'true' ||
                json['is_rescheduled'] == 1),
    );
  }

  /// Factory method to convert from API AppointmentDetailData
  factory AppointmentDetailModel.fromApiData(AppointmentDetailData apiData) {
    // Map status to lowercase for UI
    String status = apiData.status.toLowerCase();
    if (status == 'served') {
      status = 'completed';
    } else if (status == 'pending') {
      status = 'requested';
    } else if (status == 'checked_in') {
      status = 'confirmed';
    }

    // Combine date and time - startTime might have wrong date (1970-01-01), so use schedule.date
    final appointmentDate = apiData.schedule.date;
    final startTime = apiData.schedule.startTime;
    // Create a proper DateTime by combining the date from schedule.date with time from startTime
    final combinedDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      startTime.hour,
      startTime.minute,
    );

    // Format date
    final dateFormat = DateFormat('dd MMM, yyyy');
    final dateStr = dateFormat.format(appointmentDate);

    // Format time
    final timeFormat = DateFormat('hh:mm a');
    final timeStr = timeFormat.format(combinedDateTime);

    // Calculate age from DOB
    final now = DateTime.now();
    final dob = apiData.patient.dob;
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    // Get clinic/hospital info from location
    final location = apiData.location;
    final clinicName = location.name;

    // Parse and format address
    String formattedAddress = '';
    String city = '';
    String pincode = '';
    double latitude = 0.0;
    double longitude = 0.0;

    if (location.type == 'CLINIC' && apiData.doctor.primaryClinic != null) {
      final primaryClinic = apiData.doctor.primaryClinic!;
      // For clinics, prefer primary clinic address if available, otherwise use location address
      formattedAddress = primaryClinic.address.isNotEmpty
          ? primaryClinic.address
          : location.address;

      // Extract city and pincode from address
      final addressParts = formattedAddress.split(',');
      if (addressParts.length > 2) {
        city = addressParts[addressParts.length - 2].trim();
      }
      if (addressParts.isNotEmpty) {
        final lastPart = addressParts.last.trim();
        if (RegExp(r'^\d{6}$').hasMatch(lastPart)) {
          pincode = lastPart;
        }
      }
      latitude = double.tryParse(primaryClinic.latitude) ?? 0.0;
      longitude = double.tryParse(primaryClinic.longitude) ?? 0.0;
    } else if (location.type == 'HOSPITAL' &&
        apiData.doctor.associatedHospitals.isNotEmpty) {
      final hospital = apiData.doctor.associatedHospitals.firstWhere(
        (h) => h.id == location.id,
        orElse: () => apiData.doctor.associatedHospitals.first,
      );
      city = hospital.city;
      pincode = hospital.pincode;
      latitude = hospital.latitude;
      longitude = hospital.longitude;

      // Parse JSON address for hospitals
      formattedAddress = _parseHospitalAddress(location.address, hospital);
    } else {
      // Fallback: use address as-is
      formattedAddress = location.address;
    }

    // Format consultation type
    String consultationType = apiData.type == 'ONLINE'
        ? 'Online Consultation'
        : 'In-Clinic Consultation';

    // Get consultation fee - prefer top-level fees, fallback to doctor fees
    final consultationFee =
        apiData.consultationFee ?? apiData.doctor.consultationFee ?? 0.0;
    final followUpFee =
        apiData.followUpFee ?? apiData.doctor.followUpFee ?? 0.0;
    final serviceFee = 0.0; // Service fee not in API response
    final totalPayable = consultationFee + serviceFee;

    // Extract doctorId, hospitalId, and clinicId
    final doctorId = apiData.doctor.userId;
    String? hospitalId;
    String? clinicId;

    if (location.type == 'HOSPITAL') {
      hospitalId = location.id;
      clinicId = null;
    } else if (location.type == 'CLINIC') {
      clinicId = location.id;
      hospitalId = null;
    }

    return AppointmentDetailModel(
      id: apiData.appointmentId,
      status: status,
      tokenNumber: apiData.tokenNo?.toString(),
      expectedTime: null, // Not available in API
      currentTokenNumber: null, // Not available in API
      doctor: DoctorInfo(
        name: apiData.doctor.name,
        specialization: apiData.doctor.specialties.isNotEmpty
            ? apiData.doctor.specialties.join(', ')
            : 'General Physician',
        qualification: apiData.doctor.degrees.isNotEmpty
            ? apiData.doctor.degrees.join(', ')
            : 'MBBS',
        rating: 0.0, // Not available in API
        yearsOfExperience: apiData.doctor.workExperience ?? 0,
        profileImage: apiData.doctor.profilePhoto,
      ),
      patient: PatientInfo(
        name: apiData.patient.name,
        gender: apiData.patient.gender,
        dateOfBirth: DateFormat('dd MMM, yyyy').format(apiData.patient.dob),
        age: age,
        isSelf: apiData.bookedFor == 'SELF',
      ),
      timeInfo: AppointmentTimeInfo(
        date: dateStr,
        time: timeStr,
        displayDate: dateStr,
        consultationType: consultationType,
      ),
      clinic: ClinicInfo(
        name: clinicName,
        address: formattedAddress,
        city: city,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        distanceKm: 0.0, // Not available in API
      ),
      payment: PaymentInfo(
        consultationFee: consultationFee,
        followUpFee: followUpFee,
        serviceFee: serviceFee,
        totalPayable: totalPayable,
        isServiceFeeWaived: serviceFee == 0,
        waiverMessage: serviceFee == 0
            ? 'We care for you and provide a free booking'
            : '',
      ),
      rating: apiData.rating,
      doctorId: doctorId,
      hospitalId: hospitalId,
      clinicId: clinicId,
      isRescheduled: apiData.isRescheduled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'token_number': tokenNumber,
      'expected_time': expectedTime,
      'current_token_number': currentTokenNumber,
      'doctor': doctor.toJson(),
      'patient': patient.toJson(),
      'time_info': timeInfo.toJson(),
      'clinic': clinic.toJson(),
      'payment': payment.toJson(),
      'rating': rating,
      if (doctorId != null) 'doctor_id': doctorId,
      if (hospitalId != null) 'hospital_id': hospitalId,
      if (clinicId != null) 'clinic_id': clinicId,
      'is_rescheduled': isRescheduled,
    };
  }
}

/// Helper function to parse and format hospital address from JSON string
String _parseHospitalAddress(
  String addressString,
  AssociatedHospital hospital,
) {
  try {
    // Check if address is a JSON string
    if (addressString.trim().startsWith('{')) {
      final addressJson = jsonDecode(addressString) as Map<String, dynamic>;
      final parts = <String>[];

      // Add street if available
      if (addressJson['street'] != null &&
          addressJson['street'].toString().isNotEmpty) {
        parts.add(addressJson['street'].toString());
      }

      // Add block number if available
      if (addressJson['blockNo'] != null &&
          addressJson['blockNo'].toString().isNotEmpty) {
        parts.add(addressJson['blockNo'].toString());
      }

      // Add city and state from hospital object
      if (hospital.city.isNotEmpty) {
        parts.add(hospital.city);
      }
      if (hospital.state.isNotEmpty) {
        parts.add(hospital.state);
      }

      // Add landmark if available
      if (addressJson['landmark'] != null &&
          addressJson['landmark'].toString().isNotEmpty) {
        parts.add('Near ${addressJson['landmark']}');
      }

      // Add pincode
      if (hospital.pincode.isNotEmpty) {
        parts.add(hospital.pincode);
      }

      return parts.isEmpty ? addressString : parts.join(', ');
    } else {
      // If not JSON, return as-is but append city, state, pincode if available
      final parts = <String>[addressString];
      if (hospital.city.isNotEmpty) {
        parts.add(hospital.city);
      }
      if (hospital.state.isNotEmpty) {
        parts.add(hospital.state);
      }
      if (hospital.pincode.isNotEmpty) {
        parts.add(hospital.pincode);
      }
      return parts.join(', ');
    }
  } catch (e) {
    // If parsing fails, return original address with hospital details appended
    final parts = <String>[addressString];
    if (hospital.city.isNotEmpty) {
      parts.add(hospital.city);
    }
    if (hospital.state.isNotEmpty) {
      parts.add(hospital.state);
    }
    if (hospital.pincode.isNotEmpty) {
      parts.add(hospital.pincode);
    }
    return parts.join(', ');
  }
}

class DoctorInfo {
  final String name;
  final String specialization;
  final String qualification;
  final double rating;
  final int yearsOfExperience;
  final String? profileImage;

  DoctorInfo({
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.rating,
    required this.yearsOfExperience,
    this.profileImage,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      qualification: json['qualification'] ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      yearsOfExperience: json['years_of_experience'] ?? 0,
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'rating': rating,
      'years_of_experience': yearsOfExperience,
      'profile_image': profileImage,
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'D';
  }
}

class PatientInfo {
  final String name;
  final String gender;
  final String dateOfBirth;
  final int age;
  final bool isSelf;

  PatientInfo({
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.age,
    required this.isSelf,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      age: json['age'] ?? 0,
      isSelf: json['is_self'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'age': age,
      'is_self': isSelf,
    };
  }

  String get displayName => isSelf ? '$name (You)' : name;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'P';
  }
}

class AppointmentTimeInfo {
  final String date;
  final String time;
  final String displayDate;
  final String consultationType;

  AppointmentTimeInfo({
    required this.date,
    required this.time,
    required this.displayDate,
    required this.consultationType,
  });

  factory AppointmentTimeInfo.fromJson(Map<String, dynamic> json) {
    return AppointmentTimeInfo(
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      displayDate: json['display_date'] ?? '',
      consultationType: json['consultation_type'] ?? 'In-Clinic Consultation',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'time': time,
      'display_date': displayDate,
      'consultation_type': consultationType,
    };
  }

  String get fullDateTime => '$date | $time';
}

class ClinicInfo {
  final String name;
  final String address;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final double distanceKm;

  ClinicInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory ClinicInfo.fromJson(Map<String, dynamic> json) {
    return ClinicInfo(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      distanceKm: (json['distance_km'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distance_km': distanceKm,
    };
  }

  String get fullAddress => '$address, $city - $pincode';
}

class PaymentInfo {
  final double consultationFee;
  final double followUpFee;
  final double serviceFee;
  final double totalPayable;
  final bool isServiceFeeWaived;
  final String waiverMessage;

  PaymentInfo({
    required this.consultationFee,
    this.followUpFee = 0.0,
    required this.serviceFee,
    required this.totalPayable,
    required this.isServiceFeeWaived,
    required this.waiverMessage,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      consultationFee: (json['consultation_fee'] as num? ?? 0).toDouble(),
      followUpFee: (json['follow_up_fee'] as num? ?? 0).toDouble(),
      serviceFee: (json['service_fee'] as num? ?? 0).toDouble(),
      totalPayable: (json['total_payable'] as num? ?? 0).toDouble(),
      isServiceFeeWaived: json['is_service_fee_waived'] ?? false,
      waiverMessage:
          json['waiver_message'] ??
          'We care for you and provide a free booking',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_fee': consultationFee,
      'follow_up_fee': followUpFee,
      'service_fee': serviceFee,
      'total_payable': totalPayable,
      'is_service_fee_waived': isServiceFeeWaived,
      'waiver_message': waiverMessage,
    };
  }
}

class StatusHeader extends StatelessWidget {
  final String status;
  final String? tokenNumber;
  final String? expectedTime;
  final String? currentTokenNumber;

  const StatusHeader({
    super.key,
    required this.status,
    this.tokenNumber,
    this.expectedTime,
    this.currentTokenNumber,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: _buildContent(config, context),
        ),
        if (currentTokenNumber != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xffF8FAFF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Token Number Currently Running',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
                SizedBox(width: 14),
                SvgPicture.asset(
                  EcliniqIcons.greenDot.assetPath,
                  width: 16,
                  height: 16,
                ),
                SizedBox(width: 4),
                Text(
                  currentTokenNumber!,
                  style: EcliniqTextStyles.responsiveHeadlineLargeBold(context).copyWith(
                    color: Color(0xFF3EAF3F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildContent(_StatusConfig config, BuildContext context) {
    if (status == 'confirmed') {
      return Column(
        children: [
          Text(
            config.title,
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              color: config.textColor,
            ),
          ),
          if (tokenNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              'Your Token Number',
              style: EcliniqTextStyles.responsiveHeadlineXLMedium(context).copyWith(
                color: Color(0xff424242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tokenNumber!,
              style: EcliniqTextStyles.responsiveHeadlineXXLarge(context).copyWith(
                color: config.textColor,
              ),
            ),
            if (expectedTime != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFB8B8B8), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Expected Time - $expectedTime',
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        EcliniqIcons.info.assetPath,
                        width: 18,
                        height: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      );
    } else if (status == 'requested') {
      return Column(
        children: [
          Text(
            config.title,
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: config.textColor,
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Text(
          config.title,
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: config.textColor,
            ),
        ),
      );
    }
  }

  _StatusConfig _getStatusConfig() {
    switch (status) {
      case 'confirmed':
        return _StatusConfig(
          title: 'Booking Confirmed',
          backgroundColor: const Color(0xFFF2FFF3),
          textColor: const Color(0xFF3EAF3F),
        );
      case 'completed':
        return _StatusConfig(
          title: 'Your Appointment is Completed',
          backgroundColor: const Color(0xFFF2FFF3),
          textColor: const Color(0xFf3EAF3F),
        );
      case 'cancelled':
        return _StatusConfig(
          title: 'Your booking has been cancelled',
          backgroundColor: const Color(0xFFFFF8F8),
          textColor: const Color(0xFFF04248),
        );

      case 'failed':
        return _StatusConfig(
          title: 'Your booking has been cancelled',
          backgroundColor: const Color(0xFFFFF8F8),
          textColor: const Color(0xFFF04248),
        );
      case 'requested':
        return _StatusConfig(
          title: 'Requested',
          backgroundColor: const Color(0xFFFEF9E6),
          textColor: const Color(0xFFBE8B00),
        );
      default:
        return _StatusConfig(
          title: status,
          backgroundColor: Colors.grey[200]!,
          textColor: Colors.grey[800]!,
        );
    }
  }
}

class _StatusConfig {
  final String title;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.title,
    required this.backgroundColor,
    required this.textColor,
  });
}

class DoctorInfoCard extends StatelessWidget {
  final DoctorInfo doctor;
  final ClinicInfo clinic;
  final String? currentTokenNumber;
  final bool isSimplified; // New parameter for simplified view

  const DoctorInfoCard({
    super.key,
    required this.doctor,
    required this.clinic,
    this.currentTokenNumber,
    this.isSimplified = false, // Default to full view
  });

  // Cache colors to prevent recreation on every build
  static final Color _borderColor = const Color(0xFF1565C0).withOpacity(0.2);

  String _getExperienceText(int years) {
    return '${years}yrs of exp';
  }

  @override
  Widget build(BuildContext context) {
    if (isSimplified) {
      return _buildSimplifiedCard(context);
    }
    return _buildFullCard(  context);
  }

  Widget _buildSimplifiedCard(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: EcliniqTextStyles.getResponsiveWidth(context, 80),
              height: EcliniqTextStyles.getResponsiveHeight(context, 80),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor, width: 1),
              ),
              child:
                  doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        doctor.profileImage!,
                        width: EcliniqTextStyles.getResponsiveWidth(context, 80),
                        height: EcliniqTextStyles.getResponsiveHeight(context, 80),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              doctor.initials,
                              style: EcliniqTextStyles.responsiveHeadlineXXLargeBold(context).copyWith(
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        doctor.initials,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: SvgPicture.asset(
                EcliniqIcons.verified.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              ),
            ),
          ],
        ),
        SizedBox(
          width: EcliniqTextStyles.getResponsiveSpacing(context, 16),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                  color: Color(0xff424242),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                doctor.specialization.isEmpty
                    ? 'General Physician'
                    : doctor.specialization,
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Color(0xff424242),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                doctor.qualification,
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Color(0xff424242),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          doctor.initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SvgPicture.asset(
                        EcliniqIcons.verified.assetPath,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialization,
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.qualification,
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.medicalKit.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  _getExperienceText(doctor.yearsOfExperience),
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xff8E8E8E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffFEF9E6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.star.assetPath,
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                          color: Color(0xffBE8B00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xff8E8E8E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹500',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.hospitalBuilding.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clinic.name,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff626060),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.mapPointBlack.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    clinic.address,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff626060),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
                  ),
                  child: Text(
                    '${clinic.distanceKm.toStringAsFixed(1)} Km',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff424242),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class AppointmentDetailsSection extends StatelessWidget {
  final PatientInfo patient;
  final AppointmentTimeInfo timeInfo;
  final VoidCallback? onEditPatient;

  const AppointmentDetailsSection({
    super.key,
    required this.patient,
    required this.timeInfo,
    this.onEditPatient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          'Appointment Details',
          style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
           context:   context,
          showDivider: true,
          icon: SvgPicture.asset(
            EcliniqIcons.userBlue.assetPath,
            width: 32,
            height: 32,
          ),
          text: patient.displayName,
          subtitle:
              '${patient.gender}, ${patient.dateOfBirth} (${patient.age}Y)',
          trailing: onEditPatient != null
              ? GestureDetector(
                  onTap: onEditPatient,
                  child: SvgPicture.asset(
                    EcliniqIcons.penBlack.assetPath,
                    width: 32,
                    height: 32,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
           context:   context,
          showDivider: true,
          icon: SvgPicture.asset(
            EcliniqIcons.calendar.assetPath,
            width: 32,
            height: 32,
          ),
          text: timeInfo.time,
          subtitle: timeInfo.displayDate,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
           context:   context,
          showDivider: false,
          icon: SvgPicture.asset(
            EcliniqIcons.hospitalBuilding1.assetPath,
            width: 32,
            height: 32,
          ),
          text: timeInfo.consultationType,
          subtitle: 'Amore Clinic, 15, Indrayani River Road, Pune - 411047',
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required Widget icon,
    required String text,
    String? subtitle,
    required bool showDivider,
    required BuildContext context,
    Widget? trailing,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                            color: Color(0xFF424242),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        color: Color(0xFF8E8E8E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            const SizedBox(width: 16),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(color: Color(0xffB8B8B8), thickness: 0.5, height: 1),
        ],
      ],
    );
  }
}

class ClinicLocationCard extends StatelessWidget {
  final ClinicInfo clinic;

  const ClinicLocationCard({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xffF9F9F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Color(0xffB8B8B8)),
                    ),
                    height: 70,

                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Tap to get the clinic direction',
                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                    color: Color(0xff2372EC),
                  ),
                ),
              ),
              SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class PaymentDetailsCard extends StatelessWidget {
  final PaymentInfo payment;

  const PaymentDetailsCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentRow(
           context:   context,
          'Consultation Fee',
          payment.serviceFee > 0 ? 0.0 : payment.consultationFee,
          subtitle: payment.serviceFee > 0 ? 'Pay at Clinic' : null,
        ),
        if (payment.serviceFee > 0) ...[
          const SizedBox(height: 8),
          _buildPaymentRow('Service Fee & Tax', payment.serviceFee,  context:   context,),
        ] else ...[
          const SizedBox(height: 8),
          _buildPaymentRow(
             context:   context,
            'Service Fee & Tax',
            payment.serviceFee,
            originalAmount: payment.isServiceFeeWaived ? 40 : null,
            isFree: payment.isServiceFeeWaived,
            subtitle: payment.isServiceFeeWaived ? payment.waiverMessage : null,
          ),
        ],
        const SizedBox(height: 8),
        Divider(color: Color(0xffB8B8B8), thickness: 0.5, height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Total Payable',
                  style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                    color: const Color(0xFF424242),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  payment.serviceFee > 0
                      ? '₹${payment.serviceFee.toStringAsFixed(0)}'
                      : '₹${payment.totalPayable.toStringAsFixed(0)}',
                  style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                    color: const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    String label,
    double amount, {
    double? originalAmount,
    bool isFree = false,
    String? subtitle,
    bool isBold = false,
    required BuildContext context,  
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                    color: const Color(0xFF626060),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SvgPicture.asset(
                    EcliniqIcons.infoCircleBlack.assetPath,
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (originalAmount != null)
                  Text(
                    '₹${originalAmount.toInt()}',
                    style: EcliniqTextStyles.responsiveHeadlineXLMedium(context).copyWith(
                      color: Color(0xFF8E8E8E),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (originalAmount != null) const SizedBox(width: 8),
                Text(
                  subtitle == 'Pay at Clinic'
                      ? 'Pay at Clinic'
                      : isFree
                      ? 'Free'
                      : '₹${amount.toInt()}',
                  style: (isFree || subtitle == 'Pay at Clinic')
                      ? EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                          color: isFree
                              ? const Color(0xFF54B955)
                              : const Color(0xFF424242),
                        )
                      : EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                          color: const Color(0xFF424242),
                        ),
                ),
              ],
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: EcliniqTextStyles.responsiveBodyXSmall(context).copyWith(
              color: Color(0xFF54B955),
            ),
          ),
        ],
      ],
    );
  }
}

class RatingSection extends StatefulWidget {
  final int? initialRating;
  final Function(int)? onRatingChanged;
  final String doctorName;
  final String appointmentId;
  final bool showAsReadOnly;
  final VoidCallback? onRefetch;

  const RatingSection({
    super.key,
    this.initialRating,
    this.onRatingChanged,
    required this.doctorName,
    required this.appointmentId,
    this.showAsReadOnly = false,
    this.onRefetch,
  });

  @override
  State<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<RatingSection> {
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
  }

  Future<void> _openRatingBottomSheet() async {
    // Don't allow opening if rating already exists or is read-only
    if (widget.showAsReadOnly ||
        widget.onRatingChanged == null ||
        (_rating > 0)) {
      return;
    }

    final result = await RatingBottomSheet.show(
      context: context,
      initialRating: _rating > 0 ? _rating : null,
      doctorName: widget.doctorName,
      appointmentId: widget.appointmentId,
      onRatingSubmitted: (rating) {
        widget.onRatingChanged?.call(rating);
        setState(() {
          _rating = rating;
        });
      },
      onRefetch: widget.onRefetch,
    );

    if (result != null && result > 0) {
      setState(() {
        _rating = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRating = _rating > 0;
    final isReadOnly = widget.showAsReadOnly || hasRating;
    // Don't allow opening if rating exists
    final canOpen = !isReadOnly && (_rating == 0);

    return GestureDetector(
      onTap: canOpen ? _openRatingBottomSheet : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              hasRating ? 'Your Rating :' : 'Rate your Experience :',
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: hasRating ? Color(0xFF424242) : Color(0xFF2372EC),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SvgPicture.asset(
                      index < _rating
                          ? EcliniqIcons.starRateExp.assetPath
                          : EcliniqIcons.starRateExpUnfilled.assetPath,
                      width: 28,
                      height: 28,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppointmentApiService {
  static const String baseUrl = 'https://your-api-url.com/api/v1';

  Future<AppointmentDetailModel> fetchAppointmentDetail(
    String appointmentId,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      String status;
      String? tokenNumber;
      String? expectedTime;
      String? currentTokenNumber;

      switch (appointmentId) {
        case '1':
          status = 'confirmed';
          tokenNumber = '76';
          expectedTime = '2:30PM';
          currentTokenNumber = '67';
          break;
        case '2':
          status = 'requested';
          tokenNumber = null;
          expectedTime = null;
          currentTokenNumber = '67';
          break;
        case '3':
          status = 'cancelled';
          tokenNumber = null;
          expectedTime = null;
          currentTokenNumber = null;
          break;
        case '4':
          status = 'completed';
          tokenNumber = '45';
          expectedTime = null;
          currentTokenNumber = null;
          break;
        default:
          status = 'confirmed';
          tokenNumber = '76';
          expectedTime = '2:30PM';
          currentTokenNumber = '67';
      }

      final mockJson = {
        'id': appointmentId,
        'status': status,
        'token_number': tokenNumber,
        'expected_time': expectedTime,
        'current_token_number': currentTokenNumber,
        'doctor': {
          'name': 'Dr. Milind Chauhan',
          'specialization': 'General Physician',
          'qualification': 'MBBS, MD - General Medicine',
          'rating': 4.0,
          'years_of_experience': 27,
        },
        'patient': {
          'name': 'Ketan Patni',
          'gender': 'Male',
          'date_of_birth': '02/02/1996',
          'age': 29,
          'is_self': true,
        },
        'time_info': {
          'date': '2025-03-02',
          'time': '10:00am - 12:00pm',
          'display_date': 'Today, 2 March 2025',
          'consultation_type': 'In-Clinic Consultation',
        },
        'clinic': {
          'name': 'Sunrise Family Clinic',
          'address': 'Amore Clinic, 15, Indrayani River Road, Pune',
          'city': 'Pune',
          'pincode': '411047',
          'latitude': 18.5204,
          'longitude': 73.8567,
          'distance_km': 4.0,
        },
        'payment': {
          'consultation_fee': 700,
          'service_fee': 0.0,
          'total_payable': 700.0,
          'is_service_fee_waived': true,
          'waiver_message': 'We care for you and provide a free booking',
        },
        'rating': null,
      };

      return AppointmentDetailModel.fromJson(mockJson);
    } catch (e) {
      throw Exception('Failed to fetch appointment details: $e');
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  Future<bool> rescheduleAppointment(
    String appointmentId,
    String newDate,
    String newTime,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  Future<bool> submitRating(String appointmentId, int rating) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  Future<bool> requestCallback(String appointmentId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      throw Exception('Failed to request callback: $e');
    }
  }
}

enum BookingButtonType { reschedule, cancel, primary, outlined }

class BookingActionButton extends StatefulWidget {
  final String label;
  final EcliniqIcons? icon;
  final BookingButtonType type;
  final VoidCallback? onPressed;
  final bool isFullWidth;

  const BookingActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.type,
    this.onPressed,
    this.isFullWidth = true,
  });

  @override
  State<BookingActionButton> createState() => _BookingActionButtonState();
}

class _BookingActionButtonState extends State<BookingActionButton> {
  bool _isPressed = false;

  Color _getBackgroundColor() {
    if (_isPressed) {
      switch (widget.type) {
        case BookingButtonType.reschedule:
          return const Color(0xFF2372EC);
        case BookingButtonType.cancel:
          return const Color(0xFFB71C1C);
        case BookingButtonType.primary:
          return const Color(0xFF0E4395);
        case BookingButtonType.outlined:
          return const Color(0xFF2372EC);
      }
    } else {
      switch (widget.type) {
        case BookingButtonType.reschedule:
          return const Color(0xFFF2F7FF);
        case BookingButtonType.cancel:
          return const Color(0xFFFFF8F8);
        case BookingButtonType.primary:
          return const Color(0xFF2372EC);
        case BookingButtonType.outlined:
          return Colors.transparent;
      }
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case BookingButtonType.reschedule:
        return const Color(0xFF96BFFF);
      case BookingButtonType.cancel:
        return const Color(0xFFEB8B85);
      case BookingButtonType.primary:
        return const Color(0xFF2372EC);
      case BookingButtonType.outlined:
        return const Color(0xFF2372EC);
    }
  }

  Color _getTextColor() {
    if (_isPressed) {
      return Colors.white;
    } else {
      switch (widget.type) {
        case BookingButtonType.reschedule:
          return const Color(0xff2372EC);
        case BookingButtonType.cancel:
          return const Color(0xffF04248);
        case BookingButtonType.primary:
          return Colors.white;
        case BookingButtonType.outlined:
          return const Color(0xFF2372EC);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: 52,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _isPressed = false;
          });
        },
        onTap: widget.onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _getBorderColor(), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                SvgPicture.asset(
                  widget.icon!.assetPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    _getTextColor(),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
