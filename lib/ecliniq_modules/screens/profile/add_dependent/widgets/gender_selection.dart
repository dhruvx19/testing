import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenderSelectionSheet extends StatelessWidget {
  final AddDependentProvider? provider;

  const GenderSelectionSheet({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    final genders = ['Male', 'Female', 'Others'];
    final providerToUse =
        provider ?? Provider.of<AddDependentProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: EcliniqColors.light.bgBaseOverlay,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(22),
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 12),
            child: Text(
              'Select Gender',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w500,
              
              ),
            ),
          ),
          SizedBox(height: 8),
          Builder(
            builder: (context) {
              return Column(
                children: genders.map((gender) {
                  final isSelected = gender == providerToUse.selectedGender;
                  return ListTile(
                    leading: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? EcliniqColors.light.strokeBrand
                              : EcliniqColors.light.strokeNeutralSubtle,
                        ),
                        shape: BoxShape.circle,
                        color: isSelected
                            ? EcliniqColors.light.bgContainerInteractiveBrand
                            : EcliniqColors.light.bgBaseOverlay,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcliniqColors.light.bgBaseOverlay,
                        ),
                      ),
                    ),
                    title: Text(
                      gender,
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                      
                      ),
                    ),
                    onTap: () {
                      providerToUse.selectGender(gender);
                      Future.delayed(
                        const Duration(milliseconds: 300),
                        () => Navigator.pop(context, gender),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
