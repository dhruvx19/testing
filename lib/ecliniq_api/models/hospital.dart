class Hospital {
  final String id;
  final String name;
  final String type;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final int noOfBeds;
  final String logo;
  final String image;
  final String url;
  final String phone;
  final String establishmentYear;
  final double distance;
  final int numberOfDoctors;

  Hospital({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.noOfBeds,
    required this.logo,
    required this.image,
    required this.url,
    required this.phone,
    required this.establishmentYear,
    required this.distance,
    required this.numberOfDoctors,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      noOfBeds: json['noOfBeds'] ?? 0,
      logo: json['logo'] ?? '',
      image: json['image'] ?? '',
      url: json['url'] ?? '',
      phone: json['phone'] ?? '',
      establishmentYear: json['establishmentYear'] ?? '',
      distance: (json['distance'] as num? ?? 0.0).toDouble(),
      numberOfDoctors: json['numberOfDoctors'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'noOfBeds': noOfBeds,
      'logo': logo,
      'image': image,
      'url': url,
      'phone': phone,
      'establishmentYear': establishmentYear,
      'distance': distance,
      'numberOfDoctors': numberOfDoctors,
    };
  }
}

class TopHospitalsResponse {
  final bool success;
  final String message;
  final List<Hospital> data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  TopHospitalsResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory TopHospitalsResponse.fromJson(Map<String, dynamic> json) {
    return TopHospitalsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Hospital.fromJson(item))
          .toList() ?? [],
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((hospital) => hospital.toJson()).toList(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class TopHospitalsRequest {
  final double latitude;
  final double longitude;

  TopHospitalsRequest({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
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

  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (blockNo != null && blockNo!.isNotEmpty) parts.add(blockNo!);
    if (landmark != null && landmark!.isNotEmpty) parts.add('Near $landmark');
    return parts.join(', ');
  }
}

class HospitalSpecialty {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;

  HospitalSpecialty({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HospitalSpecialty.fromJson(Map<String, dynamic> json) {
    return HospitalSpecialty(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class HospitalDetail {
  final String id;
  final String name;
  final String type;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final int noOfBeds;
  final String logo;
  final HospitalAddress address;
  final String image;
  final String url;
  final String establishmentYear;
  final int numberOfDoctors;
  final List<String> accreditation;
  final List<String> hospitalServices;
  final List<HospitalSpecialty> specialties;

  HospitalDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.noOfBeds,
    required this.logo,
    required this.address,
    required this.image,
    required this.url,
    required this.establishmentYear,
    required this.numberOfDoctors,
    required this.accreditation,
    required this.hospitalServices,
    required this.specialties,
  });

  factory HospitalDetail.fromJson(Map<String, dynamic> json) {
    return HospitalDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      noOfBeds: json['noOfBeds'] ?? 0,
      logo: json['logo'] ?? '',
      address: json['address'] != null
          ? HospitalAddress.fromJson(json['address'])
          : HospitalAddress(),
      image: json['image'] ?? '',
      url: json['url'] ?? '',
      establishmentYear: json['establishmentYear'] ?? '',
      numberOfDoctors: json['numberOfDoctors'] ?? 0,
      accreditation: (json['accreditation'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hospitalServices: (json['hospitalServices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => HospitalSpecialty.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'noOfBeds': noOfBeds,
      'logo': logo,
      'address': address.toJson(),
      'image': image,
      'url': url,
      'establishmentYear': establishmentYear,
      'numberOfDoctors': numberOfDoctors,
      'accreditation': accreditation,
      'hospitalServices': hospitalServices,
      'specialties': specialties.map((e) => e.toJson()).toList(),
    };
  }
}

class HospitalDetailsResponse {
  final bool success;
  final String message;
  final HospitalDetail? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  HospitalDetailsResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory HospitalDetailsResponse.fromJson(Map<String, dynamic> json) {
    return HospitalDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? HospitalDetail.fromJson(json['data'])
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
      'data': data?.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}
