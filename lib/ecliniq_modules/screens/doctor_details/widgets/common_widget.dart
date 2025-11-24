import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

String _getImageUrl(String? imageKey) {
  if (imageKey == null || imageKey.isEmpty) {
    return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
  }
  return '${Endpoints.localhost}/$imageKey';
}

class ClinicalDetailsWidget extends StatelessWidget {
  final ProfessionalInformation professionalInfo;

  const ClinicalDetailsWidget({super.key, required this.professionalInfo});

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
              const Text(
                'Clinical Details',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w400,
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
                  _buildDetailItem(
                    label: 'Registration Number:',
                    value: professionalInfo.registrationNumber!,
                  ),
                if (professionalInfo.registrationNumber != null)
                  const SizedBox(height: 12),
                if (professionalInfo.registrationCouncil != null)
                  _buildDetailItem(
                    label: 'Registration Council:',
                    value: professionalInfo.registrationCouncil!,
                  ),
                if (professionalInfo.registrationCouncil != null)
                  const SizedBox(height: 12),
                if (professionalInfo.registrationYear != null)
                  _buildDetailItem(
                    label: 'Registration Year:',
                    value: professionalInfo.registrationYear!,
                  ),
                if (professionalInfo.registrationYear != null)
                  const SizedBox(height: 12),
                if (professionalInfo.specializations != null &&
                    professionalInfo.specializations!.isNotEmpty)
                  _buildDetailItem(
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

  Widget _buildDetailItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Divider(color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildDetailItemWithIcon({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onIconTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            IconButton(
              onPressed: EcliniqRouter.pop,
              icon: SvgPicture.asset(
                EcliniqIcons.phone.assetPath,
                width: 32,
                height: 32,
              ),
            ),
          ],
        ),
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
              const Text(
                'Professional Information',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w400,
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
                  _buildDetailItem(
                    label: 'Registration Number:',
                    value: professionalInfo.registrationNumber!,
                    hasVerification: true,
                  ),
                if (professionalInfo.registrationNumber != null)
                  const SizedBox(height: 12),
                if (professionalInfo.registrationCouncil != null)
                  _buildDetailItem(
                    label: 'Registration Council:',
                    value: professionalInfo.registrationCouncil!,
                  ),
                if (professionalInfo.registrationCouncil != null)
                  const SizedBox(height: 12),
                if (professionalInfo.registrationYear != null)
                  _buildDetailItem(
                    label: 'Registration Year:',
                    value: professionalInfo.registrationYear!,
                  ),
                if (professionalInfo.registrationYear != null)
                  const SizedBox(height: 12),
                if (professionalInfo.specializations != null &&
                    professionalInfo.specializations!.isNotEmpty)
                  _buildDetailItem(
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
    bool hasVerification = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
           
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xff626060),
                
              ),
            ),
            if (hasVerification) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: Colors.green),
            ],
          ],
        ),
        Divider(color: Colors.grey[300]),
      ],
    );
  }
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
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (contactDetails.email != null)
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFF5B9FFF),
                    title: contactDetails.email!,
                    subtitle: 'Doctor Contact Email',
                    onTap: () {},
                  ),
                if (contactDetails.email != null) const SizedBox(height: 16),
                if (contactDetails.phone != null)
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    iconColor: const Color(0xFF5B9FFF),
                    title: contactDetails.phone!,
                    subtitle: 'Doctor Contact Number',
                    showCallButton: true,
                    onTap: () {},
                  ),
                if (contactDetails.phone != null) const SizedBox(height: 16),
                if (contactDetails.languages != null &&
                    contactDetails.languages!.isNotEmpty)
                  _buildContactItem(
                    icon: Icons.language_outlined,
                    iconColor: const Color(0xFF5B9FFF),
                    title: contactDetails.languages!.join(', '),
                    subtitle: 'Speaks',
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showCallButton = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (showCallButton)
              IconButton(
                onPressed: EcliniqRouter.pop,
                icon: SvgPicture.asset(
                  EcliniqIcons.phone.assetPath,
                  width: 32,
                  height: 32,
                ),
              ),
          ],
        ),
        Divider(color: Colors.grey[300]),
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
              const Text(
                'Educational Information',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5B9FFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Color(0xFF5B9FFF),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                degree,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                institution,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$type - $year',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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
              const Text(
                'Certificates & Accreditations',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
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
                      style: const TextStyle(
                        fontSize: 14,
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
              const Text(
                'Clinic Photos',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
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
