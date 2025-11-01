import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../ecliniq_ui/lib/tokens/colors.g.dart';
import '../../../../../ecliniq_ui/lib/tokens/styles.dart';

class RelationSelectionSheet extends StatelessWidget {
  const RelationSelectionSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final relations = [
      'Father',
      'Mother',
      'Son',
      'Daughter',
      'Brother',
      'Sister',
      'Spouse',
      'Grandfather',
      'Grandmother',
      'Uncle',
      'Aunt',
      'Other'
    ];

    return ChangeNotifierProvider(
      create: (_) => AddDependentProvider(),
      child: Container(
        decoration: BoxDecoration(
          color: EcliniqColors.light.bgBaseOverlay,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EcliniqColors.light.strokeNeutralSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Relation',
                style: EcliniqTextStyles.headlineBMedium.copyWith(
                  color: EcliniqColors.light.textPrimary,
                ),
              ),
            ),
            Consumer<AddDependentProvider>(
              builder: (context, watch, child) {
                return Column(
                  children: relations.map((relation) {
                    final isSelected = watch.selectedRelation == relation;
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
                        relation,
                        style: EcliniqTextStyles.bodyMedium.copyWith(
                          color: EcliniqColors.light.textPrimary,
                        ),
                      ),
                      onTap: () {
                        Future.delayed(
                          const Duration(milliseconds: 100),
                              () => Navigator.pop(context, relation),
                        );
                        watch.selectRelation(relation);
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