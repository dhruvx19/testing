import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DependentsSection extends StatelessWidget {
  final List<Dependent> dependents;
  final VoidCallback? onAddDependent;
  final Function(Dependent)? onDependentTap;

  const DependentsSection({
    super.key,
    required this.dependents,
    this.onAddDependent,
    this.onDependentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: EcliniqTextStyles.getResponsiveSpacing(context, 5)),
          child: Center(
            child: Text(
              "Add Dependents",
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                color: Color(0xff626060),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 20)),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...dependents.map(
                  (dep) => Padding(
                    padding: EdgeInsets.only(right: EcliniqTextStyles.getResponsiveSpacing(context, 15)),
                    child: _DependentCard(
                      label: dep.relation,
                      isAdded: true,
                      onTap: () => onDependentTap?.call(dep),
                    ),
                  ),
                ),
                _DependentCard(
                  label: "Add",
                  isAdded: false,
                  onTap: onAddDependent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class Dependent {
  final String id;
  final String name;
  final String relation;

  Dependent({required this.id, required this.name, required this.relation});
}

class _DependentCard extends StatelessWidget {
  final String label;
  final bool isAdded;
  final VoidCallback? onTap;

  const _DependentCard({
    required this.label,
    required this.isAdded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: EcliniqTextStyles.getResponsiveSize(context, 52),
            height: EcliniqTextStyles.getResponsiveSize(context, 52),
            decoration: BoxDecoration(
              color: isAdded ? Color(0xffFFF7F0) : Color(0xffF9F9F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isAdded ? Color(0xffEC7600) : Color(0xff96BFFF),
                width: 0.5,
              ),
            ),
            child: Center(
              child: isAdded
                  ? EcliniqText(
                      label.substring(0, 1).toUpperCase(),
                      style: EcliniqTextStyles.responsiveHeadlineLargeBold(context).copyWith(
                        color: Color(0xffEC7600),
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : SvgPicture.asset(
                      EcliniqIcons.add.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 34),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 34),
                    ),
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
          Text(
            label,
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              fontWeight: FontWeight.w400,
              color: Color(0xff626060),
            ),
          ),
        ],
      ),
    );
  }
}

class AppUpdateBanner extends StatelessWidget {
  final String currentVersion;
  final String? newVersion;
  final VoidCallback? onUpdate;

  const AppUpdateBanner({
    super.key,
    required this.currentVersion,
    this.newVersion,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpdate,
      child: Container(
        height: EcliniqTextStyles.getResponsiveSize(context, 48),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: EcliniqTextStyles.getResponsiveSpacing(context, 10)),
        decoration: BoxDecoration(
          color: const Color(0xFF2372EC),
          borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              EcliniqIcons.restart.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 10)),
            Text(
              "App Update Available",
              style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                vertical: EcliniqTextStyles.getResponsiveSpacing(context, 2),
              ),
              decoration: BoxDecoration(
                color: Color(0xffF8FAFF),
                borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4)),
              ),
              child: Text(
                newVersion ?? currentVersion,
                style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                  color: Color(0xFF2372EC),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 5)),
            SvgPicture.asset(
              EcliniqIcons.angleRight.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
          ],
        ),
      ),
    );
  }
}
