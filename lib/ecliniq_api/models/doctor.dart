import 'package:ecliniq/ecliniq_api/storage_service.dart';

class Doctor {
  final String id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;
  final String? headline;
  final String? gender;
  final double? rating;
  final List<String> specializations;
  final List<String> qualifications;
  final int? experience;
  final List<String>? languages;
  final String? practiceArea;
  final double? fee;
  final double? distance;
  final String? availability;
  final List<DoctorHospital> hospitals;
  final List<DoctorClinic> clinics;
  final bool isFavourite;
  final double? serviceFee;

  
  List<String> get degreeTypes => qualifications;
  int? get yearOfExperience => experience;
  String get primarySpecialization =>
      specializations.isNotEmpty ? specializations.first : '';
  String get educationText => qualifications.join(', ');
  String get ratingText => rating?.toString() ?? '0.0';
  String get experienceText =>
      experience != null ? '$experience years exp.' : '';
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '';
  bool get hasLocations => hospitals.isNotEmpty || clinics.isNotEmpty;

  Doctor({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.profilePhoto,
    this.headline,
    this.gender,
    this.rating,
    required this.specializations,
    required this.qualifications,
    this.experience,
    this.languages,
    this.practiceArea,
    this.fee,
    this.distance,
    this.availability,
    required this.hospitals,
    required this.clinics,
    this.isFavourite = false,
    this.serviceFee,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    double? parseNumeric(dynamic value) {
      if (value == null) return null;
      if (value is String) return double.tryParse(value);
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    String? parsePracticeArea(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) {
        if (value.isEmpty) return null;
        return value.map((e) => e.toString()).join(', ');
      }
      return value.toString();
    }

    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      profilePhoto: json['profilePhoto'],
      headline: json['headline'],
      gender: json['gender'],
      rating: parseNumeric(json['rating']),
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      qualifications: (json['qualifications'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          (json['degreeTypes'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      experience: json['experience'] ?? json['yearOfExperience'],
      languages: (json['languages'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      practiceArea: parsePracticeArea(json['practiceArea']),
      fee: parseNumeric(json['fee']),
      distance: parseNumeric(json['distance']),
      availability: json['availability'],
      hospitals: (json['hospitals'] as List<dynamic>?)
              ?.map((item) => DoctorHospital.fromJson(item))
              .toList() ??
          (json['doctorHospitals'] as List<dynamic>?)
              ?.map((item) => DoctorHospital.fromJson(item))
              .toList() ??
          [],
      clinics: (json['clinics'] as List<dynamic>?)
              ?.map((item) => DoctorClinic.fromJson(item))
              .toList() ??
          (json['clinicDetails'] != null && json['clinicDetails'] is Map
              ? [DoctorClinic.fromJson(json['clinicDetails'])]
              : []),
      isFavourite: json['isFavourite'] ?? false,
      serviceFee: parseNumeric(json['serviceFee']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'profilePhoto': profilePhoto,
      'headline': headline,
      'gender': gender,
      'rating': rating,
      'specializations': specializations,
      'qualifications': qualifications,
      'experience': experience,
      'languages': languages,
      'practiceArea': practiceArea,
      'fee': fee,
      'distance': distance,
      'availability': availability,
      'hospitals': hospitals.map((e) => e.toJson()).toList(),
      'clinics': clinics.map((e) => e.toJson()).toList(),
      'isFavourite': isFavourite,
      'serviceFee': serviceFee,
    };
  }

  
  
  
  
  
  
  
  
  
  
  Future<String?> getProfilePhotoUrl(StorageService storageService) async {
    if (profilePhoto == null || profilePhoto!.isEmpty) {
      return null;
    }
    
    if (profilePhoto!.startsWith('http://') || profilePhoto!.startsWith('https://')) {
      return profilePhoto;
    }
    
    if (profilePhoto!.startsWith('public/')) {
      return await storageService.getPublicUrl(profilePhoto);
    }
    return null;
  }
}

class DoctorHospital {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final double? consultationFee;
  final double? distance;

  DoctorHospital({
    required this.id,
    required this.name,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.consultationFee,
    this.distance,
  });

  factory DoctorHospital.fromJson(Map<String, dynamic> json) {
    double? parseNumeric(dynamic value) {
      if (value == null) return null;
      if (value is String) return double.tryParse(value);
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return DoctorHospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      state: json['state'],
      latitude: parseNumeric(json['latitude']),
      longitude: parseNumeric(json['longitude']),
      consultationFee: parseNumeric(json['consultationFee']),
      distance: parseNumeric(json['distance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'consultationFee': consultationFee,
      'distance': distance,
    };
  }
}

class DoctorClinic {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final double? consultationFee;
  final double? distance;

  DoctorClinic({
    required this.id,
    required this.name,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.consultationFee,
    this.distance,
  });

  factory DoctorClinic.fromJson(Map<String, dynamic> json) {
    double? parseNumeric(dynamic value) {
      if (value == null) return null;
      if (value is String) return double.tryParse(value);
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return DoctorClinic(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      state: json['state'],
      latitude: parseNumeric(json['latitude']),
      longitude: parseNumeric(json['longitude']),
      consultationFee: parseNumeric(json['consultationFee']),
      distance: parseNumeric(json['distance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'consultationFee': consultationFee,
      'distance': distance,
    };
  }
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

class FilterDoctorsRequest {
  final double latitude;
  final double longitude;
  final String? city;
  final double? distance;
  final String? workExperience;
  final List<String>? practiceArea;
  final List<String>? speciality;
  final String? availability;
  final String? date;
  final String? gender;
  final List<String>? languages;
  final int page;
  final int limit;

  FilterDoctorsRequest({
    required this.latitude,
    required this.longitude,
    this.city,
    this.distance,
    this.workExperience,
    this.practiceArea,
    this.speciality,
    this.availability,
    this.date,
    this.gender,
    this.languages,
    this.page = 1,
    this.limit = 50,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (city != null) 'city': city,
      if (distance != null) 'distance': distance,
      if (workExperience != null) 'workExperience': workExperience,
      if (practiceArea != null) 'practiceArea': practiceArea,
      if (speciality != null) 'speciality': speciality,
      if (availability != null) 'availability': availability,
      if (date != null) 'date': date,
      if (gender != null) 'gender': gender,
      if (languages != null) 'languages': languages,
      'page': page,
      'limit': limit,
    };
  }
}

class FilterDoctorsResponse {
  final bool success;
  final String message;
  final FilterDocsData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  FilterDoctorsResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory FilterDoctorsResponse.fromJson(Map<String, dynamic> json) {
    return FilterDoctorsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? FilterDocsData.fromJson(json['data']) : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class FilterDocsData {
  final List<Doctor> doctors;
  final Pagination pagination;

  FilterDocsData({
    required this.doctors,
    required this.pagination,
  });

  factory FilterDocsData.fromJson(Map<String, dynamic> json) {
    return FilterDocsData(
      doctors: (json['data'] as List<dynamic>?)
              ?.map((item) => Doctor.fromJson(item))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
    );
  }
}


class ClinicDetails {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? contactEmail;
  final String? contactNumber;
  final List<String>? photos;
  final String? image;
  final String? about;

  ClinicDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.contactEmail,
    this.contactNumber,
    this.photos,
    this.image,
    this.about,
  });

  factory ClinicDetails.fromJson(Map<String, dynamic> json) {
    return ClinicDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      contactEmail: json['contactEmail'],
      contactNumber: json['contactNumber'],
      photos: (json['photos'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      image: json['image'],
      about: json['about'],
    );
  }
}

class ContactDetails {
  final String? email;
  final String? phone;
  final List<String>? languages;

  ContactDetails({
    this.email,
    this.phone,
    this.languages,
  });

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      email: json['email'],
      phone: json['phone'],
      languages: (json['languages'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
    );
  }
}

class ProfessionalInformation {
  final String? registrationCouncil;
  final String? registrationNumber;
  final String? registrationYear;
  final List<SpecializationInfo>? specializations;
  final List<String>? symptoms;

  ProfessionalInformation({
    this.registrationCouncil,
    this.registrationNumber,
    this.registrationYear,
    this.specializations,
    this.symptoms,
  });

  factory ProfessionalInformation.fromJson(Map<String, dynamic> json) {
    return ProfessionalInformation(
      registrationCouncil: json['registrationCouncil'],
      registrationNumber: json['registrationNumber'],
      registrationYear: json['registrationYear'],
      specializations: (json['specializations'] as List<dynamic>?)
          ?.map((item) => SpecializationInfo.fromJson(item))
          .toList(),
      symptoms: (json['symptoms'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
    );
  }
}

class SpecializationInfo {
  final String name;
  final int expYears;

  SpecializationInfo({
    required this.name,
    required this.expYears,
  });

  factory SpecializationInfo.fromJson(Map<String, dynamic> json) {
    return SpecializationInfo(
      name: json['name'] ?? '',
      expYears: json['expYears'] ?? 0,
    );
  }
}

class EducationalInformation {
  final String id;
  final String instituteName;
  final String graduationType;
  final String degree;
  final String? fieldOfStudy;
  final int startYear;
  final int completionYear;

  EducationalInformation({
    required this.id,
    required this.instituteName,
    required this.graduationType,
    required this.degree,
    this.fieldOfStudy,
    required this.startYear,
    required this.completionYear,
  });

  factory EducationalInformation.fromJson(Map<String, dynamic> json) {
    return EducationalInformation(
      id: json['id'] ?? '',
      instituteName: json['instituteName'] ?? '',
      graduationType: json['graduationType'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'],
      startYear: json['startYear'] ?? 0,
      completionYear: json['completionYear'] ?? 0,
    );
  }
}

class CertificateAndAccreditation {
  final String id;
  final String name;
  final String issuer;
  final String? associatedWith;
  final String? issueDate;
  final String? url;
  final String? description;

  CertificateAndAccreditation({
    required this.id,
    required this.name,
    required this.issuer,
    this.associatedWith,
    this.issueDate,
    this.url,
    this.description,
  });

  factory CertificateAndAccreditation.fromJson(Map<String, dynamic> json) {
    return CertificateAndAccreditation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      associatedWith: json['associatedWith'],
      issueDate: json['issueDate'],
      url: json['url'],
      description: json['description'],
    );
  }
}

class Experience {
  final String id;
  final String jobTitle;
  final String employmentType;
  final String hospitalOrClinicName;
  final bool isCurrentlyWorking;
  final String? startDate;
  final String? endDate;
  final String? description;

  Experience({
    required this.id,
    required this.jobTitle,
    required this.employmentType,
    required this.hospitalOrClinicName,
    required this.isCurrentlyWorking,
    this.startDate,
    this.endDate,
    this.description,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      employmentType: json['employmentType'] ?? '',
      hospitalOrClinicName: json['hospitalOrClinicName'] ?? '',
      isCurrentlyWorking: json['isCurrentlyWorking'] ?? false,
      startDate: json['startDate'],
      endDate: json['endDate'],
      description: json['description'],
    );
  }
}

class Publication {
  final String id;
  final String title;
  final String? publisher;
  final String? publicationDate;
  final String? url;
  final String? description;

  Publication({
    required this.id,
    required this.title,
    this.publisher,
    this.publicationDate,
    this.url,
    this.description,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      publisher: json['publisher'],
      publicationDate: json['publicationDate'],
      url: json['url'],
      description: json['description'],
    );
  }
}

class DoctorDetails {
  final String userId;
  final String name;
  final String? profilePhoto;
  final String? headline;
  final String? about;
  final List<String>? specializations;
  final ClinicDetails? clinicDetails;
  final List<dynamic>? doctorHospitals;
  final int? workExperience;
  final int? patientsServed;
  final double? rating;
  final int? currentTokenNumber;
  final ContactDetails? contactDetails;
  final ProfessionalInformation? professionalInformation;
  final List<EducationalInformation>? educationalInformation;
  final List<CertificateAndAccreditation>? certificatesAndAccreditations;
  final List<Experience>? experiences;
  final List<Publication>? publications;
  final bool isFavourite;

  DoctorDetails({
    required this.userId,
    required this.name,
    this.profilePhoto,
    this.headline,
    this.about,
    this.specializations,
    this.clinicDetails,
    this.doctorHospitals,
    this.workExperience,
    this.patientsServed,
    this.rating,
    this.currentTokenNumber,
    this.contactDetails,
    this.professionalInformation,
    this.educationalInformation,
    this.certificatesAndAccreditations,
    this.experiences,
    this.publications,
    this.isFavourite = false,
  });

  factory DoctorDetails.fromJson(Map<String, dynamic> json) {
    return DoctorDetails(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      profilePhoto: json['profilePhoto'],
      headline: json['headline'],
      about: json['about'],
      specializations: (json['specializations'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      clinicDetails: json['clinicDetails'] != null
          ? ClinicDetails.fromJson(json['clinicDetails'])
          : null,
      doctorHospitals: json['doctorHospitals'],
      workExperience: json['workExperience'],
      patientsServed: json['patientsServed'],
      rating: json['rating'] != null
          ? (json['rating'] is String
              ? double.tryParse(json['rating'] as String)
              : json['rating'] is int
                  ? (json['rating'] as int).toDouble()
                  : json['rating'] is double
                      ? json['rating'] as double
                      : json['rating'] is num
                          ? (json['rating'] as num).toDouble()
                          : double.tryParse(json['rating'].toString()))
          : null,
      currentTokenNumber: json['currentTokenNumber'],
      contactDetails: json['contactDetails'] != null
          ? ContactDetails.fromJson(json['contactDetails'])
          : null,
      professionalInformation: json['professionalInformation'] != null
          ? ProfessionalInformation.fromJson(json['professionalInformation'])
          : null,
      educationalInformation:
          (json['educationalInformation'] as List<dynamic>?)
              ?.map((item) => EducationalInformation.fromJson(item))
              .toList(),
      certificatesAndAccreditations:
          (json['certificatesAndAccreditations'] as List<dynamic>?)
              ?.map((item) => CertificateAndAccreditation.fromJson(item))
              .toList(),
      experiences: (json['experiences'] as List<dynamic>?)
          ?.map((item) => Experience.fromJson(item))
          .toList(),
      publications: (json['publications'] as List<dynamic>?)
          ?.map((item) => Publication.fromJson(item))
          .toList(),
      isFavourite: json['isFavourite'] ?? false,
    );
  }

  
  
  
  
  
  
  
  
  
  
  Future<String?> getProfilePhotoUrl(StorageService storageService) async {
    if (profilePhoto == null || profilePhoto!.isEmpty) {
      return null;
    }
    
    if (profilePhoto!.startsWith('http://') || profilePhoto!.startsWith('https://')) {
      return profilePhoto;
    }
    
    if (profilePhoto!.startsWith('public/')) {
      return await storageService.getPublicUrl(profilePhoto);
    }
    return null;
  }
}

class DoctorDetailsResponse {
  final bool success;
  final String message;
  final DoctorDetails? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  DoctorDetailsResponse({
    required this.success,
    required this.message,
    this.data,
    required this.errors,
    required this.meta,
    required this.timestamp,
  });

  factory DoctorDetailsResponse.fromJson(Map<String, dynamic> json) {
    return DoctorDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? DoctorDetails.fromJson(json['data'])
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}
