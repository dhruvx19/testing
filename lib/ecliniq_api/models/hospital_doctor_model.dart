// Updated Doctor Model to match the API response
class Doctor {
  final String id;
  final String firstName;
  final String lastName;
  final String? headline;
  final String specialization;
  final String qualifications;
  final int? experience;
  final double? rating;
  final double? fee;
  final String? timings;
  final String? location;
  final double? distance;
  final DoctorAvailability? availability;
  final String? profilePhoto;
  final DoctorContact? contact;
  final List<dynamic> clinics;
  final List<DoctorHospital> hospitals;
  final bool isFavourite;

  Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.headline,
    required this.specialization,
    required this.qualifications,
    this.experience,
    this.rating,
    this.fee,
    this.timings,
    this.location,
    this.distance,
    this.availability,
    this.profilePhoto,
    this.contact,
    this.clinics = const [],
    this.hospitals = const [],
    this.isFavourite = false,
  });

  // Computed property for full name
  String get name => '$firstName $lastName'.trim();

  // Computed property for specializations list
  List<String> get specializations {
    if (specialization.isEmpty) return [];
    return specialization.split(',').map((s) => s.trim()).toList();
  }

  // Computed property for degree types
  List<String> get degreeTypes {
    if (qualifications.isEmpty) return [];
    return qualifications.split(',').map((s) => s.trim()).toList();
  }

  // Year of experience
  int? get yearOfExperience => experience;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      headline: json['headline'],
      // API may return an array 'specializations' or a string 'specialization'
      specialization: (json['specializations'] is List)
          ? ((json['specializations'] as List).map((e) => e.toString()).toList()).join(', ')
          : (json['specialization'] ?? ''),
      // API may return an array 'qualifications'
      qualifications: (json['qualifications'] is List)
          ? ((json['qualifications'] as List).map((e) => e.toString()).toList()).join(', ')
          : (json['qualifications'] ?? ''),
      experience: json['experience'],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
      // Fee can be a string (e.g., "600"). Parse to double when possible.
      fee: () {
        final f = json['fee'];
        if (f == null) return null;
        if (f is num) return f.toDouble();
        final parsed = double.tryParse(f.toString());
        return parsed;
      }(),
      timings: json['timings'],
      location: json['location'],
      // Distance object: { meters, km }
      distance: () {
        final d = json['distance'];
        if (d is Map) {
          final km = d['km'];
          if (km is num) return km.toDouble();
          return double.tryParse(km?.toString() ?? '');
        }
        if (d is num) return d.toDouble();
        return double.tryParse(d?.toString() ?? '');
      }(),
      availability: json['availability'] != null
          ? DoctorAvailability.fromJson(json['availability'])
          : null,
      profilePhoto: json['profilePhoto'],
      contact: json['contact'] != null
          ? DoctorContact.fromJson(json['contact'])
          : null,
      clinics: json['clinics'] ?? [],
      hospitals: (json['hospitals'] as List<dynamic>?)
              ?.map((h) => DoctorHospital.fromJson(h))
              .toList() ??
          [],
      isFavourite: json['isFavourite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'headline': headline,
      'specialization': specialization,
      'qualifications': qualifications,
      'experience': experience,
      'rating': rating,
      'fee': fee,
      'timings': timings,
      'location': location,
      'distance': distance,
      'availability': availability?.toJson(),
      'profilePhoto': profilePhoto,
      'contact': contact?.toJson(),
      'clinics': clinics,
      'hospitals': hospitals.map((h) => h.toJson()).toList(),
      'isFavourite': isFavourite,
    };
  }
}

class DoctorAvailability {
  final String status;
  final String message;
  final String? slotId;
  final String? date;
  final String? startTime;
  final int? availableTokens;
  final int? totalTokens;
  final RawSlot? rawSlot;

  DoctorAvailability({
    required this.status,
    required this.message,
    this.slotId,
    this.date,
    this.startTime,
    this.availableTokens,
    this.totalTokens,
    this.rawSlot,
  });

  factory DoctorAvailability.fromJson(Map<String, dynamic> json) {
    return DoctorAvailability(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      slotId: json['slotId'],
      date: json['date'],
      startTime: json['startTime'],
      availableTokens: json['availableTokens'],
      totalTokens: json['totalTokens'],
      rawSlot: json['rawSlot'] != null
          ? RawSlot.fromJson(json['rawSlot'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'slotId': slotId,
      'date': date,
      'startTime': startTime,
      'availableTokens': availableTokens,
      'totalTokens': totalTokens,
      'rawSlot': rawSlot?.toJson(),
    };
  }
}

class RawSlot {
  final String id;
  final String startTime;
  final String endTime;
  final int maxTokens;
  final int availableTokens;
  final String slotStatus;

  RawSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.maxTokens,
    required this.availableTokens,
    required this.slotStatus,
  });

  factory RawSlot.fromJson(Map<String, dynamic> json) {
    return RawSlot(
      id: json['id'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      maxTokens: json['maxTokens'] ?? 0,
      availableTokens: json['availableTokens'] ?? 0,
      slotStatus: json['slotStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'maxTokens': maxTokens,
      'availableTokens': availableTokens,
      'slotStatus': slotStatus,
    };
  }
}

class DoctorContact {
  final String? phone;
  final String? email;

  DoctorContact({
    this.phone,
    this.email,
  });

  factory DoctorContact.fromJson(Map<String, dynamic> json) {
    return DoctorContact(
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}

class DoctorHospital {
  final String id;
  final String name;
  final HospitalAddress? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? consultationFee;

  DoctorHospital({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.consultationFee,
  });

  factory DoctorHospital.fromJson(Map<String, dynamic> json) {
    return DoctorHospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] != null
          ? HospitalAddress.fromJson(json['address'])
          : null,
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      distanceKm: () {
        final d = json['distance'];
        if (d is Map) {
          final km = d['km'];
          if (km is num) return km.toDouble();
          return double.tryParse(km?.toString() ?? '');
        }
        if (d is num) return d.toDouble();
        return double.tryParse(d?.toString() ?? '');
      }(),
      consultationFee: json['consultationFee']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address?.toJson(),
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distanceKm,
      'consultationFee': consultationFee,
    };
  }
}

class HospitalAddress {
  final String? street;
  final String? blockNo;
  final String? landmark;

  HospitalAddress({
    this.street,
    this.blockNo,
    this.landmark,
  });

  factory HospitalAddress.fromJson(Map<String, dynamic> json) {
    return HospitalAddress(
      street: json['street'],
      blockNo: json['blockNo'],
      landmark: json['landmark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'blockNo': blockNo,
      'landmark': landmark,
    };
  }
}

// Response wrapper
class TopDoctorsResponse {
  final bool success;
  final String message;
  final List<Doctor> data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  TopDoctorsResponse({
    required this.success,
    required this.message,
    required this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory TopDoctorsResponse.fromJson(Map<String, dynamic> json) {
    return TopDoctorsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((d) => Doctor.fromJson(d))
              .toList() ??
          [],
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((d) => d.toJson()).toList(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}