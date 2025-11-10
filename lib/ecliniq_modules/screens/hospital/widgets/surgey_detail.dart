import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SurgeryDetail extends StatelessWidget {
  const SurgeryDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SvgPicture.asset(
                      EcliniqIcons.scissor.assetPath,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Appendectomy',
                  style: EcliniqTextStyles.headlineLarge.copyWith(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                height: 89,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: EcliniqTextStyles.bodySmallProminent.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Surgical removal of the appendix, usually performed to treat appendicitis.',
                        style: EcliniqTextStyles.bodySmallProminent.copyWith(
                          color: Colors.black,
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
    );
  }
}
