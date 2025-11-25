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
  final String profileInitial; // e.g. 'M', 'A'

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
      rating: json['rating'].toDouble(),
      fee: json['fee'],
      availableTime: json['availableTime'],
      availableDays: json['availableDays'],
      location: json['location'],
      distanceKm: json['distanceKm'].toDouble(),
      availableTokens: json['availableTokens'],
      nextAvailable: json['nextAvailable'],
      isFavorite: json['isFavorite'] ?? false,
      isVerified: json['isVerified'] ?? false,
      profileInitial: json['profileInitial'],
    );
  }

  /// Factory method to create FavouriteDoctor from API response
  factory FavouriteDoctor.fromApiResponse(Map<String, dynamic> json) {
    // Extract name
    final name = json['name'] ?? '';
    
    // Extract profile initial (first letter of first name or name)
    final firstName = json['firstName'] ?? '';
    final profileInitial = firstName.isNotEmpty 
        ? firstName[0].toUpperCase() 
        : (name.isNotEmpty ? name[0].toUpperCase() : 'D');
    
    // Extract specialization (join array or use first one)
    final specializations = json['specializations'] as List<dynamic>? ?? [];
    final specialization = specializations.isNotEmpty 
        ? specializations.join(', ') 
        : 'General Physician';
    
    // Extract qualification (join array or use default)
    final qualifications = json['qualifications'] as List<dynamic>? ?? [];
    final qualification = qualifications.isNotEmpty 
        ? qualifications.join(', ') 
        : 'MBBS';
    
    // Extract experience
    final experience = json['experience'] ?? 0;
    
    // Extract rating
    final rating = (json['rating'] ?? 0.0).toDouble();
    
    // Extract fee (convert string to int)
    final feeStr = json['fee'] ?? '0';
    final fee = int.tryParse(feeStr.toString()) ?? 0;
    
    // Extract distance
    final distance = json['distance']?.toDouble() ?? 0.0;
    
    // Extract availability information
    final availability = json['availability'] as Map<String, dynamic>?;
    final availableTokens = availability?['availableTokens'] ?? 0;
    final totalTokens = availability?['totalTokens'] ?? 0;
    final availabilityMessage = availability?['message'] ?? 'Not available';
    final startTime = availability?['startTime'] ?? '';
    
    // Extract location from clinics or hospitals
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
    
    // Extract available time and days (from availability message or default)
    String availableTime = 'Not available';
    String availableDays = '';
    
    // Use startTime if available, otherwise parse from message
    if (startTime.isNotEmpty) {
      availableTime = startTime;
    }
    
    // Parse availability status and message
    final availabilityStatus = availability?['status'] as String? ?? '';
    if (availabilityStatus.contains('TODAY') || availabilityMessage.toLowerCase().contains('today')) {
      availableDays = 'Today';
      if (availableTime.isEmpty) {
        // Try to extract time from message
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
    
    // Extract isFavorite
    final isFavorite = json['isFavourite'] ?? false;
    
    // isVerified - not in API response, defaulting to false
    // You might want to add this field to the API response later
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

/// Response model for favourite doctors API
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

  factory FavouriteDoctorsResponse.fromJson(Map<String, dynamic> json) {
    return FavouriteDoctorsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => FavouriteDoctor.fromApiResponse(item as Map<String, dynamic>))
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
