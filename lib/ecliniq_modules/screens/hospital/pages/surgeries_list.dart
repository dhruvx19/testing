import 'dart:async';

import 'package:ecliniq/ecliniq_modules/screens/hospital/widgets/surgery_details.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

import '../../../../ecliniq_icons/icons.dart';

class SurgeryList extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const SurgeryList({super.key, this.onBackPressed});

  @override
  State<SurgeryList> createState() => _SurgeryListState();
}

class _SurgeryListState extends State<SurgeryList> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechHelper _speechHelper = SpeechHelper();
  bool get _isListening => _speechHelper.isListening;
  String _searchQuery = '';

  final List<Map<String, dynamic>> surgeries = [
    {
      'name': 'Appendectomy',
      'description':
          'Surgical removal of the appendix, usually performed to treat appendicitis.',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Hernia Repair Surgery',
      'description':
          'Correction of hernias in the abdomen or groin using open or laparoscopic techniques.',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Gallbladder Removal Surgery',
      'description':
          'Cholecystectomy, the surgical removal of the gallbladder, often performed due to gallstones.',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Knee Replacement Surgery',
      'description':
          'Total or partial knee arthroplasty to relieve pain and improve function in patients with knee damage..',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Knee Replacement',
      'description':
          'Surgical procedure to replace a damaged knee joint with an artificial prosthesis.',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Caesarean Section',
      'description':
          'Surgical delivery of a baby through an incision in the mother\'s abdomen and uterus.',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Tonsillectomy',
      'description':
          'Surgical removal of the tonsils, often performed to treat chronic tonsillitis or breathing problems.',
      'icon': EcliniqIcons.scissors,
    },
    {
      'name': 'Coronary Bypass',
      'description':
          'Heart surgery to improve blood flow to the heart by creating new routes around blocked arteries.',
      'icon': EcliniqIcons.scissors,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _speechHelper.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speechHelper.initSpeech(
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
      mounted: () => mounted,
    );
  }

  void _startListening() async {
    await _speechHelper.startListening(
      onResult: _onSpeechResult,
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
        }
      },
      mounted: () => mounted,
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _stopListening() async {
    await _speechHelper.stopListening(
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {
      _searchQuery = result.recognizedWords.toLowerCase();
    });

    if (result.finalResult) {
      _stopListening();
    }
  }

  void _toggleVoiceSearch() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> get _filteredSurgeries {
    if (_searchQuery.isEmpty) {
      return surgeries;
    }
    return surgeries.where((surgery) {
      final name = surgery['name'].toString().toLowerCase();
      final description = surgery['description'].toString().toLowerCase();
      return name.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF9F9F9),
      appBar: AppBar(
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 58.0),
        titleSpacing: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'List of Surgeries',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveHeight(context, 0.2),
          ),
          child: Container(
            color: Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveHeight(context, 0.5),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            height: EcliniqTextStyles.getResponsiveButtonHeight(
              context,
              baseHeight: 52.0,
            ),
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 10,
              vertical: 0,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              border: Border.all(
                color: Color(0xff626060),
                width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
              ),
            ),
            child: Row(
              spacing: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SvgPicture.asset(
                  EcliniqIcons.magnifierMyDoctor.assetPath,
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: 'Search Surgeries',
                      hintStyle:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            color: Color(0xff8E8E8E),
                            fontWeight: FontWeight.w400,
                          ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleVoiceSearch,
                  child: Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                      context,
                      right: 8,
                      top: 0,
                      bottom: 0,
                      left: 0,
                    ),
                    child: SvgPicture.asset(
                      EcliniqIcons.microphone.assetPath,
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        32,
                      ),
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        32,
                      ),
                      colorFilter: _isListening
                          ? const ColorFilter.mode(
                              Color(0xFF2372EC),
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredSurgeries.isEmpty
                ? Center(
                    child: Text(
                      'No surgeries found',
                      style: EcliniqTextStyles.responsiveBodyMedium(
                        context,
                      ).copyWith(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSurgeries.length,
                    itemBuilder: (context, index) {
                      return SurgeryDetail(surgery: _filteredSurgeries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
