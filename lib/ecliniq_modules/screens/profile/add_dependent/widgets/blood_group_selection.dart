import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';

class BloodGroupSelectionSheet extends StatelessWidget {
  const BloodGroupSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Others'];

    return ChangeNotifierProvider(
      create: (_) => AddDependentProvider(),
      child: Container(
        decoration: BoxDecoration(
          color: EcliniqColors.light.bgBaseOverlay,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EcliniqColors.light.strokeNeutralSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 15, ),
              child: Text(
                'Select Blood Group',
                style: EcliniqTextStyles.headlineBMedium.copyWith(
                  color: EcliniqColors.light.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
            Consumer<AddDependentProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: bloodGroups.map((bloodGroup) {
                    final isSelected = provider.selectedBloodGroup == bloodGroup;

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
                        bloodGroup,
                        style: EcliniqTextStyles.bodyMedium.copyWith(
                          color: EcliniqColors.light.textPrimary,
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () {
                        provider.selectBloodGroup(bloodGroup);
                        Future.delayed(
                          const Duration(milliseconds: 200),
                              () => Navigator.pop(context, bloodGroup),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}