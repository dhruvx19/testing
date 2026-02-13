import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AboutUpcharqPage extends StatelessWidget {
  const AboutUpcharqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'About Upcharq',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paragraph 1
            Text(
              'UpcharQ is a smart digital healthcare platform designed to simplify OPD visits by replacing traditional, manual token systems with a real-time, transparent queue management solution.',
              style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
            ),

            // Paragraph 2
            Text(
              'Built for the realities of Indian healthcare, UpcharQ enables patients to book tokens, track their position in the queue, and receive live updates, reducing unnecessary waiting and overcrowding at clinics and hospitals. At the same time, it empowers doctors and healthcare providers to manage OPD flow efficiently, handle walk-ins, reduce no-shows, and improve overall patient experience.',
              style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
            ),

            // Paragraph 3
            Text(
              'UpcharQ supports both online and walk-in consultations, offers secure communication and notifications, and follows a compliance-first approach to data privacy and security. The platform is designed to scale across individual clinics, multi-doctor hospitals, and healthcare networks.',
              style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
            ),

            // Paragraph 4
            Text(
              'UpcharQ is a product of Bloomevera Solutions, with a vision to become the digital backbone of OPD operations in India, making healthcare access smoother, predictable, and more patient-friendly.',
              style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 160),
            ),

            // Divider
            Divider(color: Color(0xffD6D6D6), thickness: 0.5),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
            ),

            // Logo and Version
            Center(
              child: Column(
                children: [
                  Image.asset(
                    EcliniqIcons.aboutLogo.assetPath,
                    width: EcliniqTextStyles.getResponsiveWidth(context, 187),
                    height: EcliniqTextStyles.getResponsiveHeight(context, 44),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'v1.0.0',
                    style:
                        EcliniqTextStyles.responsiveBodySmallProminent(
                          context,
                        ).copyWith(
                          color: Color(0xff8E8E8E),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
            ),
          ],
        ),
      ),
    );
  }
}
