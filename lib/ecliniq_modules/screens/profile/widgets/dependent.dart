import 'package:ecliniq/ecliniq_icons/icons.dart';
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
          padding: const EdgeInsets.only(left: 5),
          child: Center(
            child: Text(
              "Add Dependents",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xff626060),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                ...dependents.map(
                  (dep) => Padding(
                    padding: const EdgeInsets.only(right: 15),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isAdded ? Color(0xffF2F7FF) : Color(0xffF9F9F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isAdded ? Color(0xffffFfFF) : Color(0xff96BFFF),
                width: 1,
              ),
            ),
            child: Center(
              child: isAdded
                  ? Icon(Icons.person, size: 35, color: Colors.orange[700])
                  : SvgPicture.asset(
                      EcliniqIcons.add.assetPath,
                      width: 34,
                      height: 34,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
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
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2372EC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              EcliniqIcons.restart.assetPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              "App Update Available",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xffF8FAFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                newVersion ?? currentVersion,
                style: const TextStyle(
                  color: Color(0xFF2372EC),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 5),
            SvgPicture.asset(
              EcliniqIcons.angleRight.assetPath,
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
