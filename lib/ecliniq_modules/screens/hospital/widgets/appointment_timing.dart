import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppointmentTimingWidget extends StatefulWidget {
  const AppointmentTimingWidget({super.key});

  @override
  State<AppointmentTimingWidget> createState() =>
      _AppointmentTimingWidgetState();
}

class _AppointmentTimingWidgetState extends State<AppointmentTimingWidget> {
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      'Appointment & OPD timing',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
         
                        fontWeight: FontWeight.w600,
                        color: Color(0xff424242),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.calendar1.assetPath,
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '10:30 AM - 4:00 PM',
                          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Color(0xff424242),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monday to Saturday',
                      style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                        
                        fontWeight: FontWeight.w400,
                        color: Color(0xff626060),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffF2F7FF),
                    foregroundColor: Color(0xffF2F7FF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Color(0xff96BFFF), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      FittedBox(
                        child: Text(
                          'Inquire Now',
                          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Color(0xff2372EC),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
