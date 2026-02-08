import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/eta_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
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

  factory AppointmentDetailModel.fromApiData(AppointmentDetailData apiData) {
    String status = apiData.status.toLowerCase();
    if (status == 'served') {
      status = 'completed';
    } else if (status == 'pending' || status == 'engaged') {
      status = 'requested';
    } else if (status == 'checked_in') {
      status = 'confirmed';
    }

    final appointmentDate = apiData.schedule.date;
    final startTime = apiData.schedule.startTime;

    final combinedDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      startTime.hour,
      startTime.minute,
    );

    final dateFormat = DateFormat('dd MMM, yyyy');
    final dateStr = dateFormat.format(appointmentDate);

    final timeFormat = DateFormat('h:mma');
    final startTimeStr = timeFormat.format(combinedDateTime).toLowerCase();
    final endTime = apiData.schedule.endTime;
    final combinedEndDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      endTime.hour,
      endTime.minute,
    );
    final endTimeStr = timeFormat.format(combinedEndDateTime).toLowerCase();
    final timeStr = '$startTimeStr - $endTimeStr';

    final now = DateTime.now();

    // Calculate display date with relative day prefix
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    final difference = appointmentDay.difference(today).inDays;

    String dayPrefix;
    if (difference == 0) {
      dayPrefix = 'Today';
    } else if (difference == 1) {
      dayPrefix = 'Tomorrow';
    } else if (difference == -1) {
      dayPrefix = 'Yesterday';
    } else {
      dayPrefix = DateFormat('EEEE').format(appointmentDate);
    }

    final displayDateFormat = DateFormat('dd MMM, yyyy');
    final formattedDisplayDate =
        '$dayPrefix, ${displayDateFormat.format(appointmentDate)}';

    final dob = apiData.patient.dob;
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    final location = apiData.location;
    final clinicName = location.name;

    String formattedAddress = '';
    String city = '';
    String state = '';
    String pincode = '';
    double latitude = 0.0;
    double longitude = 0.0;

    if (location.type == 'CLINIC' && apiData.doctor.primaryClinic != null) {
      final primaryClinic = apiData.doctor.primaryClinic!;

      formattedAddress = primaryClinic.address.isNotEmpty
          ? primaryClinic.address
          : location.address;

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
      state = hospital.state;
      pincode = hospital.pincode;
      latitude = hospital.latitude;
      longitude = hospital.longitude;

      formattedAddress = _parseHospitalAddress(location.address, hospital);
    } else {
      formattedAddress = location.address;
    }

    String consultationType = apiData.type == 'ONLINE'
        ? 'In-Clinic Consultation'
        : 'In-Clinic Consultation';

    final consultationFee =
        apiData.consultationFee ?? apiData.doctor.consultationFee ?? 0.0;
    final followUpFee =
        apiData.followUpFee ?? apiData.doctor.followUpFee ?? 0.0;
    final serviceFee = 0.0;
    final totalPayable = consultationFee + serviceFee;

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
      expectedTime: null,
      currentTokenNumber: null,
      doctor: DoctorInfo(
        name: apiData.doctor.name,
        specialization: apiData.doctor.specialties.isNotEmpty
            ? apiData.doctor.specialties.join(', ')
            : 'General Physician',
        qualification: apiData.doctor.degrees.isNotEmpty
            ? apiData.doctor.degrees.join(', ')
            : 'MBBS',
        rating: 0.0,
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
        displayDate: formattedDisplayDate,
        consultationType: consultationType,
      ),
      clinic: ClinicInfo(
        name: clinicName,
        address: formattedAddress,
        city: city,
        state: state,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        distanceKm: 0.0,
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

String _parseHospitalAddress(
  String addressString,
  AssociatedHospital hospital,
) {
  try {
    if (addressString.trim().startsWith('{')) {
      final addressJson = jsonDecode(addressString) as Map<String, dynamic>;
      final parts = <String>[];

      if (addressJson['street'] != null &&
          addressJson['street'].toString().isNotEmpty) {
        parts.add(addressJson['street'].toString());
      }

      if (addressJson['blockNo'] != null &&
          addressJson['blockNo'].toString().isNotEmpty) {
        parts.add(addressJson['blockNo'].toString());
      }

      if (hospital.city.isNotEmpty) {
        parts.add(hospital.city);
      }
      if (hospital.state.isNotEmpty) {
        parts.add(hospital.state);
      }

      if (addressJson['landmark'] != null &&
          addressJson['landmark'].toString().isNotEmpty) {
        parts.add('Near ${addressJson['landmark']}');
      }

      if (hospital.pincode.isNotEmpty) {
        parts.add(hospital.pincode);
      }

      return parts.isEmpty ? addressString : parts.join(', ');
    } else {
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

  String get displayName => name;

  Widget displayNameWidget(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: EcliniqTextStyles.responsiveHeadlineMedium(
            context,
          ).copyWith(color: const Color(0xFF424242)),
          overflow: TextOverflow.ellipsis,
        ),
        if (isSelf) ...[
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
          Container(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 4.0,
              vertical: 2.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 6.0),
              ),
            ),
            child: Text(
              'You',
              style: EcliniqTextStyles.responsiveHeadlineXMedium(
                context,
              ).copyWith(color: Color(0xff2372EC), fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ],
    );
  }

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
    final dateStr = json['date'] ?? '';
    String displayDate = json['display_date'] ?? '';

    // Always compute displayDate from date to ensure proper format with year
    if (dateStr.isNotEmpty) {
      try {
        final dateFormat = DateFormat('dd MMM, yyyy');
        final parsedDate = dateFormat.parse(dateStr);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final appointmentDay = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
        );
        final difference = appointmentDay.difference(today).inDays;

        String dayPrefix;
        if (difference == 0) {
          dayPrefix = 'Today';
        } else if (difference == 1) {
          dayPrefix = 'Tomorrow';
        } else if (difference == -1) {
          dayPrefix = 'Yesterday';
        } else {
          dayPrefix = DateFormat('EEEE').format(parsedDate);
        }

        final displayDateFormat = DateFormat('dd MMM, yyyy');
        displayDate = '$dayPrefix, ${displayDateFormat.format(parsedDate)}';
      } catch (e) {
        if (displayDate.isEmpty) {
          displayDate = dateStr;
        }
      }
    }

    return AppointmentTimeInfo(
      date: dateStr,
      time: json['time'] ?? '',
      displayDate: displayDate,
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
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double distanceKm;

  ClinicInfo({
    required this.name,
    required this.address,
    required this.city,
    this.state = '',
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
      state: json['state'] ?? '',
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
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distance_km': distanceKm,
    };
  }

  String get fullAddress => '$address, $city - $pincode';

  String get cityState {
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    return parts.isNotEmpty ? parts.join(', ') : 'Location not available';
  }
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
  final String? displayDate;

  const StatusHeader({
    super.key,
    required this.status,
    this.tokenNumber,
    this.expectedTime,
    this.currentTokenNumber,
    this.displayDate,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 12.0,
            vertical: 12.0,
          ),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
              ),
              topRight: Radius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
              ),
            ),
          ),
          child: _buildContent(config, context),
        ),
        if (currentTokenNumber != null) ...[
          Container(
            width: double.infinity,
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 14.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Color(0xffF8FAFF),
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 6.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Token Number Currently Running',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context)
                      .copyWith(
                        color: Color(0xff626060),
                        fontWeight: FontWeight.w400,
                      ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 14.0),
                ),
                _AnimatedDot(),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
                ),
                Text(
                  currentTokenNumber!,
                  style: EcliniqTextStyles.responsiveHeadlineLargeBold(context)
                      .copyWith(
                        color: Color(0xFF3EAF3F),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
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
            style: EcliniqTextStyles.responsiveHeadlineBMedium(
              context,
            ).copyWith(color: config.textColor),
          ),
          if (tokenNumber != null) ...[
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            Text(
              'Your Token Number',
              style: EcliniqTextStyles.responsiveHeadlineXLMedium(
                context,
              ).copyWith(color: Color(0xff424242)),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            Text(
              tokenNumber!,
              style: EcliniqTextStyles.responsiveHeadlineXXLarge(
                context,
              ).copyWith(color: config.textColor, fontWeight: FontWeight.w700),
            ),
            if (expectedTime != null && expectedTime!.isNotEmpty) ...[
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
              ),
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                  context,
                  6.0,
                ),
                child: Container(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                    context,
                    4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 6.0),
                    ),
                    border: Border.all(
                      color: const Color(0xFFB8B8B8),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Expected Time - $expectedTime',
                        style: EcliniqTextStyles.responsiveTitleXLarge(
                          context,
                        ).copyWith(color: const Color(0xff424242)),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          6.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          EcliniqBottomSheet.show(
                            child: EtaBottomSheet(),
                            context: context,
                          );
                        },
                        child: SvgPicture.asset(
                          EcliniqIcons.infoCircleBlack.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            18.0,
                          ),
                          height: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            18.0,
                          ),
                        ),
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
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: config.textColor),
          ),
        ],
      );
    } else if (status == 'cancelled' || status == 'failed') {
      return Column(
        children: [
          Text(
            config.title,
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: config.textColor),
          ),
          if (displayDate != null && displayDate!.isNotEmpty) ...[
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
            ),
            Text(
              displayDate!,
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                color: const Color(0xff8E8E8E),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      );
    } else {
      return Center(
        child: Text(
          config.title,
          style: EcliniqTextStyles.responsiveHeadlineMedium(
            context,
          ).copyWith(color: config.textColor),
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
  final bool isSimplified;

  const DoctorInfoCard({
    super.key,
    required this.doctor,
    required this.clinic,
    this.currentTokenNumber,
    this.isSimplified = false,
  });

  static final Color _borderColor = const Color(0xFF1565C0).withOpacity(0.2);

  String _getExperienceText(int years) {
    return '${years}yrs of exp';
  }

  @override
  Widget build(BuildContext context) {
    if (isSimplified) {
      return _buildSimplifiedCard(context);
    }
    return _buildFullCard(context);
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
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          80,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          80,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              doctor.initials,
                              style:
                                  EcliniqTextStyles.responsiveHeadlineXXLargeBold(
                                    context,
                                  ).copyWith(color: Color(0xFF1565C0)),
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
        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: EcliniqTextStyles.responsiveHeadlineLarge(
                  context,
                ).copyWith(color: Color(0xff424242)),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
              ),
              Text(
                doctor.specialization.isEmpty
                    ? 'General Physician'
                    : doctor.specialization,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Color(0xff424242)),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
              ),
              Text(
                doctor.qualification,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Color(0xff424242)),
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
                      width: EcliniqTextStyles.getResponsiveSize(context, 80.0),
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        80.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          doctor.initials,
                          style:
                              EcliniqTextStyles.responsiveHeadlineXXLargeBold(
                                context,
                              ).copyWith(color: Color(0xFF1565C0)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SvgPicture.asset(
                        EcliniqIcons.verified.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24.0,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: EcliniqTextStyles.responsiveHeadlineLarge(
                          context,
                        ).copyWith(color: Color(0xff424242)),
                      ),
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          4.0,
                        ),
                      ),
                      Text(
                        doctor.specialization,
                        style: EcliniqTextStyles.responsiveTitleXLarge(
                          context,
                        ).copyWith(color: Color(0xff424242)),
                      ),
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          2.0,
                        ),
                      ),
                      Text(
                        doctor.qualification,
                        style: EcliniqTextStyles.responsiveTitleXLarge(
                          context,
                        ).copyWith(color: Color(0xff424242)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            ),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.medicalKit.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                  height: EcliniqTextStyles.getResponsiveIconSize(
                    context,
                    24.0,
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
                ),
                Text(
                  _getExperienceText(doctor.yearsOfExperience),
                  style: EcliniqTextStyles.responsiveTitleXLarge(
                    context,
                  ).copyWith(color: Color(0xff626060)),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Container(
                  width: EcliniqTextStyles.getResponsiveSize(context, 6.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 6.0),
                  decoration: const BoxDecoration(
                    color: Color(0xff8E8E8E),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Container(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                    context,
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffFEF9E6),
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.star.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          18.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          18.0,
                        ),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          2.0,
                        ),
                      ),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: EcliniqTextStyles.responsiveTitleXBLarge(
                          context,
                        ).copyWith(color: Color(0xffBE8B00)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Container(
                  width: EcliniqTextStyles.getResponsiveSize(context, 6.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 6.0),
                  decoration: const BoxDecoration(
                    color: Color(0xff8E8E8E),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Text(
                  '₹500',
                  style: EcliniqTextStyles.responsiveTitleXLarge(
                    context,
                  ).copyWith(color: Color(0xff626060)),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
                    style: EcliniqTextStyles.responsiveTitleXLarge(
                      context,
                    ).copyWith(color: Color(0xff626060)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.mapPointBlack.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clinic.cityState,
                    style: EcliniqTextStyles.responsiveTitleXLarge(
                      context,
                    ).copyWith(color: Color(0xff626060)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (clinic.distanceKm > 0) ...[
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
                      style: EcliniqTextStyles.responsiveTitleXLarge(
                        context,
                      ).copyWith(color: Color(0xff424242)),
                    ),
                  ),
                ],
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
          style: EcliniqTextStyles.responsiveHeadlineLarge(
            context,
          ).copyWith(color: Color(0xFF333333)),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context: context,
          showDivider: true,
          icon: SvgPicture.asset(
            EcliniqIcons.userBlue.assetPath,
            width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
          ),
          text: patient.displayName,
          textWidget: patient.displayNameWidget(context),
          subtitle:
              '${patient.gender}, ${patient.dateOfBirth} (${patient.age}Y)',
          trailing: onEditPatient != null
              ? GestureDetector(
                  onTap: onEditPatient,
                  child: SvgPicture.asset(
                    EcliniqIcons.penBlack.assetPath,
                    width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
                    height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          context: context,
          showDivider: true,
          icon: SvgPicture.asset(
            EcliniqIcons.calendar.assetPath,
            width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
          ),
          text: timeInfo.time,
          subtitle: timeInfo.displayDate.isNotEmpty
              ? timeInfo.displayDate
              : timeInfo.date,
        ),
        const SizedBox(height: 10),
        _buildDetailRow(
          context: context,
          showDivider: false,
          icon: SvgPicture.asset(
            EcliniqIcons.hospitalBuilding1.assetPath,
            width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
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
    Widget? textWidget,
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
                        child:
                            textWidget ??
                            Text(
                              text,
                              style: EcliniqTextStyles.responsiveHeadlineMedium(
                                context,
                              ).copyWith(color: Color(0xFF424242)),
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle
                          .toLowerCase()
                          .split(' ')
                          .map(
                            (word) => word.isNotEmpty
                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                : '',
                          )
                          .join(' '),
                      style: EcliniqTextStyles.responsiveTitleXLarge(
                        context,
                      ).copyWith(color: Color(0xFF8E8E8E)),
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
          const SizedBox(height: 10),
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
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveSize(context, 12.0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 12.0,
                  bottom: 12.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveSize(context, 8.0),
                  ),
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
                  style: EcliniqTextStyles.responsiveBodySmall(
                    context,
                  ).copyWith(color: Color(0xff2372EC)),
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
          style: EcliniqTextStyles.responsiveHeadlineLarge(
            context,
          ).copyWith(color: Color(0xFF424242)),
        ),
        const SizedBox(height: 16),
        _buildPaymentRow(
          context: context,
          'Consultation Fee',
          payment.serviceFee > 0 ? 0.0 : payment.consultationFee,
          subtitle: payment.serviceFee > 0 ? 'Pay at Clinic' : null,
        ),
        if (payment.serviceFee > 0) ...[
          const SizedBox(height: 8),
          _buildPaymentRow(
            'Service Fee & Tax',
            payment.serviceFee,
            context: context,
          ),
        ] else ...[
          const SizedBox(height: 8),
          _buildPaymentRow(
            context: context,
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
                  style: EcliniqTextStyles.responsiveHeadlineLarge(
                    context,
                  ).copyWith(color: const Color(0xFF424242)),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  payment.serviceFee > 0
                      ? '₹${payment.serviceFee.toStringAsFixed(0)}'
                      : '₹${payment.totalPayable.toStringAsFixed(0)}',
                  style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                      .copyWith(
                        color: const Color(0xFF424242),
                        fontWeight: FontWeight.w600,
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
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(
                    context,
                  ).copyWith(color: const Color(0xFF626060)),
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
                    style: EcliniqTextStyles.responsiveHeadlineXLMedium(context)
                        .copyWith(
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
                      ? EcliniqTextStyles.responsiveHeadlineMedium(
                          context,
                        ).copyWith(
                          color: isFree
                              ? const Color(0xFF54B955)
                              : const Color(0xFF424242),
                        )
                      : EcliniqTextStyles.responsiveHeadlineXMedium(
                          context,
                        ).copyWith(color: const Color(0xFF424242)),
                ),
              ],
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: EcliniqTextStyles.responsiveBodyXSmall(
              context,
            ).copyWith(color: Color(0xFF54B955)),
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
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                  .copyWith(
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
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
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
                style: EcliniqTextStyles.responsiveHeadlineMedium(
                  context,
                ).copyWith(color: _getTextColor()),
              ),
            ],
          ),
        ),
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
