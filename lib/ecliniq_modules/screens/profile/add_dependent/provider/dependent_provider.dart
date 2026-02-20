import 'dart:io';

import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/upload_service.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddDependentProvider extends ChangeNotifier {
  
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

  
  String? _selectedGender;
  String? get selectedGender => _selectedGender ?? _gender;
  void selectGender(String value){
    _selectedGender = value;
    _gender = value; 
    notifyListeners();
  }
  void clearGender(){
    _selectedGender = null;
    _gender = null;
    notifyListeners();
  }

  
  String? _selectedRelation;
  String? get selectedRelation => _selectedRelation ?? _relation;
  void selectRelation(String value){
    _selectedRelation = value;
    _relation = value; 
    notifyListeners();
  }
  void clearRelation(){
    _selectedRelation = null;
    _relation = null;
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
  int? _height;
  int? _weight;
  String? _profilePhotoKey;
  File? _selectedProfilePhoto;
  bool _photoDeleted = false;

  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  final PatientService _patientService = PatientService();
  final UploadService _uploadService = UploadService();

  String? get photoUrl => _photoUrl;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String? get gender => _gender;
  DateTime? get dateOfBirth => _dateOfBirth;
  String? get relation => _relation;
  String get contactNumber => _contactNumber;
  String get email => _email;
  String? get bloodGroup => _bloodGroup;
  int? get height => _height;
  int? get weight => _weight;
  File? get selectedProfilePhoto => _selectedProfilePhoto;
  bool get photoDeleted => _photoDeleted;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;

  
  bool get isFormValid {
    final isValid = _firstName.trim().isNotEmpty &&
        _lastName.trim().isNotEmpty &&
        _gender != null &&
        _dateOfBirth != null &&
        _relation != null &&
        _contactNumber.trim().isNotEmpty &&
        _bloodGroup != null && _bloodGroup!.isNotEmpty;
    
    
    if (!isValid) {
      
      
      
      
      
      
      
    }
    
    return isValid;
  }
  
  
  String getValidationErrorMessage() {
    final errors = <String>[];
    
    if (_firstName.trim().isEmpty) {
      errors.add('First name is required');
    }
    if (_lastName.trim().isEmpty) {
      errors.add('Last name is required');
    }
    if (_gender == null) {
      errors.add('Gender is required');
    }
    if (_dateOfBirth == null) {
      errors.add('Date of birth is required');
    }
    if (_relation == null) {
      errors.add('Relation is required');
    }
    if (_contactNumber.trim().isEmpty) {
      errors.add('Contact number is required');
    }
    if (_bloodGroup == null || _bloodGroup!.isEmpty) {
      errors.add('Blood group is required');
    }

    return errors.isEmpty ? 'Please fill all required fields' : errors.join(', ');
  }

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

  void setHeight(int? value) {
    _height = value;
    notifyListeners();
  }

  void setWeight(int? value) {
    _weight = value;
    notifyListeners();
  }

  void setSelectedProfilePhoto(File? file) {
    _selectedProfilePhoto = file;
    notifyListeners();
  }

  void setPhotoDeleted(bool value) {
    _photoDeleted = value;
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
    if (_bloodGroup == null || _bloodGroup!.isEmpty) {
      _errorMessage = 'Blood group is required';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    return true;
  }

  Future<bool> saveDependent(BuildContext context) async {
    
    if (!validate()) {
      
      return false;
    }
    

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      

      
      
      
      
      if (_selectedProfilePhoto != null) {
        _isUploadingPhoto = true;
        notifyListeners();

        try {
          
          
          _profilePhotoKey = await _uploadService.uploadImageComplete(
            authToken: authToken,
            imageFile: _selectedProfilePhoto!,
          );

          if (_profilePhotoKey == null) {
            
            _errorMessage = 'Failed to upload profile photo';
            _isLoading = false;
            _isUploadingPhoto = false;
            notifyListeners();
            return false;
          }

          
          _isUploadingPhoto = false;
          notifyListeners();
        } catch (e) {
          
          _errorMessage = 'Failed to upload profile photo: $e';
          _isLoading = false;
          _isUploadingPhoto = false;
          notifyListeners();
          return false;
        }
      }

      
      final formattedDob = '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}';

      
      
      
      
      
      
      
      
      
      
      
      
      
      
      final request = AddDependentRequest(
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        dob: formattedDob,
        gender: _gender!.toLowerCase(),
        relation: _mapRelationToApi(_relation!),
        phone: _contactNumber.trim().isNotEmpty ? _contactNumber.trim() : null,
        emailId: _email.trim().isNotEmpty ? _email.trim() : null,
        bloodGroup: _mapBloodGroupToApi(_bloodGroup),
        height: _height,
        weight: _weight,
        profilePhoto: _profilePhotoKey,
      );

      
      
      final response = await _patientService.addDependent(
        authToken: authToken,
        request: request,
      );
      

      if (response.success) {
      _isLoading = false;
        reset();
      notifyListeners();
      return true;
      } else {
        if (response.errors != null) {
          _errorMessage = response.errors.toString();
        } else {
          _errorMessage = response.message;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to save dependent: $e';
      _isLoading = false;
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _photoUrl = null;
    _selectedProfilePhoto = null;
    _profilePhotoKey = null;
    _firstName = '';
    _lastName = '';
    _gender = null;
    _dateOfBirth = null;
    _relation = null;
    _contactNumber = '';
    _email = '';
    _bloodGroup = null;
    _height = null;
    _weight = null;
    _isLoading = false;
    _isUploadingPhoto = false;
    _errorMessage = null;
    _photoDeleted = false;
    notifyListeners();
  }

  
  String? _mapBloodGroupToApi(String? uiValue) {
    if (uiValue == null || uiValue.isEmpty) return null;
    final v = uiValue.toUpperCase();
    const map = {
      'A+': 'A_POSITIVE',
      'A-': 'A_NEGATIVE',
      'B+': 'B_POSITIVE',
      'B-': 'B_NEGATIVE',
      'AB+': 'AB_POSITIVE',
      'AB-': 'AB_NEGATIVE',
      'O+': 'O_POSITIVE',
      'O-': 'O_NEGATIVE',
      'OTHERS': 'OTHERS',
    };
    return map[v];
  }

  
  String _mapRelationToApi(String uiValue) {
    // Handle both UI format and backend format
    if (uiValue == 'Aunt' || uiValue == 'AUNT') {
      return 'AUNTY';
    } else {
      // Convert all other relations to uppercase
      return uiValue.toUpperCase();
    }
  }
}