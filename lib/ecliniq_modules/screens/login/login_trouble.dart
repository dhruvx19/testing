import 'dart:io';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginTroublePage extends StatefulWidget {
  const LoginTroublePage({super.key});

  @override
  State<LoginTroublePage> createState() => _LoginTroublePageState();
}

class _LoginTroublePageState extends State<LoginTroublePage> {
  Future<void> _launchEmailSupport() async {
    try {
      // Get device information
      final deviceInfo = DeviceInfoPlugin();
      String deviceType = 'Unknown';
      String osVersion = 'Unknown';

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceType = iosInfo.utsname.machine ?? 'iPhone';
        osVersion = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceType = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release}';
      }

      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone_number') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      // Get locale/region
      final locale = Platform.localeName;

      // Platform identifier
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Email subject and body
      final subject = '[upcharq-$platform]: Issue in logging in upcharq app';
      final body = '''
Issue:

Phone Number: $phoneNumber

Name: $userName

App Version: $appVersion
Device Type: $deviceType
os Details: $osVersion
Region: $locale


Sent from my ${Platform.isIOS ? 'iPhone' : 'Android device'}''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@upcharq.com',
        query: _encodeQueryParameters(<String, String>{
          'subject': subject,
          'body': body,
        }),
      );

      // Try launching directly without canLaunchUrl check
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app. Please ensure you have an email app installed.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return EcliniqScaffold(
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SizedBox.expand(
        child: Column(
          children: [
            const SizedBox(height: 52),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: SvgPicture.asset(
                    EcliniqIcons.close.assetPath,
                    width: 32,
                    height: 32,
                  ),
                ),
              ],
            ),

            Expanded(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need help logging in?',
                                  style: EcliniqTextStyles.responsiveHeadlineXLarge(context)
                                      .copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff424242),
                                      ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Try the following',
                                  style: EcliniqTextStyles.responsiveTitleXLarge(context)
                                      .copyWith(fontWeight: FontWeight.w400)
                                      .copyWith(color: Color(0xff424242)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.questionCircle.assetPath,
                            width: 32,
                            height: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trouble in Sign?',
                            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                              fontWeight: FontWeight.w500,

                              color: Color(0xff424242),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Go to our help centre to know step - by - step guide for sign in or sign-up process',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              fontWeight: FontWeight.w400,

                              color: Color(0xff8E8E8E),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffF2F7FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xff96BFFF),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Go to Help Centre',
                                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                                    fontWeight: FontWeight.w500,

                                    color: Color(0xff2372EC),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: Color(0xff2372EC),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Divider(thickness: 1),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.chatMessage.assetPath,
                            width: 32,
                            height: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Can’t sign in?',
                            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                              fontWeight: FontWeight.w500,

                              color: Color(0xff424242),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Get instant answers to your queries from our support team',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              fontWeight: FontWeight.w400,

                              color: Color(0xff8E8E8E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: _launchEmailSupport,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffF2F7FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xff96BFFF),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Contact Customer Support',
                                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                                    fontWeight: FontWeight.w500,

                                    color: Color(0xff2372EC),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: Color(0xff2372EC),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
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
