import 'dart:convert';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api;
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_api/top_doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorProvider with ChangeNotifier {

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<Doctor>? _doctors;
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentLocationName;

  
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<Doctor>? get doctors => _doctors;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get currentLocationName => _currentLocationName;
  bool get hasDoctors => _doctors != null && _doctors!.isNotEmpty;
  bool get hasLocation => _currentLatitude != null && _currentLongitude != null;

  
  void setLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    if (locationName != null) {
      _currentLocationName = locationName;
    }
    notifyListeners();
  }

  
  void clearLocation() {
    _currentLatitude = null;
    _currentLongitude = null;
    _currentLocationName = null;
    notifyListeners();
  }

  
  Future<void> fetchTopDoctors({
    required double latitude,
    required double longitude,
    bool isRefresh = false,
  }) async {
    
    if (_isLoading || _isLoadingMore) {
      
      return;
    }

    if (isRefresh) {
      _isLoading = true;
      
      
      if (_doctors == null || _doctors!.isEmpty) {
        _doctors = null;
      }
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      
      
      
      
      final double requestLat = latitude;
      final double requestLong = longitude;
      
      
      final url = Uri.parse(Endpoints.topDoctors);
      
      final requestBody = api.TopDoctorsRequest(
        latitude: 12.9173,
        longitude: 77.6377,
      );

      final httpResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody.toJson()),
      );

      if (httpResponse.statusCode == 200) {
        
        
        
        final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final success = responseData['success'] ?? false;
        final message = responseData['message'] ?? '';
        
        

        if (success) {
          try {
            
            final doctorsData = responseData['data'] as List<dynamic>? ?? [];
            
            
            final uiDoctors = <Doctor>[];
            for (var item in doctorsData) {
              try {
                final doctorJson = item as Map<String, dynamic>;
                final doctor = Doctor.fromJson(doctorJson);
                uiDoctors.add(doctor);
                
              } catch (e) {
                
                
                
                
              }
            }

            

            
            if (isRefresh) {
              
              
              if (uiDoctors.isNotEmpty) {
                _doctors = uiDoctors;
              } else if (_doctors == null || _doctors!.isEmpty) {
                
                _doctors = uiDoctors;
                
              } else {
                
              }
            } else {
              
              _doctors = [...?_doctors, ...uiDoctors];
            }

            
            setLocation(
              latitude: latitude,
              longitude: longitude,
            );
          } catch (parseError) {
            
            
            
            _errorMessage = 'Failed to parse doctors data: $parseError';
          }
        } else {
          _errorMessage = message;
        }
      } else {
        _errorMessage = 'Failed to fetch doctors: ${httpResponse.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch doctors: $e';
      
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  
  Future<void> refreshDoctors() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await fetchTopDoctors(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        isRefresh: true,
      );
    }
  }

  
  Future<void> retry() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await fetchTopDoctors(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        isRefresh: true,
      );
    }
  }

  
  void clearData() {
    _doctors = null;
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }
}