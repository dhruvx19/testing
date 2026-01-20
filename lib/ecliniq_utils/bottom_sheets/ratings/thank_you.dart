import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class ThankYou extends StatefulWidget {
  const ThankYou({super.key});

  @override
  State<ThankYou> createState() => _ThankYouState();
}

class _ThankYouState extends State<ThankYou> {
  late int _tempRating;

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EcliniqTextStyles.getResponsivePadding(context, 16),
        EcliniqTextStyles.getResponsivePadding(context, 16),
        EcliniqTextStyles.getResponsivePadding(context, 16),
        MediaQuery.of(context).viewInsets.bottom + EcliniqTextStyles.getResponsivePadding(context, 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: EcliniqTextStyles.getResponsiveWidth(context, 142),
            height: EcliniqTextStyles.getResponsiveHeight(context, 110),
            child: Image.asset(
              EcliniqIcons.thankYou.assetPath,
              fit: BoxFit.contain,
            ),
          ),

          Text(
            'Thank you for your Valuable Feedback!',
            style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
           
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 22),
          ),

          _buildSubmitButton(),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      child: GestureDetector(
        onTapUp: (_) {
          Navigator.of(context).pop(_tempRating);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
            ),
            border: Border.all(color: const Color(0xff8E8E8E), width: 0.5),
          ),
          child:  Center(
            child: Text(
              'Ok',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              
                fontWeight: FontWeight.w500,
                color: Color(0xff424242),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
