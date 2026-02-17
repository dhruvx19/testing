import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:flutter/material.dart';

class HospitalProvider with ChangeNotifier {
  final HospitalService _hospitalService = HospitalService();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<Hospital> _hospitals = [];
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentLocationName;


  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<Hospital> get hospitals => _hospitals;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get currentLocationName => _currentLocationName;
  bool get hasHospitals => _hospitals.isNotEmpty;
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


  Future<void> fetchTopHospitals({
    required double latitude,
    required double longitude,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    
    _errorMessage = null;
    notifyListeners();

    try {
      
      final double requestLat = latitude;
      final double requestLong = longitude;

      final response = await _hospitalService.getTopHospitals(
        latitude: requestLat,
        longitude: requestLong,
      );

      if (response.success) {
        if (isRefresh) {
          _hospitals = response.data;
        } else {
          _hospitals.addAll(response.data);
        }
        

        setLocation(
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch hospitals: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }


  Future<void> refreshHospitals() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await fetchTopHospitals(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        isRefresh: true,
      );
    }
  }


  void clearData() {
    _hospitals.clear();
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }


  Future<void> retry() async {
    if (_currentLatitude != null && _currentLongitude != null) {
      await fetchTopHospitals(
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        isRefresh: true,
      );
    }
  }
}
