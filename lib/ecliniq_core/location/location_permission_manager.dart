

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecliniq/ecliniq_core/location/location_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';


class LocationPermissionManager {
  static const String _keyLocationPermissionAsked = 'location_permission_asked';
  static const String _keyLocationPermissionGranted = 'location_permission_granted';
  static const String _keyLocationPermissionDeniedForever = 'location_permission_denied_forever';

  final LocationService _locationService = LocationService();

  
  static Future<bool> hasAskedForPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyLocationPermissionAsked) ?? false;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> isPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_keyLocationPermissionGranted);
      
      if (stored != null) {
        return stored;
      }
      
      
      final permission = await Geolocator.checkPermission();
      final isGranted = permission == LocationPermission.whileInUse || 
                       permission == LocationPermission.always;
      
      
      await prefs.setBool(_keyLocationPermissionGranted, isGranted);
      
      return isGranted;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> isPermissionDeniedForever() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_keyLocationPermissionDeniedForever);
      
      if (stored != null) {
        return stored;
      }
      
      
      final permission = await Geolocator.checkPermission();
      final isDeniedForever = permission == LocationPermission.deniedForever;
      
      
      await prefs.setBool(_keyLocationPermissionDeniedForever, isDeniedForever);
      
      return isDeniedForever;
    } catch (e) {
      return false;
    }
  }

  
  static Future<LocationPermissionStatus> requestPermissionIfNeeded() async {
    try {
      // Check if permission is already granted
      final currentPermission = await Geolocator.checkPermission();
      
      if (currentPermission == LocationPermission.whileInUse || 
          currentPermission == LocationPermission.always) {
        // Already granted, update storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyLocationPermissionGranted, true);
        return LocationPermissionStatus.granted;
      }

      // Check if permanently denied
      if (currentPermission == LocationPermission.deniedForever) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyLocationPermissionDeniedForever, true);
        return LocationPermissionStatus.deniedForever;
      }

      // Request permission (will prompt user)
      final permission = await Geolocator.requestPermission();
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyLocationPermissionAsked, true);
      
      final isGrantedNow = permission == LocationPermission.whileInUse || 
                          permission == LocationPermission.always;
      final isDeniedForeverNow = permission == LocationPermission.deniedForever;
      
      await prefs.setBool(_keyLocationPermissionGranted, isGrantedNow);
      await prefs.setBool(_keyLocationPermissionDeniedForever, isDeniedForeverNow);
      
      if (isGrantedNow) {
        return LocationPermissionStatus.granted;
      } else if (isDeniedForeverNow) {
        return LocationPermissionStatus.deniedForever;
      } else {
        return LocationPermissionStatus.denied;
      }
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return LocationPermissionStatus.error;
    }
  }

  
  Future<Position?> getCurrentLocationIfGranted() async {
    try {
      final isGranted = await isPermissionGranted();
      if (!isGranted) {
        return null;
      }
      
      final position = await _locationService.getCurrentPosition();
      
      
      if (position != null) {
        final locationName = await _locationService.getLocationName(
          position.latitude,
          position.longitude,
        );
        await LocationStorageService.storeLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: locationName,
        );
      }
      
      return position;
    } catch (e) {
      return null;
    }
  }

  
  static Future<void> resetPermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLocationPermissionAsked);
      await prefs.remove(_keyLocationPermissionGranted);
      await prefs.remove(_keyLocationPermissionDeniedForever);
    } catch (e) {
    }
  }
}


enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  error,
}

