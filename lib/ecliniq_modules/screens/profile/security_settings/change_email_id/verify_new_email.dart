import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';

class VerifyNewEmailAddress extends StatefulWidget {
  const VerifyNewEmailAddress({super.key});

  @override
  State<VerifyNewEmailAddress> createState() => _VerifyNewEmailAddressState();
}

class _VerifyNewEmailAddressState extends State<VerifyNewEmailAddress> {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            'Verify Existing Account',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please Verify your new  account information.',
              style: EcliniqTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                Text(
                  'OTP sent to ',
                  style: EcliniqTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'ketanpatni02@gmail.com',
                  style: EcliniqTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              autoFocus: true,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 48,
                fieldWidth: 40,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                activeColor: Colors.blue,
                selectedColor: Colors.blue,
                inactiveColor: Colors.grey.shade500,
                borderWidth: 1,
                activeBorderWidth: 1,
                selectedBorderWidth: 1,
                inactiveBorderWidth: 1,
                fieldOuterPadding: EdgeInsets.symmetric(horizontal: 4),
              ),
              enableActiveFill: true,
              errorTextSpace: 16,
              onChanged: (value) {},
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Didn\'t receive OTP?',
                  style: EcliniqTextStyles.bodyMedium.copyWith(color: Colors.grey.shade500),
                ),
                Spacer(),
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.clockCircle.assetPath,
                      width: 16,
                      height: 16,
                    ),
                    SizedBox(width: 4),
                    Text('02:30', style: EcliniqTextStyles.bodyMedium.copyWith( color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Resend',
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecuritySettingsOptions(),
                  ),
                );
              },

              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.blue.shade800,
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                minimumSize: MaterialStateProperty.all(
                  Size(double.infinity, 48),
                ),
              ),
              child: Container(
                height: 26,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify & Update',
                        style: EcliniqTextStyles.headlineXMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SvgPicture.asset(
                        EcliniqIcons.arrowRightWhite.assetPath,
                        width: 24,
                        height: 24,
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
