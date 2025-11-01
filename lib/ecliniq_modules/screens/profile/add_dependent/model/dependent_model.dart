class DependentModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime dateOfBirth;
  final String relation;
  final String contactNumber;
  final String? email;
  final String? bloodGroup;
  final String? photoUrl;

  DependentModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.relation,
    required this.contactNumber,
    this.email,
    this.bloodGroup,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'relation': relation,
      'contactNumber': contactNumber,
      'email': email,
      'bloodGroup': bloodGroup,
      'photoUrl': photoUrl,
    };
  }

  factory DependentModel.fromJson(Map<String, dynamic> json) {
    return DependentModel(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      gender: json['gender'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      relation: json['relation'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      bloodGroup: json['bloodGroup'],
      photoUrl: json['photoUrl'],
    );
  }

  DependentModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? relation,
    String? contactNumber,
    String? email,
    String? bloodGroup,
    String? photoUrl,
  }) {
    return DependentModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      relation: relation ?? this.relation,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}