import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/search_bar.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SymptomsPage extends StatefulWidget {
  const SymptomsPage({super.key});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  String _searchQuery = '';
  final Map<String, bool> _expandedCategories = {};

  final List<Map<String, dynamic>> _commonSymptoms = [
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
    {'title': 'Hair Related Problem', 'icon': EcliniqIcons.hairCare},
    {'title': 'Pregnancy Related', 'icon': EcliniqIcons.pregnancyCare},
    {'title': 'Dental Care', 'icon': EcliniqIcons.dentalCare},
    {'title': 'Joint Pain', 'icon': EcliniqIcons.jointCare},
    {'title': 'Blood Pressure', 'icon': EcliniqIcons.bloodPressure},
  ];

  final Map<String, String> _symptomSpecialtyMap = {
    // General & Common
    'Fever / Chills': 'General Physician, Pediatrician',
    'Fever/Chills': 'General Physician, Pediatrician', // Mapping for common symptoms widget
    'Cold & Cough': 'General Physician, Pediatrician, Pulmonologist',
    'Sore Throat': 'General Physician, ENT',
    'Body Pain': 'General Physician, Orthopedic',
    'Weakness / Fatigue': 'General Physician, Diabetologist, Endocrinologist',
    'Headache': 'General Physician, Neurologist',
    'Stomach Pain': 'Gastroenterologist', // Mapping for common symptoms widget
    'Back Pain': 'Orthopedic', // Mapping for common symptoms widget
    'Dizziness / Fainting': 'General Physician, Cardiologist, Neurologist',
    'Viral Infection Symptoms': 'General Physician',
    'High or Low Blood Pressure': 'General Physician, Cardiologist',
    'Blood Pressure': 'General Physician, Cardiologist', // Mapping for common symptoms widget
    'General Health Check-up': 'General Physician',

    // Child Health
    'Vomiting or Diarrhea (Child)': 'Pediatrician',
    'Poor Feeding': 'Pediatrician',
    'Excessive Crying / Irritability': 'Pediatrician',
    'Skin Rash (Child)': 'Pediatrician, Dermatologist',
    'Growth or Development Concerns': 'Pediatrician',
    'Vaccination': 'Pediatrician',

    // Women's Health
    'Irregular or Painful Periods': 'Gynaecologist',
    'Periods Problem': 'Gynaecologist', // Mapping for common symptoms widget
    'Heavy Menstrual Bleeding': 'Gynaecologist',
    'Vaginal Discharge / Infection': 'Gynaecologist',
    'Pelvic or Lower Abdominal Pain': 'Gynaecologist',
    'Pregnancy Care': 'Gynaecologist',
    'Pregnancy Related': 'Gynaecologist', // Mapping for common symptoms widget
    'Menopause Symptoms': 'Gynaecologist',
    'Breast Lump or Pain': 'Gynaecologist, Oncologist',
    'Fertility Concerns': 'Gynaecologist, Endocrinologist',

    // Dental
    'Toothache': 'Dentist',
    'Cavities': 'Dentist',
    'Bleeding or Swollen Gums': 'Dentist',
    'Mouth Ulcers': 'Dentist',
    'Bad Breath': 'Dentist',
    'Jaw Pain': 'Dentist',
    'Tooth Sensitivity': 'Dentist',
    'Wisdom Tooth Pain': 'Dentist',
    'Dental Care': 'Dentist', // Mapping for common symptoms widget

    // Skin & Hair
    'Skin & Hair': 'Dermatologist',
    'Skin Rash /Itching': 'Dermatologist', // Mapping for common symptoms widget
    'Hair Related Problem': 'Dermatologist', // Mapping for common symptoms widget

    // Category mappings (for categories with no symptoms)
    'ENT Health': 'ENT',
    'Eyes Health': 'Ophthalmologist',
    'Heart & Chest': 'Cardiologist',
    'Bones & Movement': 'Orthopedic',
    'Lungs & Breathing': 'Pulmonologist',
    'Kidney & Urinary': 'Urologist',
    'Stomach & Liver': 'Gastroenterologist',
    'Brain & Mental Health': 'Neurologist',

    // ENT
    'Ear Pain or Discharge': 'ENT',
    'Hearing Loss': 'ENT',
    'Blocked Nose / Sinus Pain': 'ENT',
    'Tonsil or Throat Pain': 'ENT',
    'Voice Change / Hoarseness': 'ENT',
    'Vertigo / Balance Issues': 'ENT, Neurologist',
    'Nosebleeds': 'ENT',

    // Eyes
    'Red or Itchy Eyes': 'Ophthalmologist',
    'Blurred Vision': 'Ophthalmologist',
    'Eye Pain or Swelling': 'Ophthalmologist',
    'Watering or Discharge': 'Ophthalmologist',
    'Night Vision Problems': 'Ophthalmologist',
    'Eye Infection': 'Ophthalmologist',
    'Light Sensitivity': 'Ophthalmologist',
    'Sudden Vision Loss': 'Ophthalmologist',

    // Heart & Chest
    'Chest Pain or Pressure': 'Cardiologist',
    'Palpitations (Fast Heartbeat)': 'Cardiologist',
    'Shortness of Breath': 'Cardiologist, Pulmonologist',
    'Leg or Foot Swelling': 'Cardiologist, Nephrologist',
    'Fatigue on Exertion': 'Cardiologist',

    // Bones & Movement
    'Back or Neck Pain': 'Orthopedic, Physiotherapist',
    'Joint Pain or Swelling': 'Orthopedic',
    'Joint Pain': 'Orthopedic', // Mapping for common symptoms widget
    'Knee Pain': 'Orthopedic',
    'Muscle Pain or Stiffness': 'Orthopedic, Physiotherapist',
    'Difficulty Walking': 'Orthopedic, Neurologist',
    'Sports Injury': 'Orthopedic, Physiotherapist',
    'Fracture or Trauma': 'Orthopedic',
    'Shoulder Pain': 'Orthopedic',

    // Diabetes & Hormones
    'High or Low Blood Sugar': 'Diabetologist',
    'Excessive Thirst or Urination': 'Diabetologist, Endocrinologist',
    'Slow Wound Healing': 'Diabetologist',
    'Numbness in Feet': 'Diabetologist, Neurologist',
    'Thyroid Problems': 'Endocrinologist',
    'Weight Gain or Loss': 'Endocrinologist',
    'Hormonal Imbalance': 'Endocrinologist',
    'PCOS Symptoms': 'Endocrinologist, Gynaecologist',

    // Lungs & Breathing
    'Persistent Cough': 'Pulmonologist',
    'Breathing Difficulty': 'Pulmonologist',
    'Wheezing / Asthma': 'Pulmonologist',
    'Chest Congestion': 'Pulmonologist',
    'Cough with Blood': 'Pulmonologist',
    'Snoring / Sleep Apnea': 'Pulmonologist',

    // Kidney & Urinary
    'Burning Urination': 'Urologist',
    'Frequent Urination': 'Urologist',
    'Blood in Urine': 'Urologist, Nephrologist',
    'Kidney Stones': 'Urologist',
    'Reduced Urine Output': 'Nephrologist',
    'Foamy Urine': 'Nephrologist',
    'Kidney Pain': 'Nephrologist',
    'Prostate Issues': 'Urologist',

    // Stomach & Liver
    'Abdominal Pain': 'Gastroenterologist',
    'Gas / Acidity / Heartburn': 'Gastroenterologist',
    'Nausea or Vomiting': 'Gastroenterologist',
    'Constipation or Diarrhea': 'Gastroenterologist',
    'Blood in Stool': 'Gastroenterologist, Oncologist',
    'Jaundice': 'Gastroenterologist, Hepatologist',
    'Fatty Liver / Liver Pain': 'Hepatologist',

    // Brain & Mental Health
    'Severe Headache / Migraine': 'Neurologist',
    'Seizures / Fits': 'Neurologist',
    'Numbness or Tingling': 'Neurologist',
    'Weakness or Paralysis': 'Neurologist',
    'Tremors': 'Neurologist',
    'Memory Loss': 'Neurologist',
    'Anxiety / Stress': 'Psychiatrist',
    'Depression / Low Mood': 'Psychiatrist',
    'Sleep Problems': 'Psychiatrist',
    'Sleep Problem': 'Psychiatrist', // Mapping for common symptoms widget (singular)
    'Addiction Issues': 'Psychiatrist',

    // Sexual Health
    'Erectile Dysfunction': 'Sexologist, Urologist',
    'Premature Ejaculation': 'Sexologist',
    'Low Libido': 'Sexologist, Endocrinologist',
    'Sexual Anxiety': 'Sexologist',
    'Relationship Intimacy Issues': 'Sexologist',

    // Blood Disorders
    'Anemia / Low Hemoglobin': 'Haematologist',
    'Excessive Bleeding': 'Haematologist',
    'Easy Bruising': 'Haematologist',
    'Blood Clotting Issues': 'Haematologist',
    'Recurrent Infections': 'Haematologist',

    // Cancer Care
    'Lump or Swelling': 'Oncologist',
    'Unexplained Weight Loss': 'Oncologist',
    'Persistent Pain': 'Oncologist',
    'Non-Healing Wounds': 'Oncologist',
    'Cancer Follow-up': 'Oncologist',
    'Chemotherapy Consultation': 'Oncologist',

    // Imaging & Alternative Care
    'Imaging (X-ray, CT, MRI, Ultrasound)': 'Radiologist',
    'Scan Report Review': 'Radiologist',
    'Chronic Conditions': 'Homeopathy',
    'Allergies': 'Homeopathy',
    'Digestive Imbalance': 'Ayurvedic',
    'Stress or Sleep Issues': 'Ayurvedic',
    'Lifestyle Disorders': 'Ayurvedic',
  };

  final Map<String, List<String>> _categorySymptoms = {
    'Child Health': [
      'Vomiting or Diarrhea (Child)',
      'Poor Feeding',
      'Excessive Crying / Irritability',
      'Skin Rash (Child)',
      'Growth or Development Concerns',
      'Vaccination',
    ],
    'Women\'s Health': [
      'Irregular or Painful Periods',
      'Heavy Menstrual Bleeding',
      'Vaginal Discharge / Infection',
      'Pelvic or Lower Abdominal Pain',
      'Pregnancy Care',
      'Menopause Symptoms',
      'Breast Lump or Pain',
      'Fertility Concerns',
    ],
    'Dental Care': [
      'Toothache',
      'Cavities',
      'Bleeding or Swollen Gums',
      'Mouth Ulcers',
      'Bad Breath',
      'Jaw Pain',
      'Tooth Sensitivity',
      'Wisdom Tooth Pain',
    ],
    'Diabetes & Hormones': [
      'High or Low Blood Sugar',
      'Excessive Thirst or Urination',
      'Slow Wound Healing',
      'Numbness in Feet',
      'Thyroid Problems',
      'Weight Gain or Loss',
      'Hormonal Imbalance',
      'PCOS Symptoms',
    ],
    'Cancer Care': [
      'Lump or Swelling',
      'Unexplained Weight Loss',
      'Persistent Pain',
      'Non-Healing Wounds',
      'Cancer Follow-up',
      'Chemotherapy Consultation',
    ],
    'Skin & Hair': [],
    'ENT Health': [],
    'Eyes Health': [],
    'Heart & Chest': [],
    'Bones & Movement': [],
    'Lungs & Breathing': [],
    'Kidney & Urinary': [],
    'Stomach & Liver': [],
    'Brain & Mental Health': [],
  };

  void _handleSymptomTap(String symptom) {
    // 1. Get specialties from map
    final specialtiesStr = _symptomSpecialtyMap[symptom];
    if (specialtiesStr != null) {
      // 2. Pick first one
      final firstSpecialty = specialtiesStr.split(',').first.trim();
      // 3. Navigate
      EcliniqRouter.push(
        SpecialityDoctorsList(initialSpeciality: firstSpecialty),
      );
    } else {
      // Fallback: Try to use the symptom name itself or handle appropriately
      // For now, we'll log or do nothing.
    }
  }

  List<Map<String, dynamic>> get _filteredCommonSymptoms {
    if (_searchQuery.isEmpty) return _commonSymptoms;
    return _commonSymptoms.where((symptom) {
      final title = (symptom['title'] as String).toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Map<String, List<String>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categorySymptoms;

    final filtered = <String, List<String>>{};
    _categorySymptoms.forEach((category, symptoms) {
      if (category.toLowerCase().contains(_searchQuery.toLowerCase())) {
        filtered[category] = symptoms;
      } else {
        final matchingSymptoms = symptoms.where((symptom) {
          return symptom.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (matchingSymptoms.isNotEmpty) {
          filtered[category] = matchingSymptoms;
        }
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _filteredCommonSymptoms.isNotEmpty || _filteredCategories.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveSize(context, 58.0),
        titleSpacing: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Symptoms',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
          child: Transform.translate(
            offset: Offset(
              0,
              -EcliniqTextStyles.getResponsiveSize(context, 8.0),
            ),
            child: Container(
              color: Color(0xFFB8B8B8),
              height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
            ),
          ),
        ),
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
            child: !hasResults
                ? Center(
                    child: Text(
                      'No symptoms found',
                      style: EcliniqTextStyles.responsiveBodyMediumProminent(
                        context,
                      ).copyWith(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_filteredCommonSymptoms.isNotEmpty) ...[
                          EcliniqText(
                            'General & Common',
                            style:
                                EcliniqTextStyles.responsiveBodyMediumProminent(
                                  context,
                                ).copyWith(
                                  color: const Color(0xff424242),
                                  fontWeight: FontWeight.w600,
                                  fontSize: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                                ),
                          ),
                          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
                          Wrap(
                            spacing: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
                            runSpacing: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
                            children: _filteredCommonSymptoms.map((symptom) {
                              return _buildSymptomButton(
                                context,
                                symptom['title'] as String,
                                symptom['icon'] as EcliniqIcons,
                                () => _handleSymptomTap(
                                  symptom['title'] as String,
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Category sections
                        ..._filteredCategories.entries.map((entry) {
                          return _buildCategorySection(
                            context,
                            entry.key,
                            entry.value,
                          );
                        }),
                      ],
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
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
        ),
        child: Container(
          width: EcliniqTextStyles.getResponsiveWidth(context, 120.0),
          height: EcliniqTextStyles.getResponsiveHeight(context, 124.0),
          decoration: BoxDecoration(
            color: Color(0xFfF8FAFF),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
            ),
          ),
          child: Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
              context,
              10.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
                ),
                Container(
                  width: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF2372EC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      icon.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        48.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        48.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Flexible(
                  child: EcliniqText(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<String> symptoms,
  ) {
    // If searching, default to expanded. Otherwise use mapped state or default to true if symptoms present
    final isExpanded = _searchQuery.isNotEmpty
        ? true
        : (_expandedCategories[category] ?? symptoms.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          // If no symptoms, navigate to speciality; otherwise toggle expand/collapse
          onTap: symptoms.isEmpty
              ? () => _handleSymptomTap(category)
              : () {
                  setState(() {
                    if (_searchQuery.isEmpty) {
                      _expandedCategories[category] = !isExpanded;
                    }
                  });
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: EcliniqText(
                  category,
                  style:
                      EcliniqTextStyles.responsiveBodyMediumProminent(
                        context,
                      ).copyWith(
                        color: const Color(0xff424242),
                        fontWeight: FontWeight.w600,
                        fontSize: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                      ),
                ),
              ),
              if (symptoms.isEmpty)
                Transform.rotate(
                  angle: -90 * 3.14159 / 180,
                  child: SvgPicture.asset(
                    EcliniqIcons.arrowDown.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    colorFilter: ColorFilter.mode(
                      const Color(0xff424242),
                      BlendMode.srcIn,
                    ),
                  ),
                )
              else if (_searchQuery.isEmpty)
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0 : -0.25,
                  child: SvgPicture.asset(
                    EcliniqIcons.arrowDown.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    colorFilter: ColorFilter.mode(
                      const Color(0xff424242),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 6.0)),
        if (isExpanded && symptoms.isNotEmpty)
          ...symptoms.asMap().entries.map((entry) {
            final index = entry.key;
            final symptom = entry.value;
            final isLast = index == symptoms.length - 1;
            return _buildSymptomListItem(context, symptom, isLast);
          }),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
      ],
    );
  }

  Widget _buildSymptomListItem(
    BuildContext context,
    String symptom,
    bool isLast,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: () => _handleSymptomTap(symptom),
          child: Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              vertical: 6.0,
              horizontal: 0.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: EcliniqText(
                    symptom,
                    style:
                        EcliniqTextStyles.responsiveBodyMediumProminent(
                          context,
                        ).copyWith(
                          color: const Color(0xff424242),
                          fontWeight: FontWeight.w400,
                          fontSize: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const HorizontalDivider(color: Color(0xffD6D6D6)),
      ],
    );
  }
}
