import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Login trouble page header + terms heading.
class ProfileHelpPage extends StatelessWidget {
  const ProfileHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EcliniqScaffold.primaryBlue,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: SvgPicture.asset(
                  EcliniqIcons.close.assetPath,
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SizedBox.expand(
        child: Expanded(
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0,left: 18.0,right: 18.0),
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
                              'Need help for Profile Details?',
                              style:  EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                            
                                fontWeight: FontWeight.w500,
                                color: Color(0xff424242),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Try the following',
                              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                       
                                fontWeight: FontWeight.w400,
                              ).copyWith(color: Color(0xff424242)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.questionCircle.assetPath,
                        width: 32,
                        height: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trouble inputting Profile Info ? ',
                        style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                          fontWeight: FontWeight.w500,
                  
                          color: Color(0xff424242),
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Go to our help centre to know step - by - step guide for Profile Details Process.',
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          fontWeight: FontWeight.w400,
                         
                          color: Color(0xff8E8E8E),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        // Your onPressed logic here
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffF2F7FF),
                          borderRadius: BorderRadius.circular(4),
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
                            SizedBox(width: 4),
                            SvgPicture.asset(
                              EcliniqIcons.arrowRight.assetPath,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                Color(0xff2372EC),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 0.5, color: Color(0xffD6D6D6)),
                  const SizedBox(height: 24),
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
                        'Can’t able to add profile details?',
                        style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                          fontWeight: FontWeight.w500,
                        
                          color: Color(0xff424242),
                          
                        ),
                      ),

                      Text(
                        'Get instant answers to your queries from our support team',
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          fontWeight: FontWeight.w400,
                        
                          color: Color(0xff8E8E8E),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        // Your onPressed logic here
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffF2F7FF),
                          borderRadius: BorderRadius.circular(4),
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
                            SizedBox(width: 4),
                            SvgPicture.asset(
                              EcliniqIcons.arrowRight.assetPath,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                Color(0xff2372EC),
                                BlendMode.srcIn,
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
          ),
        ),
      ),
    );
  }
}
