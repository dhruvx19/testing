import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_email_id/verify_existing_email.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'change_mobile_number/screens/verify_existing_account.dart';

class SecuritySettingsOptions extends StatefulWidget {
  const SecuritySettingsOptions({super.key});

  @override
  State<SecuritySettingsOptions> createState() => _SecuritySettingsOptionsState();
}

class _SecuritySettingsOptionsState extends State<SecuritySettingsOptions> {
  bool isOn = false;
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    void onPressedChangeMobileNumber() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyExistingAccount()),
      );
    }

    void onPressedChangeEmail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VerifyExistingEmail()),
      );
    }
    void handleBiometricPermission() {
      setState(() {
        isOn = !isOn;
      });
    }

    void onPressedChangeBiometricPermissions() {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
    void onPressedChangeMPin() {}

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Security Settings',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildTile(
              EcliniqIcons.smartphone.assetPath,
              'Change Mobile Number',
              onPressedChangeMobileNumber,
              _isExpanded
            ),
            Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: 1,
            ),
            _buildTile(
              EcliniqIcons.mail.assetPath,
              'Change Email ID',
              onPressedChangeEmail,
              _isExpanded
            ),
            Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: 1,
            ),
            _buildTile(
              EcliniqIcons.password.assetPath,
              'Change M-PIN',
              onPressedChangeMPin,
              _isExpanded
            ),
            Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: 1,
            ),
            _buildTile(
              EcliniqIcons.faceScanSquare.assetPath,
              'Change Biometric Permissions',
              onPressedChangeBiometricPermissions,
              _isExpanded
            ),
            if(_isExpanded)...[
              _buildDropDown( isOn, handleBiometricPermission)
            ],

            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 21),
              child: GestureDetector(
                onTap: () {
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF8F8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.trashBin2.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTile(String icon, String title, VoidCallback onPressed, bool isExpanded) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      splashFactory: InkSplash.splashFactory,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Colors.white,
    ),
    child: SizedBox(
      height: 48,
      width: double.infinity,
      child: Row(
        children: [
          SvgPicture.asset(icon, width: 24, height: 24),
          SizedBox(width: 8),
          Text(
            title,
            style: EcliniqTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w400,
              color: Color(0xff424242),
              fontSize: 18,
            ),
          ),

          Spacer(),
          (title != 'Change Biometric Permissions') ? SvgPicture.asset(
            EcliniqIcons.angleRight.assetPath,
            width: 24,
            height: 24,
          ) : (!isExpanded)?SvgPicture.asset(
            EcliniqIcons.angleRight.assetPath,
            width: 24,
            height: 24,
          ): SvgPicture.asset(
            EcliniqIcons.angleDown.assetPath,
            width: 24,
            height: 24,
          ),
        ],
      ),
    ),
  );
}

Widget _buildDropDown( bool isOn, VoidCallback onPressed) {
  return Column(
    children: [
      Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Face Lock Permission',
                style: EcliniqTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Color(0xff424242),
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep it turn ON to unlock app quickly without \ninputting m-pin. ',
                overflow: TextOverflow.visible,
                style: EcliniqTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
              )


            ],
          ),
          Spacer(),
          SizedBox(
            width: 40,
            height: 23,
            child:  GestureDetector(
              onTap: onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: isOn ? Colors.blue.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                  curve: Curves.easeInOut,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          )

        ],
      ),
      Divider(),
    ],
  );
}
