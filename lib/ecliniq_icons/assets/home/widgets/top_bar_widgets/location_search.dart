import 'package:ecliniq/ecliniq_core/location/location_permission_manager.dart';
import 'package:ecliniq/ecliniq_core/location/location_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
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
              horizontal: 10.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.mapPoint.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8.0),
                Text(
                  displayLocation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 10),
                Container(height: 20, width: 0.5, color: Color(0xff96BFFF)),
                const SizedBox(width: 8.0),
                SvgPicture.asset(
                  EcliniqIcons.arrowDown.assetPath,
                  width: 20,
                  height: 20,
                  color: Colors.white,
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(EcliniqIcons.locationSheet.assetPath),
          const SizedBox(height: 4),
          EcliniqText(
            'Please share your location',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xFF424242),
            ),
          ),

          EcliniqText(
            'Enable your location for better services',
            style: EcliniqTextStyles.titleXLarge.copyWith(
              color: Color(0xff626060),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xff8E8E8E)),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Location Manually',
                    style: EcliniqTextStyles.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff424242),
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
        // Add a small delay to ensure bottom sheet is fully rendered
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

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

    // 2. Store location persistently
    await LocationStorageService.storeLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
    );

    // 3. Get providers before popping context
    final hospitalProvider = Provider.of<HospitalProvider>(
      context,
      listen: false,
    );
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

    // 4. Update providers first before closing bottom sheet
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

    // 4. Ensure UI is ready before closing bottom sheet
    await Future.delayed(const Duration(milliseconds: 100));

    // 5. Close bottom sheet safely
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // 6. Fetch data in background (UI will show loading state via providers)
    // Use a small delay to ensure bottom sheet is fully closed
    await Future.delayed(const Duration(milliseconds: 200));

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
