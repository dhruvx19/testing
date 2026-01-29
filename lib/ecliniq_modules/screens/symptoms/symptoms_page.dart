import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/search_bar.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SymptomsPage extends StatefulWidget {
  const SymptomsPage({super.key});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  String _searchQuery = '';
  final List<Map<String, dynamic>> _allSymptoms = [
      {'title': 'Fever/Chills', 'icon': EcliniqIcons.fever},
      {'title': 'Headache', 'icon': EcliniqIcons.headache},
      {'title': 'Stomach Pain', 'icon': EcliniqIcons.stomachPain},
      {'title': 'Cold & Cough', 'icon': EcliniqIcons.coughCold},
      {'title': 'Body Pain', 'icon': EcliniqIcons.bodyPain},
      {'title': 'Back Pain', 'icon': EcliniqIcons.backPain},
      {'title': 'Breathing Difficulty', 'icon': EcliniqIcons.breathingProblem},
      {'title': 'Skin Rash /Itching', 'icon': EcliniqIcons.itchingOrSkinProblem},
      {'title': 'Periods Problem', 'icon': EcliniqIcons.periodsProblem},
      {'title': 'Sleep Problem', 'icon': EcliniqIcons.sleepProblem},
  ];

  @override
  Widget build(BuildContext context) {
    // Filter symptoms based on search query
    final filteredSymptoms = _allSymptoms.where((symptom) {
      final title = (symptom['title'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowBack.assetPath,
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: EcliniqText(
          'Symptoms',
          style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
            color: Color(0xff424242),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          SearchBarWidget(
            hintText: 'Search Symptoms',
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: filteredSymptoms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Text(
                        'No symptoms found',
                        style: EcliniqTextStyles.responsiveBodyMediumProminent(context)
                            .copyWith(color: Colors.grey),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredSymptoms.length,
                    itemBuilder: (context, index) {
                      final symptom = filteredSymptoms[index];
                      return _buildSymptomButton(
                        context,
                        symptom['title'] as String,
                        symptom['icon'] as EcliniqIcons,
                        () {
                          // Handle symptom tap
                        },
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomButton(
    BuildContext context,
    String title,
    EcliniqIcons icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFfF8FAFF),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2372EC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      icon.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        24.0, // adjusted size for icon inside the circle
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        24.0,
                      ),
                       colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
                ),
                EcliniqText(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EcliniqTextStyles.responsiveBodyMediumProminent(context)
                      .copyWith(
                        color: const Color(0xff424242),
                        fontWeight: FontWeight.w400,
                        fontSize: 12, // slightly smaller font for grid
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
