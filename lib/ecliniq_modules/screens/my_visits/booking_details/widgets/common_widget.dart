

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
  });

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
    };
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

  String get fullDateTime => '$displayDate | $time';
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
  final double serviceFee;
  final double totalPayable;
  final bool isServiceFeeWaived;
  final String waiverMessage;

  PaymentInfo({
    required this.consultationFee,
    required this.serviceFee,
    required this.totalPayable,
    required this.isServiceFeeWaived,
    required this.waiverMessage,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      consultationFee: (json['consultation_fee'] as num? ?? 0).toDouble(),
      serviceFee: (json['service_fee'] as num? ?? 0).toDouble(),
      totalPayable: (json['total_payable'] as num? ?? 0).toDouble(),
      isServiceFeeWaived: json['is_service_fee_waived'] ?? false,
      waiverMessage: json['waiver_message'] ?? 'We care for you and provide a free booking',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_fee': consultationFee,
      'service_fee': serviceFee,
      'total_payable': totalPayable,
      'is_service_fee_waived': isServiceFeeWaived,
      'waiver_message': waiverMessage,
    };
  }
}











  




class AppointmentApiService {

  static const String baseUrl = 'https://your-api-url.com/api/v1';


  Future<AppointmentDetailModel> fetchAppointmentDetail(String appointmentId) async {
    try {





      

      await Future.delayed(const Duration(seconds: 1));
      
      final mockJson = {
        'id': appointmentId,
        'status': 'confirmed',
        'token_number': '76',
        'expected_time': '2:30PM',
        'current_token_number': '67',
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
          'consultation_fee':  700,
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