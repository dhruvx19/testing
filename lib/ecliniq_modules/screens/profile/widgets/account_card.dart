import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class AccountSettingsMenu extends StatelessWidget {
  final VoidCallback? onPersonalDetailsPressed;
  final VoidCallback? onCreateAbhaPressed;
  final VoidCallback? onMedicalRecordsPressed;
  final VoidCallback? onSecuritySettingsPressed;

  const AccountSettingsMenu({
    super.key,
    this.onPersonalDetailsPressed,
    this.onCreateAbhaPressed,
    this.onMedicalRecordsPressed,
    this.onSecuritySettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Account',
              style: EcliniqTextStyles.headlineLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildMenuItem(
            iconPath: EcliniqIcons.userCircle.assetPath ,
            iconColor: Colors.blue,
            title: 'Personal Details',
            onTap: onPersonalDetailsPressed,
          ),
          _buildDivider(),
          _buildMenuItem(
            iconPath: EcliniqIcons.abhaIdLogo.assetPath,
            iconColor: Colors.purple,
            title: 'Create My ABHA ID',
            onTap: onCreateAbhaPressed,
          ),
          _buildDivider(),
          _buildMenuItem(
            iconPath: 'assets/icons/medical_information_outlined.png',
            iconColor: Colors.blue,
            title: 'Medical Records',
            onTap: onMedicalRecordsPressed,
          ),
          _buildDivider(),
          _buildMenuItem(
            iconPath: 'assets/icons/lock_outline.png',
            iconColor: Colors.blue,
            title: 'Security Settings',
            onTap: onSecuritySettingsPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              
              child: Image.asset(iconPath, width: 20, height: 20)
            ),
          
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
    );
  }
}
