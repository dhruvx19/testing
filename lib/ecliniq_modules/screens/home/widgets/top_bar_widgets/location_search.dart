import 'package:ecliniq/ecliniq_core/location/location_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_permission_manager.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class LocationSelectorWidget extends StatelessWidget {
  final String currentLocation;
  final VoidCallback? onLocationTap;

  const LocationSelectorWidget({
    super.key,
    required this.currentLocation,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HospitalProvider>(
      builder: (context, hospitalProvider, child) {
        final displayLocation =
            hospitalProvider.currentLocationName ?? currentLocation;

        return GestureDetector(
          onTap: onLocationTap ?? () => _showLocationBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.map.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8.0),
                Text(
                  displayLocation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 10),
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 8.0),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20.0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationBottomSheet(BuildContext context) {
    EcliniqBottomSheet.show(
      context: context,
      child: LocationBottomSheet(currentLocation: currentLocation),
    );
  }
}

class LocationBottomSheet extends StatefulWidget {
  final String currentLocation;

  const LocationBottomSheet({super.key, required this.currentLocation});

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  final LocationService _locationService = LocationService();
  final LocationPermissionManager _permissionManager =
      LocationPermissionManager();
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 40,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 24),
          EcliniqText(
            'Please share your location',
            style: EcliniqTextStyles.titleXLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          EcliniqText(
            'Enable your location for better services',
            style: EcliniqTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isButtonPressed = true;
                });
                _enableLocation();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isButtonPressed
                      ? const Color(0xFF0E4395)
                      : const Color(0xFF2372EC),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Enable Device Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Location Manually',
                    style: EcliniqTextStyles.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLocation() async {
    try {
      // Check if permission is already granted
      final isGranted = await LocationPermissionManager.isPermissionGranted();
      if (isGranted) {
        // Permission already granted, get location directly
        final position = await _permissionManager.getCurrentLocationIfGranted();
        if (position != null) {
          await _handleLocationReceived(position);
          return;
        }
      }

      // Check if permission was denied forever
      final isDeniedForever =
          await LocationPermissionManager.isPermissionDeniedForever();
      if (isDeniedForever) {
        _showSettingsDialog();
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog(
          'Location services are disabled. Please enable them in settings.',
        );
        return;
      }

      // Request permission if needed
      final permissionStatus =
          await LocationPermissionManager.requestPermissionIfNeeded();

      if (permissionStatus == LocationPermissionStatus.granted) {
        // Permission granted, get location
        final position = await _permissionManager.getCurrentLocationIfGranted();
        if (position != null) {
          await _handleLocationReceived(position);
        } else {
          _showErrorDialog(
            'Unable to get your current location. Please try again.',
          );
        }
      } else if (permissionStatus == LocationPermissionStatus.deniedForever) {
        _showSettingsDialog();
      } else if (permissionStatus == LocationPermissionStatus.denied) {
        _showErrorDialog(
          'Location permission denied. Please enable location permission to continue.',
        );
      } else {
        _showErrorDialog(
          'Error requesting location permission. Please try again.',
        );
      }
    } catch (e) {
      _showErrorDialog('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonPressed = false;
        });
      }
    }
  }

  Future<void> _handleLocationReceived(Position position) async {
    // 1. Get location name first
    String? locationName;
    try {
      locationName = await _locationService.getLocationName(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting location name: $e');
      locationName = 'Unknown Location';
    }

    if (!mounted) return;

    // 2. Get providers before popping context
    final hospitalProvider = Provider.of<HospitalProvider>(
      context,
      listen: false,
    );
    final doctorProvider = Provider.of<DoctorProvider>(
      context,
      listen: false,
    );

    // 3. Close bottom sheet immediately
    Navigator.of(context).pop();

    // 4. Update providers
    hospitalProvider.setLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
    );

    doctorProvider.setLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
    );

    // 4. Fetch data in background (UI will show loading state via providers)
    try {
      await Future.wait([
        hospitalProvider.fetchTopHospitals(
          latitude: position.latitude,
          longitude: position.longitude,
          isRefresh: true,
        ),
        doctorProvider.fetchTopDoctors(
          latitude: position.latitude,
          longitude: position.longitude,
          isRefresh: true,
        ),
      ]);
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _showErrorDialog(String message) {
    setState(() {
      _isButtonPressed = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    setState(() {
      _isButtonPressed = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission has been permanently denied. Please enable it in app settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _locationService.openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
