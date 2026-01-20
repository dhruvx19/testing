import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

class CancellationPolicyBottomSheet extends StatefulWidget {
  const CancellationPolicyBottomSheet({super.key});

  @override
  State<CancellationPolicyBottomSheet> createState() =>
      _CancellationPolicyBottomSheetState();
}

class _CancellationPolicyBottomSheetState
    extends State<CancellationPolicyBottomSheet> {
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
            'Cancellation & Rescheduling Policy',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
       
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildBulletPoint(
            'You can cancel or reschedule your appointment up to 30 minutes before the scheduled appointment time.',
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            'If the provider cancels the appointment, the Service Fee and Taxes will be refunded as Upchar-Q Coins, which can be used for your next booking.',
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            'Service Fee and Taxes are non-refundable if the appointment is cancelled by the patient or marked as a no-show.',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
  crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color(0xFF626060),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: EcliniqText(
            text,
            style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
            
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
