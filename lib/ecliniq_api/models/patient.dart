class PatientDetailsResponse {
  final bool success;
  final String message;
  final PatientDetailsData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  PatientDetailsResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory PatientDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PatientDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PatientDetailsData.fromJson(json['data'])
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class PatientDetailsData {
  final String userId;
  final String patientCode;
  final DateTime? dob;
  final String? bloodGroup;
   final String? gender;
  final int? height;
  final int? weight;
  final String? abhaId;
  final String? blockNo;
  final String? areaStreet;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;
  final List<String> languages;
  final bool getPhoneNotifications;
  final bool getWhatsAppNotifications;
  final bool getEmailNotifications;
  final bool getInAppNotifications;
  final bool getPromotionalMessages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePhoto;
  final PatientUser? user;

  PatientDetailsData({
    required this.userId,
    required this.patientCode,
    this.dob,
    this.bloodGroup,
    this.gender,
    this.height,
    this.weight,
    this.abhaId,
    this.blockNo,
    this.areaStreet,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    required this.languages,
    required this.getPhoneNotifications,
    required this.getWhatsAppNotifications,
    required this.getEmailNotifications,
    required this.getInAppNotifications,
    required this.getPromotionalMessages,
    required this.createdAt,
    required this.updatedAt,
    this.profilePhoto,
    this.user,
  });

  factory PatientDetailsData.fromJson(Map<String, dynamic> json) {
    
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return null;
      }
    }

    
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return PatientDetailsData(
      userId: json['userId']?.toString() ?? '',
      patientCode: json['patientCode']?.toString() ?? '',
      dob: parseDateTime(json['dob']),
      bloodGroup: json['bloodGroup']?.toString(),
      gender: json['gender']?.toString(),
      height: json['height'] is int
          ? json['height']
          : json['height'] != null
              ? int.tryParse(json['height'].toString())
              : null,
      weight: json['weight'] is int
          ? json['weight']
          : json['weight'] != null
              ? int.tryParse(json['weight'].toString())
              : null,
      abhaId: json['abhaId']?.toString(),
      blockNo: json['blockNo']?.toString(),
      areaStreet: json['areaStreet']?.toString(),
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      languages: parseStringList(json['languages']),
      getPhoneNotifications: json['getPhoneNotifications'] ?? false,
      getWhatsAppNotifications: json['getWhatsAppNotifications'] ?? false,
      getEmailNotifications: json['getEmailNotifications'] ?? false,
      getInAppNotifications: json['getInAppNotifications'] ?? false,
      getPromotionalMessages: json['getPromotionalMessages'] ?? false,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']) ?? DateTime.now(),
      profilePhoto: (json['profilePhoto']?.toString().isNotEmpty == true)
          ? json['profilePhoto']?.toString()
          : (json['user'] is Map<String, dynamic>
              ? (json['user']['profilePhoto']?.toString())
              : null),
      user: json['user'] != null
          ? PatientUser.fromJson(json['user'])
          : null,
    );
  }

  
  String get fullName {
    if (user == null) return '';
    final firstName = user!.firstName ?? '';
    final lastName = user!.lastName ?? '';
    return '$firstName $lastName'.trim();
  }

  String get displayPhone {
    if (user?.phone == null) return '';
    final phone = user!.phone!;
    if (phone.length == 10) {
      return '+91 $phone';
    }
    return phone;
  }

  String get displayEmail {
    return user?.emailId ?? '';
  }

  String? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int years = now.year - dob!.year;
    int months = now.month - dob!.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    return '${years}y ${months}m';
  }

  String get displayHeight {
    if (height == null) return 'N/A';
    return '$height cm';
  }

  String get displayWeight {
    if (weight == null) return 'N/A';
    return '$weight kg';
  }

  double? get bmi {
    if (height == null || weight == null || height == 0) return null;
    final heightInMeters = height! / 100.0;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get healthStatus {
    final bmiValue = bmi;
    if (bmiValue == null) return 'N/A';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Healthy';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get gender from either direct field or user object
  String? get displayGender {
    // Try direct gender field first
    if (gender != null && gender!.isNotEmpty) {
      return _formatGender(gender!);
    }
    // Fallback to user.gender
    if (user?.gender != null && user!.gender!.isNotEmpty) {
      return _formatGender(user!.gender!);
    }
    return null;
  }

  /// Format gender from backend format (MALE, FEMALE, OTHER) to display format
  String _formatGender(String genderValue) {
    switch (genderValue.toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
        return 'Other';
      default:
        return genderValue;
    }
  }
}

class PatientUser {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? emailId;
  final String? phone;
  final String? profilePhoto;
  final String? gender;

  PatientUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.emailId,
    this.phone,
    this.profilePhoto,
    this.gender,
  });

  factory PatientUser.fromJson(Map<String, dynamic> json) {
    return PatientUser(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      emailId: json['emailId']?.toString(),
      phone: json['phone']?.toString(),
      profilePhoto: json['profilePhoto']?.toString(),
      gender: json['gender']?.toString(),
    );
  }
}


class AddDependentRequest {
  final String firstName;
  final String lastName;
  final String dob;
  final String gender;
  final String relation;
  final String? phone;
  final String? emailId;
  final String? bloodGroup;
  final int? height;
  final int? weight;
  final String? profilePhoto;

  AddDependentRequest({
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.gender,
    required this.relation,
    this.phone,
    this.emailId,
    this.bloodGroup,
    this.height,
    this.weight,
    this.profilePhoto,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob,
      'gender': gender,
      'relation': relation,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (emailId != null && emailId!.isNotEmpty) 'emailId': emailId,
      'bloodGroup': bloodGroup,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (profilePhoto != null && profilePhoto!.isNotEmpty) 'profilePhoto': profilePhoto,
    };
  }
}

class DeleteDependentResponse {
  final bool success;
  final String message;
  final String timestamp;

  DeleteDependentResponse({
    required this.success,
    required this.message,
    required this.timestamp,
  });
}

class AddDependentResponse {
  final bool success;
  final String message;
  final DependentData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  AddDependentResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory AddDependentResponse.fromJson(Map<String, dynamic> json) {
    return AddDependentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? DependentData.fromJson(json['data'])
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class GetDependentsResponse {
  final bool success;
  final String message;
  final DependentData? self;
  final List<DependentData> dependents;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  GetDependentsResponse({
    required this.success,
    required this.message,
    this.self,
    required this.dependents,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  
  List<DependentData> get data => dependents;

  factory GetDependentsResponse.fromJson(Map<String, dynamic> json) {
    
    DependentData? selfData;
    List<DependentData> dependentsList = [];
    
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      
      
      if (dataMap['self'] != null && dataMap['self'] is Map<String, dynamic>) {
        final selfJson = dataMap['self'] as Map<String, dynamic>;
        
        if (!selfJson.containsKey('relation') || selfJson['relation'] == null) {
          selfJson['relation'] = 'SELF';
        }
        
        if (!selfJson.containsKey('createdAt')) {
          selfJson['createdAt'] = DateTime.now().toIso8601String();
        }
        if (!selfJson.containsKey('updatedAt')) {
          selfJson['updatedAt'] = DateTime.now().toIso8601String();
        }
        selfData = DependentData.fromJson(selfJson);
      }
      
      
      if (dataMap['dependents'] != null && dataMap['dependents'] is List) {
        dependentsList = (dataMap['dependents'] as List)
            .map((item) => DependentData.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    
    return GetDependentsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      self: selfData,
      dependents: dependentsList,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class DependentData {
  final String id;
  final String patientId;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime? dob;
  final String relation;
  final String? phone;
  final String? emailId;
  final String? bloodGroup;
  final int? height;
  final int? weight;
  final String? profilePhoto;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DependentData({
    required this.id,
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dob,
    required this.relation,
    this.phone,
    this.emailId,
    this.bloodGroup,
    this.height,
    this.weight,
    this.profilePhoto,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DependentData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return null;
      }
    }

    return DependentData(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      dob: parseDateTime(json['dob']),
      relation: json['relation']?.toString() ?? '',
      phone: json['phone']?.toString(),
      emailId: json['emailId']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      height: json['height'] is int
          ? json['height']
          : json['height'] != null
              ? int.tryParse(json['height'].toString())
              : null,
      weight: json['weight'] is int
          ? json['weight']
          : json['weight'] != null
              ? int.tryParse(json['weight'].toString())
              : null,
      profilePhoto: json['profilePhoto']?.toString(),
      isActive: json['isActive'] ?? true,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int years = now.year - dob!.year;
    int months = now.month - dob!.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    return '${years}y ${months}m';
  }

  
  String get formattedRelation {
    if (relation.isEmpty) return relation;
    final upperRelation = relation.toUpperCase();
    if (upperRelation == 'SELF') return 'Self';
    if (upperRelation == 'AUNTY') return 'Aunt';  // Convert AUNTY to Aunt for UI
    
    return relation[0].toUpperCase() + relation.substring(1).toLowerCase();
  }

  
  bool get isSelf => relation.toUpperCase() == 'SELF';
}

