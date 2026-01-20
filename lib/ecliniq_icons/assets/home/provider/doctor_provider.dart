import 'dart:convert';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api;
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_api/top_doctor_model.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
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

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<Doctor>? get doctors => _doctors;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get currentLocationName => _currentLocationName;
  bool get hasDoctors => _doctors != null && _doctors!.isNotEmpty;
  bool get hasLocation => _currentLatitude != null && _currentLongitude != null;

  // Set location
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

  // Clear location
  void clearLocation() {
    _currentLatitude = null;
    _currentLongitude = null;
    _currentLocationName = null;
    notifyListeners();
  }

  // Fetch top doctors
  Future<void> fetchTopDoctors({
    required double latitude,
    required double longitude,
    bool isRefresh = false,
  }) async {
    // Prevent duplicate calls if already loading
    if (_isLoading || _isLoadingMore) {
      debugPrint('Already loading doctors, skipping duplicate call');
      return;
    }

    if (isRefresh) {
      _isLoading = true;
      // Only clear existing doctors if we're explicitly refreshing
      // Don't clear if we already have doctors and this might be a duplicate call
      if (_doctors == null || _doctors!.isEmpty) {
        _doctors = null;
      }
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔍 fetchTopDoctors called - lat: $latitude, lng: $longitude, isRefresh: $isRefresh');
      debugPrint('🔍 Current doctors count: ${_doctors?.length ?? 0}');
      
      // Use provided coordinates (user's actual location)
      final double requestLat = latitude;
      final double requestLong = longitude;
      
      // Fetch directly to parse with UI model
      final url = Uri.parse(Endpoints.topDoctors);
      // Hardcoded latitude and longitude
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
        debugPrint('API Response status: ${httpResponse.statusCode}');
        debugPrint('API Response body length: ${httpResponse.body.length}');
        
        final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final success = responseData['success'] ?? false;
        final message = responseData['message'] ?? '';
        
        debugPrint('API Response success: $success, message: $message');

        if (success) {
          try {
            // Parse doctors using UI model to get all fields (hospital, clinic, distanceKm, etc.)
            final doctorsData = responseData['data'] as List<dynamic>? ?? [];
            debugPrint('Parsing ${doctorsData.length} doctors from API response');
            
            final uiDoctors = <Doctor>[];
            for (var item in doctorsData) {
              try {
                final doctorJson = item as Map<String, dynamic>;
                final doctor = Doctor.fromJson(doctorJson);
                uiDoctors.add(doctor);
                debugPrint('Successfully parsed doctor: ${doctor.name}, hasLocations: ${doctor.hasLocations}');
              } catch (e, stackTrace) {
                debugPrint('Error parsing individual doctor: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint('Doctor JSON: $item');
                // Continue parsing other doctors even if one fails
              }
            }

            debugPrint('Successfully parsed ${uiDoctors.length} doctors');

            // Update doctors list
            if (isRefresh) {
              // On refresh, only update if we got doctors, or if we explicitly want to clear
              // Don't overwrite existing doctors with empty list unless it's a real empty response
              if (uiDoctors.isNotEmpty) {
                _doctors = uiDoctors;
              } else if (_doctors == null || _doctors!.isEmpty) {
                // Only set empty list if we didn't have doctors before
                _doctors = uiDoctors;
                debugPrint('Refresh returned 0 doctors - clearing list');
              } else {
                debugPrint('Refresh returned 0 doctors but keeping existing ${_doctors!.length} doctors');
              }
            } else {
              // For pagination/load more, append to existing list
              _doctors = [...?_doctors, ...uiDoctors];
            }

            // Update location
            setLocation(
              latitude: latitude,
              longitude: longitude,
            );
          } catch (parseError, stackTrace) {
            debugPrint('Error parsing doctors data: $parseError');
            debugPrint('Stack trace: $stackTrace');
            debugPrint('Response data: $responseData');
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
      debugPrint('Error fetching top doctors: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Refresh doctors with current location
  Future<void> refreshDoctors() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await fetchTopDoctors(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        isRefresh: true,
      );
    }
  }

  // Retry fetching doctors
  Future<void> retry() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await fetchTopDoctors(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        isRefresh: true,
      );
    }
  }

  // Clear all data
  void clearData() {
    _doctors = null;
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }
}