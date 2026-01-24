import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AddressWidget extends StatefulWidget {
  final ClinicDetails clinic;

  const AddressWidget({super.key, required this.clinic});

  @override
  State<AddressWidget> createState() => _AddressWidgetState();
}

class _AddressWidgetState extends State<AddressWidget> {
  /// Open maps app with directions from current location to clinic
  /// @description Opens Google Maps or Apple Maps with navigation directions
  /// from user's current location to the clinic coordinates
  Future<void> _openMapsDirections() async {
    if (widget.clinic.latitude == null || widget.clinic.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location coordinates not available'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final lat = widget.clinic.latitude!;
    final lng = widget.clinic.longitude!;

    // Try Google Maps first with directions from current location
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    // Try Apple Maps (will fall back to web on Android)
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

    try {
      bool canLaunchGoogle = false;
      bool canLaunchApple = false;

      // Safely check if URLs can be launched
      try {
        canLaunchGoogle = await canLaunchUrl(googleMapsUrl);
      } catch (e) {
        canLaunchGoogle = false;
      }

      try {
        canLaunchApple = await canLaunchUrl(appleMapsUrl);
      } catch (e) {
        canLaunchApple = false;
      }

      // Try to launch Google Maps
      if (canLaunchGoogle) {
        try {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          // Continue to next option if Google Maps fails
        }
      }

      // Try to launch Apple Maps
      if (canLaunchApple) {
        try {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          // Continue to web fallback if Apple Maps fails
        }
      }

      // Fall back to web browser with Google Maps
      final webMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      try {
        await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        // If all methods fail, try launching without checking first
        try {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } catch (finalLaunchError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to open maps app. Please try again or search for the location manually.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Silent fail - error handling above already shows user-friendly message
    }
  }

  /// Get static map image URL for preview
  /// @description Generates a Google Static Maps URL for the clinic location
  /// @returns String? - Static map image URL or null if coordinates unavailable
  String? _getStaticMapUrl() {
    if (widget.clinic.latitude == null || widget.clinic.longitude == null) {
      return null;
    }

    final lat = widget.clinic.latitude!;
    final lng = widget.clinic.longitude!;

    // Google Static Maps API (no API key required for basic usage)
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=400x150&maptype=roadmap&markers=color:red%7C$lat,$lng';
  }

  @override
  Widget build(BuildContext context) {
    final hasCoordinates =
        widget.clinic.latitude != null && widget.clinic.longitude != null;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFF96BFFF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clinic Address',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clinic.address,
                  maxLines: 8,
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                      .copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff626060),
                      ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: hasCoordinates ? _openMapsDirections : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 118,
                    decoration: BoxDecoration(
                      color: Color(0xffF9F9F9),

                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 70,
                              width: double.infinity,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: hasCoordinates ? _openMapsDirections : null,
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tap to get the clinic direction',
                                  style:
                                      EcliniqTextStyles.responsiveBodySmall(
                                        context,
                                      ).copyWith(
                                        color: hasCoordinates
                                            ? Color(0xff2372EC)
                                            : Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
