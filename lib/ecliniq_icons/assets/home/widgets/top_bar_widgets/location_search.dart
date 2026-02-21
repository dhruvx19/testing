import 'package:ecliniq/ecliniq_core/location/location_permission_manager.dart';
import 'package:ecliniq/ecliniq_core/location/location_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/location/select_location_page.dart';
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
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 10.0,
              vertical: 6.0,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.mapPoint.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                  height: EcliniqTextStyles.getResponsiveIconSize(context,  24.0),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  8.0)),
                EcliniqText(
                  displayLocation,
                  style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
                    color: Colors.white,

                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0)),
                Container(
                  height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                  width: 0.5,
                  color: Color(0xff96BFFF),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context,  8.0)),
                SvgPicture.asset(
                  EcliniqIcons.arrowDown.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context,  20.0),
                  height: EcliniqTextStyles.getResponsiveIconSize(context,20.0),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
          bottom: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  16.0)),
        ),
      ),
      width: double.infinity,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context,  16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(EcliniqIcons.locationSheet.assetPath),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  4.0)),
          EcliniqText(
            'Please share your location',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: Color(0xFF424242),
            ),
          ),

          EcliniqText(
            'Setting your location helps us provide better services by finding the best doctors and hospitals near you.',
            textAlign: TextAlign.center,
            style: EcliniqTextStyles.responsiveHeadlineXLMedium(context).copyWith(
              color: Color(0xff626060),
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  18.0)),

          SizedBox(
            width: double.infinity,
            height: EcliniqTextStyles.getResponsiveButtonHeight(context, baseHeight: 52.0),
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
                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                ),
                alignment: Alignment.center,
                child: EcliniqText(
                  'Continue',
                  style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
                    color: Colors.white,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context,  12.0)),

          SizedBox(
             width: double.infinity,
            height: EcliniqTextStyles.getResponsiveButtonHeight(context, baseHeight: 52.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                EcliniqRouter.push(const SelectLocationPage());
              },
              child: Container(
                width: double.infinity,
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  vertical: 12.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff8E8E8E)),
                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context,  4.0)),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EcliniqText(
                      'Enter Location Manually',
                      style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff424242),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLocation() async {
    try {
      
      final isGranted = await LocationPermissionManager.isPermissionGranted();
      if (isGranted) {
        
        
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        final position = await _permissionManager.getCurrentLocationIfGranted();
        if (position != null) {
          await _handleLocationReceived(position);
          return;
        }
      }

      
      final isDeniedForever =
          await LocationPermissionManager.isPermissionDeniedForever();
      if (isDeniedForever) {
        _showSettingsDialog();
        return;
      }

      
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog(
          'Location services are disabled. Please enable them in settings.',
        );
        return;
      }

      
      final permissionStatus =
          await LocationPermissionManager.requestPermissionIfNeeded();

      if (permissionStatus == LocationPermissionStatus.granted) {
        
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
    
    String? locationName;
    try {
      locationName = await _locationService.getLocationName(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      
      locationName = 'Unknown Location';
    }

    if (!mounted) return;

    
    await LocationStorageService.storeLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
    );

    
    final hospitalProvider = Provider.of<HospitalProvider>(
      context,
      listen: false,
    );
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

    
    final lat = position.latitude;
    final lng = position.longitude;
    final locName = locationName;

    
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    
    
    Future.delayed(const Duration(milliseconds: 300), () {
      
      hospitalProvider.setLocation(
        latitude: lat,
        longitude: lng,
        locationName: locName,
      );

      doctorProvider.setLocation(
        latitude: lat,
        longitude: lng,
        locationName: locName,
      );

      
      Future.wait([
        hospitalProvider.fetchTopHospitals(
          latitude: lat,
          longitude: lng,
          isRefresh: true,
        ),
        doctorProvider.fetchTopDoctors(
          latitude: lat,
          longitude: lng,
          isRefresh: true,
        ),
      ]).catchError((e) {
        // Handle the error and return an empty list to satisfy the return type
        return <void>[];
      });
    });
  }

  void _showErrorDialog(String message) {
    setState(() {
      _isButtonPressed = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const EcliniqText('Error'),
        content: EcliniqText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const EcliniqText('OK'),
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
        title: const EcliniqText('Location Permission Required'),
        content: const EcliniqText(
          'Location permission has been permanently denied. Please enable it in app settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const EcliniqText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _locationService.openAppSettings();
              Navigator.of(context).pop();
            },
            child: const EcliniqText('Open Settings'),
          ),
        ],
      ),
    );
  }
}
