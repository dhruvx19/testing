import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

class TaxesBottomSheet extends StatefulWidget {
  const TaxesBottomSheet({super.key});

  @override
  State<TaxesBottomSheet> createState() => _TaxesBottomSheetState();
}

class _TaxesBottomSheetState extends State<TaxesBottomSheet> {
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
            'Service Fees & Taxes Breakdown',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w500, color: Color(0xFF424242)),
          ),
          const SizedBox(height: 8),
          EcliniqText(
            'This small fee helps us operate and maintain Upchar-Q Platform.',
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Service Charges',
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xff626060)),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              Row(
                children: [
                  Text(
                    '12.71',
                    style: EcliniqTextStyles.responsiveHeadlineXLMedium(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Taxes on Service Charge',
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xff626060)),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              Row(
                children: [
                  Text(
                    '2.29',
                    style: EcliniqTextStyles.responsiveHeadlineXLMedium(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 0.5, color: Color(0xFFB8B8B8)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Total Payable',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              Row(
                children: [
                  Text(
                    '₹15',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
