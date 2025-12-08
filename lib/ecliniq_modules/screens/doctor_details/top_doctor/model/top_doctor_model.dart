class Doctor {
  final String id;
  final String name;
  final String? profilePhoto;
  final double? rating;
  final List<String> specializations;
  final List<String> degrees;
  final int? yearOfExperience;
  final double? distanceKm;
  final Hospital? hospital;
  final Clinic? clinic;

  Doctor({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.rating,
    required this.specializations,
    required this.degrees,
    this.yearOfExperience,
    this.distanceKm,
    this.hospital,
    this.clinic,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // Helper to parse hospital - handle both singular and plural
    Hospital? parseHospital() {
      // Try singular first
      if (json['hospital'] != null) {
        try {
          return Hospital.fromJson(json['hospital'] as Map<String, dynamic>);
        } catch (e) {
          // If parsing fails, try plural
        }
      }
      // Try plural (array) - take first item
      if (json['hospitals'] != null) {
        final hospitals = json['hospitals'] as List<dynamic>?;
        if (hospitals != null && hospitals.isNotEmpty) {
          try {
            return Hospital.fromJson(hospitals.first as Map<String, dynamic>);
          } catch (e) {
            // If parsing fails, return null
          }
        }
      }
      return null;
    }

    // Helper to parse clinic - handle both singular and plural
    Clinic? parseClinic() {
      // Try singular first
      if (json['clinic'] != null) {
        try {
          return Clinic.fromJson(json['clinic'] as Map<String, dynamic>);
        } catch (e) {
          // If parsing fails, try plural
        }
      }
      // Try plural (array) - take first item
      if (json['clinics'] != null) {
        final clinics = json['clinics'] as List<dynamic>?;
        if (clinics != null && clinics.isNotEmpty) {
          try {
            return Clinic.fromJson(clinics.first as Map<String, dynamic>);
          } catch (e) {
            // If parsing fails, return null
          }
        }
      }
      return null;
    }

    // Distance can be provided as a simple number or as an object { meters, km }
    double? parseDistanceKm(dynamic d) {
      if (d == null) return null;
      if (d is num) return d.toDouble();
      if (d is Map) {
        final km = d['km'];
        if (km is num) return km.toDouble();
        return double.tryParse(km?.toString() ?? '');
      }
      return double.tryParse(d.toString());
    }

    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profilePhoto: json['profilePhoto'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      // New response uses 'qualifications' instead of 'degrees'
      degrees: (json['qualifications'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          ((json['degrees'] as List<dynamic>?)
                  ?.map((item) => item.toString())
                  .toList() ??
              []),
      // New response uses 'experience' instead of 'yearOfExperience'
      yearOfExperience: json['experience'] ?? json['yearOfExperience'],
      // Handle distance object { meters, km }
      distanceKm: parseDistanceKm(json['distance']) ?? (json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null),
      hospital: parseHospital(),
      clinic: parseClinic(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      if (rating != null) 'rating': rating,
      'specializations': specializations,
      'degrees': degrees,
      if (yearOfExperience != null) 'yearOfExperience': yearOfExperience,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (hospital != null) 'hospital': hospital!.toJson(),
      if (clinic != null) 'clinic': clinic!.toJson(),
    };
  }

  // Helper methods
  String get primarySpecialization =>
      specializations.isNotEmpty ? specializations.first : 'Doctor';

  String get educationText => degrees.isNotEmpty ? degrees.join(', ') : '';

  String get experienceText => yearOfExperience != null
      ? '${yearOfExperience}yrs of exp'
      : 'Experience not specified';

  String get ratingText =>
      rating != null ? rating!.toStringAsFixed(1) : 'N/A';

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'D';

  bool get hasLocations => hospital != null || clinic != null;

  List<LocationData> get locations {
    final List<LocationData> locs = [];

    if (hospital != null) {
      locs.add(LocationData.fromHospital(hospital!));
    }

    if (clinic != null) {
      locs.add(LocationData.fromClinic(clinic!));
    }

    return locs;
  }
}

class Hospital {
  final String id;
  final String name;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double distanceKm;

  Hospital({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    // Handle nested address object if present
    String getCity() {
      if (json['city'] != null) return json['city'].toString();
      if (json['address'] != null && json['address'] is Map) {
        final address = json['address'] as Map<String, dynamic>;
        return address['city']?.toString() ?? '';
      }
      return '';
    }

    String getState() {
      if (json['state'] != null) return json['state'].toString();
      if (json['address'] != null && json['address'] is Map) {
        final address = json['address'] as Map<String, dynamic>;
        return address['state']?.toString() ?? '';
      }
      return '';
    }

    String getPincode() {
      if (json['pincode'] != null) return json['pincode'].toString();
      if (json['address'] != null && json['address'] is Map) {
        final address = json['address'] as Map<String, dynamic>;
        return address['pincode']?.toString() ?? '';
      }
      return '';
    }

    // Handle both distanceKm and distance fields
    double getDistanceKm() {
      if (json['distanceKm'] != null) {
        return (json['distanceKm'] is num) 
            ? json['distanceKm'].toDouble() 
            : double.tryParse(json['distanceKm'].toString()) ?? 0.0;
      }
      if (json['distance'] != null) {
        return (json['distance'] is num) 
            ? json['distance'].toDouble() 
            : double.tryParse(json['distance'].toString()) ?? 0.0;
      }
      return 0.0;
    }

    return Hospital(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: getCity(),
      state: getState(),
      pincode: getPincode(),
      latitude: (json['latitude'] is num) 
          ? json['latitude'].toDouble() 
          : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: (json['longitude'] is num) 
          ? json['longitude'].toDouble() 
          : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      distanceKm: getDistanceKm(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
    };
  }

  String get address => '$city, $state';
  String get distance => '${distanceKm.toStringAsFixed(1)} Km';
}

class Clinic {
  final String id;
  final String name;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double distanceKm;

  Clinic({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    // Handle nested address object if present
    String getCity() {
      if (json['city'] != null) return json['city'].toString();
      if (json['address'] != null && json['address'] is Map) {
        final address = json['address'] as Map<String, dynamic>;
        return address['city']?.toString() ?? '';
      }
      return '';
    }

    String getState() {
      if (json['state'] != null) return json['state'].toString();
      if (json['address'] != null && json['address'] is Map) {
        final address = json['address'] as Map<String, dynamic>;
        return address['state']?.toString() ?? '';
      }
      return '';
    }

    String getPincode() {
      if (json['pincode'] != null) return json['pincode'].toString();
      if (json['address'] != null && json['address'] is Map) {
        final address = json['address'] as Map<String, dynamic>;
        return address['pincode']?.toString() ?? '';
      }
      return '';
    }

    // Handle both distanceKm and distance fields
    double getDistanceKm() {
      if (json['distanceKm'] != null) {
        return (json['distanceKm'] is num) 
            ? json['distanceKm'].toDouble() 
            : double.tryParse(json['distanceKm'].toString()) ?? 0.0;
      }
      if (json['distance'] != null) {
        return (json['distance'] is num) 
            ? json['distance'].toDouble() 
            : double.tryParse(json['distance'].toString()) ?? 0.0;
      }
      return 0.0;
    }

    return Clinic(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: getCity(),
      state: getState(),
      pincode: getPincode(),
      latitude: (json['latitude'] is num) 
          ? json['latitude'].toDouble() 
          : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: (json['longitude'] is num) 
          ? json['longitude'].toDouble() 
          : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      distanceKm: getDistanceKm(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
    };
  }

  String get address => '$city, $state';
  String get distance => '${distanceKm.toStringAsFixed(1)} Km';
}

class LocationData {
  final String id;
  final String name;
  final String hours;
  final String area;
  final String distance;
  final LocationType type;
  final double latitude;
  final double longitude;

  LocationData({
    required this.id,
    required this.name,
    required this.hours,
    required this.area,
    required this.distance,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  factory LocationData.fromHospital(Hospital hospital) {
    return LocationData(
      id: hospital.id,
      name: hospital.name,
      hours: 'Contact for timings',
      area: hospital.address,
      distance: hospital.distance,
      type: LocationType.hospital,
      latitude: hospital.latitude,
      longitude: hospital.longitude,
    );
  }

  factory LocationData.fromClinic(Clinic clinic) {
    return LocationData(
      id: clinic.id,
      name: clinic.name,
      hours: 'Contact for timings',
      area: clinic.address,
      distance: clinic.distance,
      type: LocationType.clinic,
      latitude: clinic.latitude,
      longitude: clinic.longitude,
    );
  }
}

enum LocationType {
  hospital,
  clinic;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

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
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory TopDoctorsResponse.fromJson(Map<String, dynamic> json) {
    return TopDoctorsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Doctor.fromJson(item))
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
      'data': data.map((doctor) => doctor.toJson()).toList(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

class TopDoctorsRequest {
  final double latitude;
  final double longitude;

  TopDoctorsRequest({
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