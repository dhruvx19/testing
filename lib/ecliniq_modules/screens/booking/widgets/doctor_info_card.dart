import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DoctorInfoCard extends StatelessWidget {
  final Doctor? doctor;
  final String? facilityName;
  final String? facilityArea;
  final String? facilityDistance;

  const DoctorInfoCard({
    super.key,
    this.doctor,
    this.facilityName,
    this.facilityArea,
    this.facilityDistance,
  });

  static final Color _borderColor = const Color(0xFF1565C0).withOpacity(0.2);

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _borderColor,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            doctor != null ? _getInitials(doctor!.name) : 'M',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
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
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor?.name ?? 'Dr. Milind Chauhan',
                          style: EcliniqTextStyles.headlineLarge.copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                      doctor != null
                          ? _getSpecializations(doctor!.specializations)
                          : 'General Physician',
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: Color(0xff424242),
                          ),
                        ),
                        if (doctor != null &&
                            doctor!.degreeTypes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _getDegrees(doctor!.degreeTypes),
                            style: EcliniqTextStyles.titleXLarge.copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                        ] else if (doctor == null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'MBBS, MD - General Medicine',
                            style: EcliniqTextStyles.titleXLarge.copyWith(
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
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 4),
                  if (doctor != null && doctor!.yearOfExperience != null)
                    Text(
                      _getExperienceText(doctor!.yearOfExperience),
                      style: EcliniqTextStyles.titleXLarge.copyWith(
                        color: Color(0xff626060),
                      ),
                    )
                  else
                    Text(
                      '27yrs of exp',
                      style: EcliniqTextStyles.titleXLarge.copyWith(
                        color: Color(0xff626060),
                      ),
                    ),
                  if (doctor != null && doctor!.yearOfExperience != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xff8E8E8E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xff8E8E8E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffFEF9E6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.star.assetPath,
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          doctor?.rating != null
                              ? doctor!.rating!.toStringAsFixed(1)
                              : '4.0',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xffBE8B00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.hospitalBuilding.assetPath,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    facilityName ?? 'Sunrise Family Clinic',
                    style: EcliniqTextStyles.titleXLarge.copyWith(
                      color: const Color(0xff626060),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2372EC),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        EcliniqIcons.shuffle.assetPath,
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.mapPoint.assetPath,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      facilityArea ?? 'Vishnu Dev Nagar, Wakad',
                      style: EcliniqTextStyles.titleXLarge.copyWith(
                        color: const Color(0xff626060),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xffB8B8B8)),
                    ),

                    child: Text(
                      facilityDistance ?? '4 Km',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xffF8FAFF),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '69',
                style: EcliniqTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Token Number Currently Running',
                style: EcliniqTextStyles.titleXLarge.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 2, thickness: 0.3, color: Colors.grey),
        SizedBox(height: 14),
      ],
    );
  }
}
