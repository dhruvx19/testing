import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HospitalBranchDetail extends StatelessWidget {
  const HospitalBranchDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Color(0xffF8FAFF),
                    border: Border.all(color: Color(0xff96BFFF), width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SvgPicture.asset(
                      EcliniqIcons.hospitalBuilding.assetPath,
                      // width: 40,
                      // height: 40,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sunrise Family Clinic',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                        color: Color(0xff424242),
                      ),
                    ),
                    Text(
                      'Est. Date : Aug, 2015',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        color: Color(0xff424242),
              
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Read About',
                          style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                            color: Color(0xff2372EC),
                          ),
                        ),
                        SvgPicture.asset(
                          EcliniqIcons.angleRight.assetPath,
                          width: 16,
                          height: 16,
                          color: Color(0xff2372EC),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Color(0xfffff7f0),
                    border: Border.all(color: Color(0xffEC7600), width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "M",
                      style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                        color: Color(0xffEC7600),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Dr. Milind Chauhan',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.appointmentReminder.assetPath,
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 10),
                Text(
                  '10am - 9:30pm (Mon - Sat)',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  EcliniqIcons.pointOnMap.assetPath,
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Survey No 111/11/1, Veerbhadra Nagar Road, Mhalunge Main Road, Baner, Pune, Maharashtra - 411045.',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff626060),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.mapPointBlue.assetPath,
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Wakad, Pune',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  height: 30,
                  width: 74,
                  decoration: BoxDecoration(
                    color: Color(0xffF9F9F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 4),
                      Center(
                        child: Text(
                          '4KM ',
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            color: Color(0xff424242),
                   
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      SvgPicture.asset(
                        EcliniqIcons.mapArrow.assetPath,
                        width: 18,
                        height: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 30,
              width: 162,
              decoration: BoxDecoration(
                color: Color(0xffF2FFF3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '25 Token Available',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff3EAF3F),
                  
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(0xff3EAF3F),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Queue Started',
                              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                color: Color(0xff3EAF3F),
                              
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 140),
                    height: 52,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x332372EC),
                          offset: const Offset(7, 4),
                          blurRadius: 5.3,
                          spreadRadius: 0,
                        ),
                      ],
                      color: Color(0xff2372EC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: Center(
                        child: Text(
                          'Book Appointment',
                          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
