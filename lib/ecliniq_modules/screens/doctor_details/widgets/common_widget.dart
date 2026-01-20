import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

String _getImageUrl(String? imageKey) {
  if (imageKey == null || imageKey.isEmpty) {
    return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
  }
  return '${Endpoints.localhost}/$imageKey';
}

class ClinicalDetailsWidget extends StatelessWidget {
  final ClinicDetails clinicDetails;

  const ClinicalDetailsWidget({super.key, required this.clinicDetails});

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Clinical Details',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  context:   context,
                  label: 'Clinic Name:',
                  value: clinicDetails.name,
                ),

                const SizedBox(height: 12),

                if (clinicDetails.contactEmail != null)
                  _buildDetailItem(
                    context:   context,
                    label: 'Clinic Contact Email:',
                    value: clinicDetails.contactEmail!,
                  ),

                _buildDetailItem(
                  context:   context,
                  label: 'Clinic Contact Number:',
                  value: clinicDetails.contactNumber!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required String label, required String value, required BuildContext context}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff8E8E8E)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 3,
          style: EcliniqTextStyles.responsiveHeadlineBMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w500, color: Color(0xff424242)),
        ),
        Divider(color: Color(0xffD6D6D6), thickness: 0.5),
      ],
    );
  }
}

class ProfessionalInformationWidget extends StatelessWidget {
  final ProfessionalInformation professionalInfo;

  const ProfessionalInformationWidget({
    super.key,
    required this.professionalInfo,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Professional Information',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (professionalInfo.registrationNumber != null)
                  _buildDetailItemRegis(
                    label: 'Registration Number:',
                    value: professionalInfo.registrationNumber!,
                    hasVerification: true,
                    context: context,
                  ),
                if (professionalInfo.registrationNumber != null)
                  const SizedBox(height: 12),
                if (professionalInfo.registrationCouncil != null)
                  _buildDetailItem(
                    context: context,
                    label: 'Registration Council:',
                    value: professionalInfo.registrationCouncil!,
                  ),
                if (professionalInfo.registrationCouncil != null)
                  const SizedBox(height: 12),
                if (professionalInfo.registrationYear != null)
                  _buildDetailItem(
                    context: context,
                    label: 'Registration Year:',
                    value: professionalInfo.registrationYear!,
                  ),
                if (professionalInfo.registrationYear != null)
                  const SizedBox(height: 12),
                if (professionalInfo.specializations != null &&
                    professionalInfo.specializations!.isNotEmpty)
                  _buildDetailItem(
                    context: context,
                    label: 'Specializations:',
                    value: professionalInfo.specializations!
                        .map((s) => '${s.name} (Exp: ${s.expYears}years)')
                        .join(', '),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff8E8E8E)),
        ),
        const SizedBox(height: 4),

        Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 20,
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
                      fontWeight: FontWeight.w500,
                      color: Color(0xff424242),
                    ),
              ),
            ),
          ],
        ),
        Divider(color: Color(0xffD6D6D6), thickness: 0.5),
      ],
    );
  }
}

Widget _buildDetailItemRegis({
  required String label,
  required String value,
  bool hasVerification = false,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: EcliniqTextStyles.responsiveTitleXLarge(
          context,
        ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff8E8E8E)),
      ),
      const SizedBox(height: 4),

      Row(
        children: [
          Text(
            value,
            maxLines: 20,
            style: EcliniqTextStyles.responsiveHeadlineBMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w500, color: Color(0xff424242)),
          ),
          if (hasVerification) ...[
            SvgPicture.asset(
              EcliniqIcons.verifiedGreenDoctor.assetPath,
              width: 16,
              height: 16,
            ),
          ],
        ],
      ),
      Divider(color: Color(0xffD6D6D6), thickness: 0.5),
    ],
  );
}

class DoctorContactDetailsWidget extends StatelessWidget {
  final ContactDetails contactDetails;

  const DoctorContactDetailsWidget({super.key, required this.contactDetails});

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Contact Details',
                style: EcliniqTextStyles.responsiveHeadlineLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (contactDetails.email != null)
                  _buildContactItem(
                    icon: EcliniqIcons.mailBlue,

                    title: contactDetails.email!,
                    subtitle: 'Doctor Contact Email',
                    onTap: () {},
                    context: context,
                  ),
                if (contactDetails.email != null) const SizedBox(height: 16),
                if (contactDetails.phone != null)
                  _buildContactItem(
                    icon: EcliniqIcons.sthes,

                    title: contactDetails.phone!,
                    subtitle: 'Doctor Contact Number',
                    showCallButton: true,
                    onTap: () {},
                    context: context,
                  ),
                if (contactDetails.phone != null) const SizedBox(height: 16),
                if (contactDetails.languages != null &&
                    contactDetails.languages!.isNotEmpty)
                  _buildContactItem(
                    icon: EcliniqIcons.userSpeak,

                    title: contactDetails.languages!.join(', '),
                    subtitle: 'Speaks',
                    onTap: () {},
                    context: context,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required EcliniqIcons icon,
    required BuildContext context,
    required String title,
    required String subtitle,
    bool showCallButton = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(
              icon.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (showCallButton)
              IconButton(
                onPressed: () => PhoneLauncher.launchPhoneCall(title),
                icon: SvgPicture.asset(
                  EcliniqIcons.phone.assetPath,
                  width: 32,
                  height: 32,
                ),
              ),
          ],
        ),
        Divider(color: Color(0xffD6D6D6), thickness: 0.5),
      ],
    );
  }
}

class EducationalInformationWidget extends StatelessWidget {
  final List<EducationalInformation> educationList;

  const EducationalInformationWidget({super.key, required this.educationList});

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Educational Information',
                style: EcliniqTextStyles.responsiveHeadlineLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: educationList.asMap().entries.map((entry) {
                final index = entry.key;
                final education = entry.value;
                return Column(
                  children: [
                    _buildEducationItem(
                      degree: education.degree,
                      institution: education.instituteName,
                      type: education.graduationType == 'UG'
                          ? 'Graduation Degree'
                          : 'Post Graduation Degree',
                      year: education.completionYear > 0
                          ? 'Completed in ${education.completionYear}'
                          : 'Year not specified',
                      context: context,
                    ),
                    if (index < educationList.length - 1)
                      const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem({
    required String degree,
    required String institution,
    required String type,
    required String year,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.academicCap.assetPath,
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    degree,
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    institution,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$type - $year',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Divider(color: Color(0xffD6D6D6), thickness: 0.5),
      ],
    );
  }
}

class DoctorCertificatesWidget extends StatelessWidget {
  final List<CertificateAndAccreditation> certificates;

  const DoctorCertificatesWidget({super.key, required this.certificates});

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Certificates & Accreditations',
                style: EcliniqTextStyles.responsiveHeadlineLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: certificates.map((cert) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 20,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cert.name,
                      style: EcliniqTextStyles.responsiveBodySmall(context)
                          .copyWith(
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ClinicPhotosWidget extends StatelessWidget {
  final List<String> photos;

  const ClinicPhotosWidget({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Clinic Photos',
                style: EcliniqTextStyles.responsiveHeadlineLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: photos.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _buildPhotoItem(
                          imageUrl: _getImageUrl(photos[index]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem({required String imageUrl}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: Colors.grey[500],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
