import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../ecliniq_utils/responsive_helper.dart';
import '../provider/dependent_provider.dart';

class PhysicalInfoCard extends StatefulWidget {
  const PhysicalInfoCard({super.key});

  @override
  State<PhysicalInfoCard> createState() => _PhysicalInfoCardState();
}

class _PhysicalInfoCardState extends State<PhysicalInfoCard> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<AddDependentProvider>(
          context,
          listen: false,
        );
        if (provider.height != null && _heightController.text.isEmpty) {
          _heightController.text = provider.height.toString();
        }
        if (provider.weight != null && _weightController.text.isEmpty) {
          _weightController.text = provider.weight.toString();
        }
      }
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _calculateBMI(int? height, int? weight) {
    if (height == null || weight == null || height == 0) {
      return '0.0';
    }
    final heightInMeters = height / 100.0;
    final bmi = weight / (heightInMeters * heightInMeters);
    return bmi.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);
    final provider = Provider.of<AddDependentProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: screenSize.getResponsiveValue(
          mobile: 8.0,
          mobileSmall: 6.0,
          mobileMedium: 8.0,
          mobileLarge: 10.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          screenSize.getResponsiveValue(
            mobile: 8.0,
            mobileSmall: 6.0,
            mobileMedium: 8.0,
            mobileLarge: 10.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _buildTextField(
                 context:   context,
                label: 'Height (cm)',
                hint: 'Enter Height',
                controller: _heightController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final height = int.tryParse(value);
                  provider.setHeight(height);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),

            Divider(
              color: Color(0xffD6D6D6),
              thickness: EcliniqTextStyles.getResponsiveSize(context, 0.5),
              height: 0,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                vertical: screenSize.getResponsiveValue(
                  mobile: 8.0,
                  mobileSmall: 6.0,
                  mobileMedium: 8.0,
                  mobileLarge: 10.0,
                ),
              ),
              height: screenSize.getResponsiveValue(
                mobile: 30.0,
                mobileSmall: 28.0,
                mobileMedium: 30.0,
                mobileLarge: 32.0,
              ),
              child: _buildTextField(
                 context:   context,
                label: 'Weight (kg)',
                hint: 'Enter Weight',
                controller: _weightController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final weight = int.tryParse(value);
                  provider.setWeight(weight);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),

            Divider(
              color: Color(0xffD6D6D6),
              thickness: EcliniqTextStyles.getResponsiveSize(context, 0.5),
              height: 0,
            ),
            Consumer<AddDependentProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    Text(
                      'BMI',
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                        color: EcliniqColors.light.textSecondary,
                      ),
                    ),
                    Spacer(),
                    Text(
                      _calculateBMI(provider.height, provider.weight),
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                        color: EcliniqColors.light.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTextField({
  required String label,
  required String hint,
  required TextEditingController controller,
  TextInputType? keyboardType,
  required Function(String) onChanged,
  List<TextInputFormatter>? inputFormatters,
  required BuildContext context,  
}) {
  return Row(
    children: [
      Expanded(
        flex: 1,
        child: Row(
          children: [
            Text(
              label,
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: Color(0xff626060),
              ),
            ),
          ],
        ),
      ),

      Expanded(
        flex: 1,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          textAlign: TextAlign.right,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
              color: Color(0xffB8B8B8),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
            color: Color(0xff424242),
          ),
        ),
      ),
    ],
  );
}
