import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DoctorInfoCard extends StatelessWidget {
  final Doctor? doctor;
  final String? doctorName;
  final String? specialization;
  final String? locationName;
  final String? locationAddress;
  final String? locationDistance;
  final VoidCallback? onChangeLocation;

   DoctorInfoCard({
    super.key,
    this.doctor,
    this.doctorName,
    this.specialization,
    this.locationName,
    this.locationAddress,
    this.locationDistance,
    this.onChangeLocation,
  });

  final StorageService _storageService = StorageService();
  static final Color _borderColor = const Color(0xFF1565C0).withOpacity(0.2);

  String _getInitials(String name) {
    if (name.startsWith('Dr. ')) {
      name = name.substring(4);
    }
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _formatDoctorName(String name) {
    if (name.toLowerCase().startsWith('dr.')) {
      // Ensure proper capitalization if needed, or just return
      return name;
    }
    return 'Dr. $name';
  }

  String _getSpecializations(List<String> specializations) {
    if (specializations.isEmpty) return 'General Physician';
    return specializations.join(', ');
  }

  String _getDegrees(List<String> degreeTypes) {
    if (degreeTypes.isEmpty) return '';
    return degreeTypes.join(', ');
  }

  String _getExperienceText(int? years) {
    if (years == null) return '';
    return '${years}yrs of exp';
  }

  @override
  Widget build(BuildContext context) {
    // Check if Change option should be visible
    bool shouldShowChange = false;
    if (doctor != null) {
      final totalLocations = doctor!.hospitals.length + doctor!.clinics.length;
      shouldShowChange = totalLocations >= 2;
    }
    
    // Also check if callback is provided
    if (onChangeLocation == null) {
      shouldShowChange = false;
    }

    final displayName = _formatDoctorName(doctor?.name ?? doctorName ?? 'Milind Chauhan');

    return Column(
      children: [
        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: EcliniqTextStyles.getResponsiveWidth(context, 70),
                        height: EcliniqTextStyles.getResponsiveHeight(context, 70),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                          border: Border.all(color: _borderColor, width: 1),
                        ),
                        child: doctor != null
                            ? FutureBuilder<String?>(
                                future: doctor!.getProfilePhotoUrl(_storageService),
                                builder: (context, snapshot) {
                                  final imageUrl = snapshot.data;
                                  if (imageUrl != null && imageUrl.isNotEmpty) {
                                    return ClipOval(
                                      child: Image.network(
                                        imageUrl,
                                        width: EcliniqTextStyles.getResponsiveWidth(context, 70),
                                        height: EcliniqTextStyles.getResponsiveHeight(context, 70),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              _getInitials(displayName),
                                              style: EcliniqTextStyles.responsiveHeadlineXXLargeBold(context).copyWith(
                                                color: Color(0xFF1565C0),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: Text(
                                      _getInitials(displayName),
                                      style: EcliniqTextStyles.responsiveHeadlineXXLargeBold(context).copyWith(
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  _getInitials(displayName),
                                  style: EcliniqTextStyles.responsiveHeadlineXXLargeBold(context).copyWith(
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: SvgPicture.asset(
                          EcliniqIcons.verified.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor != null
                              ? _getSpecializations(doctor!.specializations)
                              : specialization ?? 'General Physician',
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                        if (doctor != null &&
                            doctor!.degreeTypes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _getDegrees(doctor!.degreeTypes),
                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                        ] else if (doctor == null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'MBBS, MD - General Medicine',
                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.medicalKit.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  if (doctor != null && doctor!.yearOfExperience != null)
                    Text(
                      _getExperienceText(doctor!.yearOfExperience),
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        color: Color(0xff626060),
                      ),
                    )
                  else
                    Text(
                      '27yrs of exp',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  if (doctor != null && doctor!.yearOfExperience != null) ...[
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                    Container(
                      width: EcliniqTextStyles.getResponsiveWidth(context, 6),
                      height: EcliniqTextStyles.getResponsiveHeight(context, 6),
                      decoration: const BoxDecoration(
                        color: Color(0xff8E8E8E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                  ] else ...[
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                    Container(
                      width: EcliniqTextStyles.getResponsiveWidth(context, 6),
                      height: EcliniqTextStyles.getResponsiveHeight(context, 6),
                      decoration: const BoxDecoration(
                        color: Color(0xff8E8E8E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                  ],
                  Container(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffFEF9E6),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.star.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                        ),
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveSpacing(context, 2),
                        ),
                        Text(
                          doctor?.rating != null
                              ? doctor!.rating!.toStringAsFixed(1)
                              : '4.0',
                          style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                       
                            color: Color(0xffBE8B00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.hospitalBuilding.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Text(
                    locationName ?? 'Sunrise Family Clinic',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff626060),
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Container(
                    width: 0.5,
                    height: EcliniqTextStyles.getResponsiveHeight(context, 20),
                    color: Color(0xffD6D6D6),
                  ),
                  if (shouldShowChange) ...[
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onChangeLocation,
                          child:  Text(
                            'Change',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          
                              color: Color(0xFF2372EC),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                        ),
                        SvgPicture.asset(
                          EcliniqIcons.shuffle.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
              if (locationAddress != null)
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.mapPointBlack.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),
                    Expanded(
                      child: Text(
                        locationAddress!,
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          color: Color(0xff626060),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (locationDistance != null) ...[
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                      ),

                      Container(
                        height: EcliniqTextStyles.getResponsiveHeight(context, 24),
                        width: EcliniqTextStyles.getResponsiveWidth(context, 44),
                        decoration: BoxDecoration(
                          color: Color(0xffF9F9F9),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(context, 6),
                          ),
                          border: Border.all(
                            color: Color(0xffB8B8B8),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$locationDistance Km',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              color: Color(0xff424242),
                            
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
