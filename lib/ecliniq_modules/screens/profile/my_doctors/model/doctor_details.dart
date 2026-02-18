class FavouriteDoctor {
  final String id;
  final String name;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double rating;
  final int fee;
  final String availableTime;
  final String availableDays;
  final String location;
  final double distanceKm;
  final int availableTokens;
  final String nextAvailable;
  final bool isFavorite;
  final bool isVerified;
  final String profileInitial; 

  FavouriteDoctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.rating,
    required this.fee,
    required this.availableTime,
    required this.availableDays,
    required this.location,
    required this.distanceKm,
    required this.availableTokens,
    required this.nextAvailable,
    this.isFavorite = false,
    this.isVerified = false,
    required this.profileInitial,
  });

  factory FavouriteDoctor.fromJson(Map<String, dynamic> json) {
    return FavouriteDoctor(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      qualification: json['qualification'],
      experienceYears: json['experienceYears'],
      rating: (json['rating'] as num).toDouble(),
      fee: json['fee'],
      availableTime: json['availableTime'],
      availableDays: json['availableDays'],
      location: json['location'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      availableTokens: json['availableTokens'],
      nextAvailable: json['nextAvailable'],
      isFavorite: json['isFavorite'] ?? false,
      isVerified: json['isVerified'] ?? false,
      profileInitial: json['profileInitial'],
    );
  }

  
  factory FavouriteDoctor.fromApiResponse(
    Map<String, dynamic> json, {
    double? userLat,
    double? userLng,
    Function? distanceCalculator,
  }) {
    
    final name = json['name'] ?? '';
    
    
    final firstName = json['firstName'] ?? '';
    final profileInitial = firstName.isNotEmpty 
        ? firstName[0].toUpperCase() 
        : (name.isNotEmpty ? name[0].toUpperCase() : 'D');
    
    
    final specializations = json['specializations'] as List<dynamic>? ?? [];
    final specialization = specializations.isNotEmpty 
        ? specializations.join(', ') 
        : 'General Physician';
    
    
    final qualifications = json['qualifications'] as List<dynamic>? ?? [];
    final qualification = qualifications.isNotEmpty 
        ? qualifications.join(', ') 
        : 'MBBS';
    
    
    final experience = json['experience'] ?? 0;
    
    
    final rating = (json['rating'] as num? ?? 0.0).toDouble();
    
    
    final feeStr = json['fee'] ?? '0';
    final fee = int.tryParse(feeStr.toString()) ?? 0;
    
    
    double distance = 0.0;
    
    // Calculate distance from clinic/hospital coordinates if available
    if (userLat != null && userLng != null && distanceCalculator != null) {
      final clinics = json['clinics'] as List<dynamic>? ?? [];
      final hospitals = json['hospitals'] as List<dynamic>? ?? [];
      
      double? locationLat;
      double? locationLng;
      
      if (clinics.isNotEmpty) {
        final clinic = clinics[0] as Map<String, dynamic>;
        locationLat = (clinic['latitude'] as num?)?.toDouble();
        locationLng = (clinic['longitude'] as num?)?.toDouble();
      } else if (hospitals.isNotEmpty) {
        final hospital = hospitals[0] as Map<String, dynamic>;
        locationLat = (hospital['latitude'] as num?)?.toDouble();
        locationLng = (hospital['longitude'] as num?)?.toDouble();
      }
      
      if (locationLat != null && locationLng != null) {
        distance = distanceCalculator(userLat, userLng, locationLat, locationLng);
      }
    } else {
      // Fallback to distance from API if available
      final d = json['distance'];
      if (d is Map<String, dynamic>) {
        final km = d['km'];
        if (km is num) {
          distance = km.toDouble();
        } else {
          distance = double.tryParse(km?.toString() ?? '0') ?? 0.0;
        }
      } else if (d is num) {
        distance = d.toDouble();
      } else if (d != null) {
        distance = double.tryParse(d.toString()) ?? 0.0;
      }
    }
    
    
    final availability = json['availability'] as Map<String, dynamic>?;
    final availableTokens = availability?['availableTokens'] ?? 0;
    final availabilityMessage = availability?['message'] ?? 'Not available';
    final startTime = availability?['startTime'] ?? '';
    
    
    final clinics = json['clinics'] as List<dynamic>? ?? [];
    final hospitals = json['hospitals'] as List<dynamic>? ?? [];
    String location = 'Location not available';
    if (clinics.isNotEmpty) {
      final clinic = clinics[0] as Map<String, dynamic>;
      final city = clinic['city'] ?? '';
      final state = clinic['state'] ?? '';
      location = city.isNotEmpty && state.isNotEmpty 
          ? '$city, $state' 
          : (clinic['name'] ?? location);
    } else if (hospitals.isNotEmpty) {
      final hospital = hospitals[0] as Map<String, dynamic>;
      final city = hospital['city'] ?? '';
      final state = hospital['state'] ?? '';
      location = city.isNotEmpty && state.isNotEmpty 
          ? '$city, $state' 
          : (hospital['name'] ?? location);
    }
    
    
    String availableTime = 'Not available';
    String availableDays = '';
    
    
    if (startTime.isNotEmpty) {
      availableTime = startTime;
    }
    
    
    final availabilityStatus = availability?['status'] as String? ?? '';
    if (availabilityStatus.contains('TODAY') || availabilityMessage.toLowerCase().contains('today')) {
      availableDays = 'Today';
      if (availableTime.isEmpty) {
        
        final timeMatch = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM))', caseSensitive: false).firstMatch(availabilityMessage);
        if (timeMatch != null) {
          availableTime = timeMatch.group(1) ?? 'Check availability';
        } else {
          availableTime = 'Check availability';
        }
      }
    } else if (availabilityStatus.contains('TOMORROW') || availabilityMessage.toLowerCase().contains('tomorrow')) {
      availableDays = 'Tomorrow';
      if (availableTime.isEmpty) {
        final timeMatch = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM))', caseSensitive: false).firstMatch(availabilityMessage);
        if (timeMatch != null) {
          availableTime = timeMatch.group(1) ?? 'Check availability';
        } else {
          availableTime = 'Check availability';
        }
      }
    } else {
      availableDays = 'Check availability';
      if (availableTime.isEmpty) {
        availableTime = 'Not available';
      }
    }
    
    
    final isFavorite = json['isFavourite'] ?? false;
    
    
    
    final isVerified = false;
    
    return FavouriteDoctor(
      id: json['id'] ?? '',
      name: name,
      specialization: specialization,
      qualification: qualification,
      experienceYears: experience,
      rating: rating,
      fee: fee,
      availableTime: availableTime,
      availableDays: availableDays,
      location: location,
      distanceKm: distance,
      availableTokens: availableTokens,
      nextAvailable: availabilityMessage,
      isFavorite: isFavorite,
      isVerified: isVerified,
      profileInitial: profileInitial,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'specialization': specialization,
    'qualification': qualification,
    'experienceYears': experienceYears,
    'rating': rating,
    'fee': fee,
    'availableTime': availableTime,
    'availableDays': availableDays,
    'location': location,
    'distanceKm': distanceKm,
    'availableTokens': availableTokens,
    'nextAvailable': nextAvailable,
    'isFavorite': isFavorite,
    'isVerified': isVerified,
    'profileInitial': profileInitial,
  };
}


class FavouriteDoctorsResponse {
  final bool success;
  final String message;
  final List<FavouriteDoctor> data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  FavouriteDoctorsResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory FavouriteDoctorsResponse.fromJson(
    Map<String, dynamic> json, {
    double? userLat,
    double? userLng,
    Function? distanceCalculator,
  }) {
    return FavouriteDoctorsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => FavouriteDoctor.fromApiResponse(
                item as Map<String, dynamic>,
                userLat: userLat,
                userLng: userLng,
                distanceCalculator: distanceCalculator,
              ))
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
      'data': data.map((doctor) => doctor.toJson()).toList(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}
