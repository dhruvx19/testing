import 'package:flutter/material.dart';

import '../model/dependent_model.dart';
class AddDependentProvider extends ChangeNotifier {
  // blood group provider
  String _selectedBloodGroup = '';
  String? get selectedBloodGroup => _selectedBloodGroup;
  void selectBloodGroup(String value){
    _selectedBloodGroup = value;
    notifyListeners();
  }
  void clearSection(){
    _selectedBloodGroup = '';
    notifyListeners();
  }
  // gender selection provider
  String? _selectedGender;
 String? get selectedGender => _selectedGender;
  void selectGender(String value){
    _selectedGender = value;
    notifyListeners();
  }
  void clearGender(){
    _selectedGender = null;
    notifyListeners();
  }
  // relation selection provider
  String? _selectedRelation;
  String? get selectedRelation => _selectedRelation;
  void selectRelation(String value){
    _selectedRelation = value;
    notifyListeners();
  }
  void clearRelation(){
    _selectedRelation = null;
    notifyListeners();
  }

  String? _photoUrl;
  String _firstName = '';
  String _lastName = '';
  String? _gender;
  DateTime? _dateOfBirth;
  String? _relation;
  String _contactNumber = '';
  String _email = '';
  String? _bloodGroup;

  bool _isLoading = false;
  String? _errorMessage;


  String? get photoUrl => _photoUrl;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String? get gender => _gender;
  DateTime? get dateOfBirth => _dateOfBirth;
  String? get relation => _relation;
  String get contactNumber => _contactNumber;
  String get email => _email;
  String? get bloodGroup => _bloodGroup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;



  void setPhotoUrl(String? url) {
    _photoUrl = url;
    notifyListeners();
  }

  void setFirstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  void setRelation(String value) {
    _relation = value;
    notifyListeners();
  }

  void setContactNumber(String value) {
    _contactNumber = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setBloodGroup(String value) {
    _bloodGroup = value;
    notifyListeners();
  }


  bool validate() {
    if (_firstName.trim().isEmpty) {
      _errorMessage = 'First name is required';
      notifyListeners();
      return false;
    }
    if (_lastName.trim().isEmpty) {
      _errorMessage = 'Last name is required';
      notifyListeners();
      return false;
    }
    if (_gender == null) {
      _errorMessage = 'Gender is required';
      notifyListeners();
      return false;
    }
    if (_dateOfBirth == null) {
      _errorMessage = 'Date of birth is required';
      notifyListeners();
      return false;
    }
    if (_relation == null) {
      _errorMessage = 'Relation is required';
      notifyListeners();
      return false;
    }
    if (_contactNumber.trim().isEmpty) {
      _errorMessage = 'Contact number is required';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    return true;
  }


  Future<bool> saveDependent() async {
    if (!validate()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {

      await Future.delayed(const Duration(seconds: 1));

      final dependent = DependentModel(
        firstName: _firstName,
        lastName: _lastName,
        gender: _gender!,
        dateOfBirth: _dateOfBirth!,
        relation: _relation!,
        contactNumber: _contactNumber,
        email: _email.isEmpty ? null : _email,
        bloodGroup: _bloodGroup,
        photoUrl: _photoUrl,
      );

      // TODO: Save to API or database
      print('Dependent saved: ${dependent.toJson()}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save dependent: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  void reset() {
    _photoUrl = null;
    _firstName = '';
    _lastName = '';
    _gender = null;
    _dateOfBirth = null;
    _relation = null;
    _contactNumber = '';
    _email = '';
    _bloodGroup = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}