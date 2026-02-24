import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

class EtaBottomSheet extends StatefulWidget {
  const EtaBottomSheet({super.key});

  @override
  State<EtaBottomSheet> createState() => _EtaBottomSheetState();
}

class _EtaBottomSheetState extends State<EtaBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
      ),
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 22, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcliniqText(
            'About Expected Time',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w500, color: Color(0xFF424242)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
            'You can cancel or reschedule your appointment up to 30 minutes before the scheduled appointment time.',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EcliniqText(
            'This might not be the exact consultation time. Consultation time depends on the providers availability.',
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
