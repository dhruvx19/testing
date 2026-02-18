import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SurgeryDetail extends StatelessWidget {
  final Map<String, dynamic> surgery;
  
  const SurgeryDetail({super.key, required this.surgery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(54),
                        color: Color(0xffF8FAFF),
                        border: Border.all(color: Color(0xff96BFFF), width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: SvgPicture.asset(
                          surgery['icon'].assetPath,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        surgery['name'],
                        style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xffF8FAFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              color: Color(0xff2372EC),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            surgery['description'],
                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                              color: Color(0xff626060),
                              fontWeight: FontWeight.w400,
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
          HorizontalDivider(color: Color(0xffD6D6D6), height: 0.5),
        ],
      ),
    );
  }
}