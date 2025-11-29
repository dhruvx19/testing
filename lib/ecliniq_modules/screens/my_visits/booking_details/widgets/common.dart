import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
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
      isRescheduled: json['is_rescheduled'] == null ? null : (json['is_rescheduled'] == true || json['is_rescheduled'] == 'true' || json['is_rescheduled'] == 1),
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
    final consultationFee = apiData.consultationFee ?? apiData.doctor.consultationFee ?? 0.0;
    final followUpFee = apiData.followUpFee ?? apiData.doctor.followUpFee ?? 0.0;
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
      rating: null, // Not available in API response
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
      rating: (json['rating'] ?? 0).toDouble(),
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
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
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
      consultationFee: (json['consultation_fee'] ?? 0).toDouble(),
      followUpFee: (json['follow_up_fee'] ?? 0).toDouble(),
      serviceFee: (json['service_fee'] ?? 0).toDouble(),
      totalPayable: (json['total_payable'] ?? 0).toDouble(),
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
          child: _buildContent(config),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

  Widget _buildContent(_StatusConfig config) {
    if (status == 'confirmed') {
      return Column(
        children: [
          Text(
            config.title,
            style: EcliniqTextStyles.headlineBMedium.copyWith(
              color: config.textColor,
            ),
          ),
          if (tokenNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              'Your Token Number',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Color(0xff424242),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tokenNumber!,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Text(
          config.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
          backgroundColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFF04248),
        );
      case 'cancelled':
        return _StatusConfig(
          title: 'Your booking has been cancelled',
          backgroundColor: const Color(0xFFFFEBEE),
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
      return _buildSimplifiedCard();
    }
    return _buildFullCard();
  }

  Widget _buildSimplifiedCard() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Row(
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
                child: doctor.profileImage != null && doctor.profileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          doctor.profileImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                doctor.initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
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
                  style: EcliniqTextStyles.headlineLarge.copyWith(
                    color: Color(0xff424242),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialization.isEmpty ? 'General Physician' : doctor.specialization,
                  style: EcliniqTextStyles.titleXLarge.copyWith(
                    color: Color(0xff424242),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.qualification,
                  style: EcliniqTextStyles.titleXLarge.copyWith(
                    color: Color(0xff424242),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
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
                          style: EcliniqTextStyles.headlineLarge.copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialization,
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doctor.qualification,
                          style: EcliniqTextStyles.titleXLarge.copyWith(
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
                    style: EcliniqTextStyles.titleXLarge.copyWith(
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xffBE8B00),
                            fontWeight: FontWeight.w600,
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
                    style: EcliniqTextStyles.titleXLarge.copyWith(
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
                      style: EcliniqTextStyles.titleXLarge.copyWith(
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
                    EcliniqIcons.mapPoint.assetPath,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clinic.address,
                      style: EcliniqTextStyles.titleXLarge.copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xffB8B8B8)),
                    ),
                    child: Text(
                      '${clinic.distanceKm.toStringAsFixed(1)} Km',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppointmentDetailsSection extends StatelessWidget {
  final PatientInfo patient;
  final AppointmentTimeInfo timeInfo;

  const AppointmentDetailsSection({
    super.key,
    required this.patient,
    required this.timeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          icon: SvgPicture.asset(
            EcliniqIcons.user.assetPath,
            width: 32,
            height: 32,
          ),
          text: patient.displayName,
          subtitle:
              '${patient.gender}, ${patient.dateOfBirth} (${patient.age}Y)',
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
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
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
              ],
              Divider(color: Colors.grey[300]),
            ],
          ),
        ),
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
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Color(0xffF9F9F9),
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 70,
                    color: Colors.grey[200],
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
                  style: EcliniqTextStyles.bodySmall.copyWith(
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
        const Text(
          'Payment Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentRow('Consultation Fee', payment.consultationFee),
        const SizedBox(height: 12),
        _buildPaymentRow(
          'Service Fee & Tax',
          payment.serviceFee,
          originalAmount: payment.isServiceFeeWaived ? 40 : null,
          isFree: payment.isServiceFeeWaived,
          subtitle: payment.isServiceFeeWaived ? payment.waiverMessage : null,
        ),
        const Divider(height: 24),
        _buildPaymentRow('Total Payable', payment.totalPayable, isBold: true),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF626060),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (originalAmount != null)
                  Text(
                    '₹${originalAmount.toInt()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (originalAmount != null) const SizedBox(width: 8),
                Text(
                  isFree ? 'Free' : '₹${amount.toInt()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                    color: isFree
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF333333),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
          ),
        ],
      ],
    );
  }
}

class RatingSection extends StatefulWidget {
  final int? initialRating;
  final Function(int) onRatingChanged;
  final String doctorName;
  final String appointmentId;

  const RatingSection({
    super.key,
    this.initialRating,
    required this.onRatingChanged,
    required this.doctorName,
    required this.appointmentId,
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
    int tempRating = _rating;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate your Experience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.doctorName,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final filled = index < tempRating;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 40,
                            color: filled ? Colors.amber : const Color(0xFFE0E0E0),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (tempRating > 0) {
                          widget.onRatingChanged(tempRating);
                          setState(() {
                            _rating = tempRating;
                          });
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2372EC),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openRatingBottomSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate your Experience :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: index < _rating
                        ? Colors.amber
                        : const Color(0xFFE0E0E0),
                  ),
                );
              }),
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
            borderRadius: BorderRadius.circular(8),
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
                style: EcliniqTextStyles.headlineMedium.copyWith(
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
