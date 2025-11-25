import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicLocationCard extends StatefulWidget {
  final String? hospitalId;
  final String? clinicId;
  final String? locationName;
  final String? locationAddress;

  const ClinicLocationCard({
    super.key,
    this.hospitalId,
    this.clinicId,
    this.locationName,
    this.locationAddress,
  }) : assert(
          hospitalId != null || clinicId != null,
          'Either hospitalId or clinicId must be provided',
        );

  @override
  State<ClinicLocationCard> createState() => _ClinicLocationCardState();
}

class _ClinicLocationCardState extends State<ClinicLocationCard> {
  final HospitalService _hospitalService = HospitalService();
  HospitalDetail? _hospitalDetail;
  bool _isLoading = true;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    if (widget.hospitalId != null) {
      _fetchHospitalDetails();
      _getUserLocationAndCalculateDistance();
    } else {
      // For clinics, we don't fetch details, just mark as loaded
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHospitalDetails() async {
    if (widget.hospitalId == null) return;
    
    try {
      final response = await _hospitalService.getHospitalDetails(
        hospitalId: widget.hospitalId!,
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _hospitalDetail = response.data;
            // Calculate distance if we have both user position and hospital location
            if (_userPosition != null) {
              _calculateDistance();
            }
          } else {
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserLocationAndCalculateDistance() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _userPosition = null;
          });
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _userPosition = null;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _userPosition = null;
          });
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userPosition = position;
        });
        // Calculate distance if we have hospital details
        if (_hospitalDetail != null) {
          _calculateDistance();
        }
      }
    } catch (e) {
      // Silently fail - we'll just not show distance
      if (mounted) {
        setState(() {
          _userPosition = null;
        });
      }
    }
  }

  void _calculateDistance() {
    if (_userPosition != null && _hospitalDetail != null) {
      Geolocator.distanceBetween(
        _userPosition!.latitude,
        _userPosition!.longitude,
        _hospitalDetail!.latitude,
        _hospitalDetail!.longitude,
      );

      setState(() {
// Convert to kilometers
      });
    }
  }

  Future<void> _openMapsDirections() async {
    if (_hospitalDetail == null) return;

    final lat = _hospitalDetail!.latitude;
    final lng = _hospitalDetail!.longitude;

    // Try Google Maps first
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    // Try Apple Maps (will fall back to web on Android)
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng',
    );

    try {
      bool canLaunchGoogle = false;
      bool canLaunchApple = false;

      // Safely check if URLs can be launched
      try {
        canLaunchGoogle = await canLaunchUrl(googleMapsUrl);
      } catch (e) {
        // If canLaunchUrl fails, try to launch directly anyway
        canLaunchGoogle = false;
      }

      try {
        canLaunchApple = await canLaunchUrl(appleMapsUrl);
      } catch (e) {
        // If canLaunchUrl fails, try to launch directly anyway
        canLaunchApple = false;
      }

      // Try to launch Google Maps
      if (canLaunchGoogle) {
        try {
          await launchUrl(
            googleMapsUrl,
            mode: LaunchMode.externalApplication,
          );
          return; // Successfully launched, exit
        } catch (e) {
          // Continue to next option if Google Maps fails
        }
      }

      // Try to launch Apple Maps
      if (canLaunchApple) {
        try {
          await launchUrl(
            appleMapsUrl,
            mode: LaunchMode.externalApplication,
          );
          return; // Successfully launched, exit
        } catch (e) {
          // Continue to web fallback if Apple Maps fails
        }
      }

      // Fall back to web browser with Google Maps
      final webMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      try {
        await launchUrl(
          webMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // If all methods fail, try launching without checking first
        // This works around iOS platform channel issues
        try {
          await launchUrl(
            googleMapsUrl,
            mode: LaunchMode.externalApplication,
          );
        } catch (finalLaunchError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open maps app. Please try again or search for the location manually.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Silent fail - don't show error to user unless all methods fail
      // The error handling above already shows a user-friendly message
    }
  }

  String _getHospitalAddress() {
    if (widget.locationAddress != null && widget.locationAddress!.isNotEmpty) {
      return widget.locationAddress!;
    }

    if (widget.clinicId != null) {
      // For clinics, return a generic message
      return 'Clinic location details';
    }
    
    if (_hospitalDetail == null) {
      return 'Loading...';
    }

    final parts = <String>[];
    final address = _hospitalDetail!.address;
    
    if (address.street != null && address.street!.isNotEmpty) {
      parts.add(address.street!);
    }
    if (address.blockNo != null && address.blockNo!.isNotEmpty) {
      parts.add(address.blockNo!);
    }
    if (_hospitalDetail!.city.isNotEmpty) {
      parts.add(_hospitalDetail!.city);
    }
    if (_hospitalDetail!.state.isNotEmpty) {
      parts.add(_hospitalDetail!.state);
    }
    if (address.landmark != null && address.landmark!.isNotEmpty) {
      parts.add('Near ${address.landmark}');
    }

    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.hospitalBuilding.assetPath,
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.locationName ??
                        (widget.clinicId != null
                            ? 'Clinic Consultation'
                            : 'In-Clinic Consultation'),
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      color: const Color(0xff424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 16,
                            width: 200,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _getHospitalAddress(),
                    maxLines: 2,
                    style: EcliniqTextStyles.titleXLarge.copyWith(
                      color: Color(0xff8E8E8E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: (widget.clinicId == null && _hospitalDetail != null) ? _openMapsDirections : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
          decoration: BoxDecoration(
            color: Color(0xffF9F9F9),
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                    child: _isLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                  child: Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.white,
                            ),
                          )
                        : Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                            child: _hospitalDetail != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Map preview - using Google Static Maps or placeholder
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.blue.shade50,
                                              Colors.blue.shade100,
                                            ],
                                          ),
                                        ),
                    child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 48,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _hospitalDetail!.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Optional: Add a small map icon overlay
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.map,
                                            size: 16,
                                            color: Color(0xff2372EC),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
                if (widget.clinicId == null)
                  InkWell(
                    onTap: _hospitalDetail != null ? _openMapsDirections : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions,
                            size: 18,
                            color: _hospitalDetail != null
                                ? Color(0xff2372EC)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap to get directions',
                    style: EcliniqTextStyles.bodySmall.copyWith(
                              color: _hospitalDetail != null
                                  ? Color(0xff2372EC)
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Clinic location',
                  style: EcliniqTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}