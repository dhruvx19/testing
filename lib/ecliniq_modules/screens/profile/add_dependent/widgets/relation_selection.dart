import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RelationSelectionSheet extends StatelessWidget {
  final AddDependentProvider? provider;

  const RelationSelectionSheet({super.key, this.provider});

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
      'Other',
    ];
    final providerToUse =
        provider ?? Provider.of<AddDependentProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: EcliniqColors.light.bgBaseOverlay,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 15),
            child: Text(
              'Select Relation',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w500,
           
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: relations.length,
              itemBuilder: (context, index) {
                final relation = relations[index];
                final isSelected = providerToUse.selectedRelation == relation;
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
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                  
                    ),
                  ),
                  onTap: () {
                    providerToUse.selectRelation(relation);
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => Navigator.pop(context, relation),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
