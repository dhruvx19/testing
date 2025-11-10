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
                    color: Colors.blue.shade50.withOpacity(0.2),
                    border: Border.all(color: Colors.blue, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SvgPicture.asset(
                      EcliniqIcons.hospital.assetPath,
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
                      'Sunrise Family Clinic, Wakad',
                      style: EcliniqTextStyles.headlineLarge.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Est. Date : Aug, 2015',
                      style: EcliniqTextStyles.bodyLarge.copyWith(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Read About',
                          style: EcliniqTextStyles.bodySmall.copyWith(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                        SvgPicture.asset(
                          EcliniqIcons.angleRight.assetPath,
                          color: Colors.blue,
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
                    color: Colors.orange.withOpacity(0.2),
                    border: Border.all(color: Colors.orange, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "M",
                      style: EcliniqTextStyles.bodySmall.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Dr. Milind Chauhan',
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
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
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Row(
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
                    style: EcliniqTextStyles.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
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
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  height: 30,
                  width: 74,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Center(
                        child: Text(
                          '4KM ',
                          style: EcliniqTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                color: Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '25 Token Available',
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, color: Colors.green),
                          Text(
                            'Queue Started',
                            style: EcliniqTextStyles.bodyMedium.copyWith(
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Book Appointment',
                        style: EcliniqTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 16,
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
