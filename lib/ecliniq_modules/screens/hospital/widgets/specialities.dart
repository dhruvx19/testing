import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:ecliniq/ecliniq_utils/phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MedicalSpecialtiesWidget extends StatelessWidget {
  final List<HospitalSpecialty>? specialties;

  const MedicalSpecialtiesWidget({super.key, this.specialties});

  @override
  Widget build(BuildContext context) {
    final specialtyNames = specialties?.map((s) => s.name).toList() ?? [];

    if (specialtyNames.isEmpty) {
      return const SizedBox.shrink();
    }

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
                'Medical Specialties',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: specialtyNames.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    specialty,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff424242),
                        ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class HospitalServicesWidget extends StatelessWidget {
  final List<String>? services;

  const HospitalServicesWidget({super.key, this.services});

  @override
  Widget build(BuildContext context) {
    final serviceList = services ?? [];

    if (serviceList.isEmpty) {
      return const SizedBox.shrink();
    }

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
                'Hospital Services & Facilities',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: serviceList.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    service,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff424242),
                        ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CertificatesWidget extends StatelessWidget {
  final List<String>? accreditation;

  const CertificatesWidget({super.key, this.accreditation});

  @override
  Widget build(BuildContext context) {
    final certificates =
        accreditation
            ?.map((acc) => {'icon': Icons.verified_outlined, 'name': acc})
            .toList() ??
        [];

    if (certificates.isEmpty) {
      return const SizedBox.shrink();
    }

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
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: certificates.map((cert) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.certificate.assetPath,
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cert['name'] as String,
                        style: EcliniqTextStyles.responsiveTitleXLarge(context)
                            .copyWith(
                              fontWeight: FontWeight.w400,
                              color: Color(0xff424242),
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactDetailsWidget extends StatelessWidget {
  const ContactDetailsWidget({super.key});

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
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
            child: Column(
              children: [
                _buildContactItem(
                  context: context,
                  icon: EcliniqIcons.mailBlue,

                  title: 'contact@manipalbaner.com',
                  subtitle: 'Hospital Contact Email',
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                HorizontalDivider(),
                const SizedBox(height: 8),
                _buildContactItem(
                  context: context,
                  icon: EcliniqIcons.hospitalBuilding,

                  title: '9876543210',
                  subtitle: 'Hospital Contact Number',
                  showCallButton: true,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                HorizontalDivider(),
                const SizedBox(height: 8),
                _buildContactItem(
                  context: context,
                  icon: EcliniqIcons.callEmergency,

                  title: '02068138888',
                  subtitle: 'Emergency Contact Number',
                  showCallButton: true,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                HorizontalDivider(),

                const SizedBox(height: 8),
                _buildContactItem(
                  context: context,

                  icon: EcliniqIcons.sirenRounded,

                  title: '02068138888',
                  subtitle: 'Ambulance Contact Number',
                  showCallButton: true,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                HorizontalDivider(),
                const SizedBox(height: 8),
                _buildContactItem(
                  context: context,
                  icon: EcliniqIcons.drop,

                  title: '02068138888',
                  subtitle: 'Blood Bank Contact Number',
                  showCallButton: true,
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
    required EcliniqIcons icon,

    required String title,
    required String subtitle,
    bool showCallButton = false,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Row(
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
                      color: Color(0xff424242),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: EcliniqTextStyles.responsiveTitleXLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w400,
                      color: Color(0xff8E8E8E),
                    ),
              ),
            ],
          ),
        ),
        if (showCallButton)
          GestureDetector(
            onTap: () => PhoneLauncher.launchPhoneCall(title),
            child: SvgPicture.asset(
              EcliniqIcons.phone.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 26),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 26),
            ),
          ),
        SizedBox(width: 4),
      ],
    );
  }
}
