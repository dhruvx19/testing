class BookAppointmentRequest {
  final String patientId;
  final String doctorId;
  final String doctorSlotScheduleId;
  final String? reason;
  final String? referBy;
  final String bookedFor;
  final String bookingType;
  final String? dependentId;
  final bool useWallet;

  BookAppointmentRequest({
    required this.patientId,
    required this.doctorId,
    required this.doctorSlotScheduleId,
    this.reason,
    this.referBy,
    required this.bookedFor,
    this.bookingType = 'NEW',
    this.dependentId,
    this.useWallet = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorSlotScheduleId': doctorSlotScheduleId,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      if (referBy != null && referBy!.isNotEmpty) 'referBy': referBy,
      'bookingType': bookingType,
      'bookedFor': bookedFor,
      if (dependentId != null && dependentId!.isNotEmpty)
        'dependentId': dependentId,
      'useWallet': useWallet,
    };
  }
}

class AppointmentData {
  final String id;
  final String patientId;
  final String? dependentId;
  final String bookedFor;
  final String doctorId;
  final String doctorSlotScheduleId;
  final int tokenNo;
  final String? reason;
  final String status;
  final String? referBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentData({
    required this.id,
    required this.patientId,
    this.dependentId,
    required this.bookedFor,
    required this.doctorId,
    required this.doctorSlotScheduleId,
    required this.tokenNo,
    this.reason,
    required this.status,
    this.referBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to string
    toString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      return value.toString();
    }

    // Helper to safely convert to int
    toInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Helper to safely parse DateTime
    parseDateTime(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return defaultValue;
      }
    }

    final defaultDate = DateTime.utc(1970, 1, 1);

    return AppointmentData(
      id: toString(json['appointmentId'] ?? json['id'], ''),
      patientId: toString(json['patientId'], ''),
      dependentId: json['dependentId'] != null
          ? toString(json['dependentId'], '')
          : null,
      bookedFor: toString(json['bookedFor'], ''),
      doctorId: toString(json['doctorId'], ''),
      doctorSlotScheduleId: toString(json['doctorSlotScheduleId'], ''),
      tokenNo: toInt(json['tokenNo'], 0),
      reason: json['reason'] != null ? toString(json['reason'], '') : null,
      status: toString(json['status'], ''),
      referBy: json['referBy'] != null ? toString(json['referBy'], '') : null,
      createdAt: parseDateTime(json['createdAt'], defaultDate),
      updatedAt: parseDateTime(json['updatedAt'], defaultDate),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      if (dependentId != null) 'dependentId': dependentId,
      'bookedFor': bookedFor,
      'doctorId': doctorId,
      'doctorSlotScheduleId': doctorSlotScheduleId,
      'tokenNo': tokenNo,
      if (reason != null) 'reason': reason,
      'status': status,
      if (referBy != null) 'referBy': referBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BookAppointmentResponse {
  final bool success;
  final String message;
  final dynamic
  data; // Changed from AppointmentData? to dynamic to support both AppointmentData and payment data
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  BookAppointmentResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory BookAppointmentResponse.fromJson(Map<String, dynamic> json) {
    // Keep data as raw Map if it contains payment fields, otherwise parse as AppointmentData
    dynamic parsedData;
    if (json['data'] != null) {
      final dataMap = json['data'] as Map<String, dynamic>;

      // Debug: Log the data structure

      // Check if response contains payment-related fields
      // Backend returns: { appointmentId, status, paymentRequired, payment: {...} }
      if (dataMap.containsKey('paymentRequired') ||
          dataMap.containsKey('payment') ||
          dataMap.containsKey('merchantTransactionId')) {
        // Keep as Map for payment data - this structure has paymentRequired and payment object
        parsedData = dataMap;
      } else {
        // Parse as AppointmentData for regular booking response (free appointments or wallet-only)
        try {
          parsedData = AppointmentData.fromJson(dataMap);
        } catch (e) {
          // If parsing fails, keep as Map
          parsedData = dataMap;
        }
      }
    }

    return BookAppointmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: parsedData,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data is AppointmentData
          ? (data as AppointmentData).toJson()
          : data,
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class AppointmentTime {
  final DateTime startTime;
  final DateTime endTime;

  AppointmentTime({required this.startTime, required this.endTime});

  factory AppointmentTime.fromJson(Map<String, dynamic> json) {
    parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return AppointmentTime(
      startTime: parseDateTime(json['startTime']),
      endTime: parseDateTime(json['endTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}

class AppointmentListItem {
  final String appointmentId;
  final String status;
  final String doctorName;
  final String? doctorPhoto;
  final List<String> speciality;
  final List<String> degrees;
  final DateTime appointmentDate;
  final AppointmentTime appointmentTime;
  final int? tokenNo;
  final String patientName;
  final String bookedFor;
  final int? rating;

  AppointmentListItem({
    required this.appointmentId,
    required this.status,
    required this.doctorName,
    this.doctorPhoto,
    required this.speciality,
    required this.degrees,
    required this.appointmentDate,
    required this.appointmentTime,
    this.tokenNo,
    required this.patientName,
    required this.bookedFor,
    this.rating,
  });

  factory AppointmentListItem.fromJson(Map<String, dynamic> json) {
    parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    toStringList(dynamic value) {
      if (value == null) return <String>[];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return <String>[];
    }

    toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return AppointmentListItem(
      appointmentId: json['appointmentId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      doctorName: json['doctorName']?.toString() ?? '',
      doctorPhoto: json['doctorPhoto']?.toString(),
      speciality: toStringList(json['speciality']),
      degrees: toStringList(json['degrees']),
      appointmentDate: parseDateTime(json['appointmentDate']),
      appointmentTime: AppointmentTime.fromJson(json['appointmentTime'] ?? {}),
      tokenNo: toInt(json['tokenNo']),
      patientName: json['patientName']?.toString() ?? '',
      bookedFor: json['bookedFor']?.toString() ?? '',
      rating: toInt(json['rating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'status': status,
      'doctorName': doctorName,
      if (doctorPhoto != null) 'doctorPhoto': doctorPhoto,
      'speciality': speciality,
      'degrees': degrees,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime.toJson(),
      if (tokenNo != null) 'tokenNo': tokenNo,
      'patientName': patientName,
      'bookedFor': bookedFor,
      if (rating != null) 'rating': rating,
    };
  }
}

class AppointmentListResponse {
  final bool success;
  final String message;
  final List<AppointmentListItem> data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  AppointmentListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory AppointmentListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return AppointmentListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: dataList
          .map(
            (item) =>
                AppointmentListItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

// Appointment Detail Models
class AppointmentDetailResponse {
  final bool success;
  final String message;
  final AppointmentDetailData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  AppointmentDetailResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory AppointmentDetailResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentDetailResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AppointmentDetailData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class AppointmentDetailData {
  final String appointmentId;
  final String status;
  final int? tokenNo;
  final String bookedFor;
  final String bookingType;
  final String type;
  final bool isRescheduled;
  final DoctorDetail doctor;
  final PatientDetail patient;
  final ScheduleDetail schedule;
  final LocationDetail location;
  final String? reason;
  final String paymentStatus;
  final double? consultationFee;
  final double? followUpFee;
  final int? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentDetailData({
    required this.appointmentId,
    required this.status,
    this.tokenNo,
    required this.bookedFor,
    required this.bookingType,
    required this.type,
    required this.isRescheduled,
    required this.doctor,
    required this.patient,
    required this.schedule,
    required this.location,
    this.reason,
    required this.paymentStatus,
    this.consultationFee,
    this.followUpFee,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentDetailData.fromJson(Map<String, dynamic> json) {
    parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    toBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is int) return value != 0;
      return false;
    }

    return AppointmentDetailData(
      appointmentId: json['appointmentId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      tokenNo: toInt(json['tokenNo']),
      bookedFor: json['bookedFor']?.toString() ?? '',
      bookingType: json['bookingType']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isRescheduled: toBool(json['isRescheduled']),
      doctor: DoctorDetail.fromJson(
        json['doctor'] as Map<String, dynamic>? ?? {},
      ),
      patient: PatientDetail.fromJson(
        json['patient'] as Map<String, dynamic>? ?? {},
      ),
      schedule: ScheduleDetail.fromJson(
        json['schedule'] as Map<String, dynamic>? ?? {},
      ),
      location: LocationDetail.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      reason: json['reason']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      consultationFee: toDouble(json['consultationFee']),
      followUpFee: toDouble(json['followUpFee']),
      rating: toInt(json['rating']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'status': status,
      if (tokenNo != null) 'tokenNo': tokenNo,
      'bookedFor': bookedFor,
      'bookingType': bookingType,
      'type': type,
      'isRescheduled': isRescheduled,
      'doctor': doctor.toJson(),
      'patient': patient.toJson(),
      'schedule': schedule.toJson(),
      'location': location.toJson(),
      if (reason != null) 'reason': reason,
      'paymentStatus': paymentStatus,
      if (consultationFee != null) 'consultationFee': consultationFee,
      if (followUpFee != null) 'followUpFee': followUpFee,
      if (rating != null) 'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class DoctorDetail {
  final String userId;
  final String name;
  final String? profilePhoto;
  final List<String> specialties;
  final List<String> degrees;
  final double? consultationFee;
  final double? followUpFee;
  final int? workExperience;
  final PrimaryClinic? primaryClinic;
  final List<AssociatedHospital> associatedHospitals;

  DoctorDetail({
    required this.userId,
    required this.name,
    this.profilePhoto,
    required this.specialties,
    required this.degrees,
    this.consultationFee,
    this.followUpFee,
    this.workExperience,
    this.primaryClinic,
    required this.associatedHospitals,
  });

  factory DoctorDetail.fromJson(Map<String, dynamic> json) {
    toStringList(dynamic value) {
      if (value == null) return <String>[];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return <String>[];
    }

    toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    return DoctorDetail(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profilePhoto: json['profilePhoto']?.toString(),
      specialties: toStringList(json['specialties']),
      degrees: toStringList(json['degrees']),
      consultationFee: toDouble(json['consultationFee']),
      followUpFee: toDouble(json['followUpFee']),
      workExperience: toInt(json['workExperience']),
      primaryClinic: json['primaryClinic'] != null
          ? PrimaryClinic.fromJson(
              json['primaryClinic'] as Map<String, dynamic>,
            )
          : null,
      associatedHospitals: json['associatedHospitals'] != null
          ? (json['associatedHospitals'] as List)
                .map(
                  (e) => AssociatedHospital.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      'specialties': specialties,
      'degrees': degrees,
      if (consultationFee != null) 'consultationFee': consultationFee,
      if (followUpFee != null) 'followUpFee': followUpFee,
      if (workExperience != null) 'workExperience': workExperience,
      if (primaryClinic != null) 'primaryClinic': primaryClinic!.toJson(),
      'associatedHospitals': associatedHospitals
          .map((e) => e.toJson())
          .toList(),
    };
  }
}

class PrimaryClinic {
  final String id;
  final String name;
  final String address;
  final String latitude;
  final String longitude;

  PrimaryClinic({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory PrimaryClinic.fromJson(Map<String, dynamic> json) {
    return PrimaryClinic(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AssociatedHospital {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;

  AssociatedHospital({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  factory AssociatedHospital.fromJson(Map<String, dynamic> json) {
    toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return AssociatedHospital(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class PatientDetail {
  final String name;
  final String phone;
  final String? emailId;
  final String gender;
  final DateTime dob;
  final String? bloodGroup;

  PatientDetail({
    required this.name,
    required this.phone,
    this.emailId,
    required this.gender,
    required this.dob,
    this.bloodGroup,
  });

  factory PatientDetail.fromJson(Map<String, dynamic> json) {
    parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return PatientDetail(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      emailId: json['emailId']?.toString(),
      gender: json['gender']?.toString() ?? '',
      dob: parseDateTime(json['dob']),
      bloodGroup: json['bloodGroup']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (emailId != null) 'emailId': emailId,
      'gender': gender,
      'dob': dob.toIso8601String(),
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
    };
  }
}

class ScheduleDetail {
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String slotStatus;

  ScheduleDetail({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.slotStatus,
  });

  factory ScheduleDetail.fromJson(Map<String, dynamic> json) {
    parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return ScheduleDetail(
      date: parseDateTime(json['date']),
      startTime: parseDateTime(json['startTime']),
      endTime: parseDateTime(json['endTime']),
      slotStatus: json['slotStatus']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'slotStatus': slotStatus,
    };
  }
}

class LocationDetail {
  final String type;
  final String id;
  final String name;
  final String address;

  LocationDetail({
    required this.type,
    required this.id,
    required this.name,
    required this.address,
  });

  factory LocationDetail.fromJson(Map<String, dynamic> json) {
    return LocationDetail(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'id': id, 'name': name, 'address': address};
  }
}

class CancelAppointmentResponse {
  final bool success;
  final String message;
  final CancelAppointmentData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  CancelAppointmentResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory CancelAppointmentResponse.fromJson(Map<String, dynamic> json) {
    return CancelAppointmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CancelAppointmentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class CancelAppointmentData {
  final bool success;
  final dynamic message;
  final dynamic data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  CancelAppointmentData({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory CancelAppointmentData.fromJson(Map<String, dynamic> json) {
    return CancelAppointmentData(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class RescheduleAppointmentRequest {
  final String appointmentId;
  final String newSlotId;

  RescheduleAppointmentRequest({
    required this.appointmentId,
    required this.newSlotId,
  });

  Map<String, dynamic> toJson() {
    return {'appointmentId': appointmentId, 'newSlotId': newSlotId};
  }
}

class RescheduleAppointmentResponse {
  final bool success;
  final String message;
  final AppointmentData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  RescheduleAppointmentResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory RescheduleAppointmentResponse.fromJson(Map<String, dynamic> json) {
    return RescheduleAppointmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AppointmentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class VerifyAppointmentRequest {
  final String appointmentId;
  final String merchantTransactionId;

  VerifyAppointmentRequest({
    required this.appointmentId,
    required this.merchantTransactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'merchantTransactionId': merchantTransactionId,
    };
  }
}

class VerifyAppointmentResponse {
  final bool success;
  final String message;
  final AppointmentData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  VerifyAppointmentResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory VerifyAppointmentResponse.fromJson(Map<String, dynamic> json) {
    return VerifyAppointmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? AppointmentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}
