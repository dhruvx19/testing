


class HospitalDetails {
  final String name;
  final String imageUrl;
  final String specialty;
  final String doctorCount;
  final String establishedYear;
  final String yearsOfExperience;
  final String location;
  final String distance;
  final String patientsServed;
  final String totalDoctors;
  final String totalBeds;
  final AppointmentTiming appointmentTiming;
  final Address address;
  final String about;
  final List<String> medicalSpecialties;
  final List<String> services;
  final List<String> certificates;
  final ContactDetails contactDetails;
  final List<ContactNumber> contactNumbers;

  HospitalDetails({
    required this.name,
    required this.imageUrl,
    required this.specialty,
    required this.doctorCount,
    required this.establishedYear,
    required this.yearsOfExperience,
    required this.location,
    required this.distance,
    required this.patientsServed,
    required this.totalDoctors,
    required this.totalBeds,
    required this.appointmentTiming,
    required this.address,
    required this.about,
    required this.medicalSpecialties,
    required this.services,
    required this.certificates,
    required this.contactDetails,
    required this.contactNumbers,
  });

  factory HospitalDetails.fromJson(Map<String, dynamic> json) {
    return HospitalDetails(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      specialty: json['specialty'] ?? '',
      doctorCount: json['doctorCount'] ?? '',
      establishedYear: json['establishedYear'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? '',
      location: json['location'] ?? '',
      distance: json['distance'] ?? '',
      patientsServed: json['patientsServed'] ?? '',
      totalDoctors: json['totalDoctors'] ?? '',
      totalBeds: json['totalBeds'] ?? '',
      appointmentTiming: AppointmentTiming.fromJson(json['appointmentTiming'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
      about: json['about'] ?? '',
      medicalSpecialties: List<String>.from(json['medicalSpecialties'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      certificates: List<String>.from(json['certificates'] ?? []),
      contactDetails: ContactDetails.fromJson(json['contactDetails'] ?? {}),
      contactNumbers: (json['contactNumbers'] as List?)
              ?.map((e) => ContactNumber.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AppointmentTiming {
  final String time;
  final String days;

  AppointmentTiming({required this.time, required this.days});

  factory AppointmentTiming.fromJson(Map<String, dynamic> json) {
    return AppointmentTiming(
      time: json['time'] ?? '',
      days: json['days'] ?? '',
    );
  }
}

class Address {
  final String full;
  final String mapUrl;

  Address({required this.full, required this.mapUrl});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      full: json['full'] ?? '',
      mapUrl: json['mapUrl'] ?? '',
    );
  }
}

class ContactDetails {
  final String email;
  final String emailLabel;

  ContactDetails({required this.email, required this.emailLabel});

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      email: json['email'] ?? '',
      emailLabel: json['emailLabel'] ?? '',
    );
  }
}

class ContactNumber {
  final String number;
  final String label;
  final String icon;

  ContactNumber({
    required this.number,
    required this.label,
    required this.icon,
  });

  factory ContactNumber.fromJson(Map<String, dynamic> json) {
    return ContactNumber(
      number: json['number'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? 'phone',
    );
  }
}
