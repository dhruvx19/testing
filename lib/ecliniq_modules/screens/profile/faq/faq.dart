import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  int? expandedIndex;

  final List<Map<String, String>> faqs = [
    {
      'question': 'What is UpcharQ?',
      'answer':
          'UpcharQ is a smart healthcare queue and appointment management app that helps patients book tokens, track their turn in real time, and reduce waiting time at hospitals and clinics.',
    },
    {
      'question': 'Do I need to create an account to use UpcharQ?',
      'answer':
          'Yes, you need to create an account to book tokens and track your queue position. Registration is quick and easy using your mobile number.',
    },
    {
      'question': 'Is UpcharQ free to use?',
      'answer':
          'Yes, UpcharQ is free for patients to download and use. You can book tokens and track your queue without any charges.',
    },
    {
      'question': 'How do I ask a question on UpcharQ?',
      'answer':
          'You can contact support through the app\'s help section or reach out to the hospital/clinic directly through the provided contact options.',
    },
    {
      'question': 'Can I upload reports or images?',
      'answer':
          'Yes, you can upload medical reports and images when booking your token. This helps doctors review your case before the consultation.',
    },
    {
      'question': 'Can I choose a specific doctor?',
      'answer':
          'Yes, you can select your preferred doctor when booking a token, subject to their availability at the selected time slot.',
    },
    {
      'question': 'What does "queue" mean?',
      'answer':
          'A queue is the line of patients waiting for consultation. Your queue position shows how many patients are ahead of you.',
    },
    {
      'question': 'Why is my queue position delayed?',
      'answer':
          'Queue delays can occur due to emergency cases, longer consultations, or walk-in patients. You\'ll receive real-time updates on any changes.',
    },
    {
      'question': 'What does "Token not available" mean?',
      'answer':
          'This means all tokens for the selected doctor and time slot are fully booked. Please try a different time slot or another day.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'FAQ\'s',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16,
          vertical: 16,
        ),
        child: Column(
          children: List.generate(
            faqs.length,
            (index) {
              final faq = faqs[index];
              final isExpanded = expandedIndex == index;

              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveWidth(context, 8),
                      ),
                      border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding:
                            EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                          context,
                          horizontal: 12,
                          vertical: 0,
                        ),
                        childrenPadding: EdgeInsets.only(
                          left: EcliniqTextStyles.getResponsiveWidth(context, 12),
                          right: EcliniqTextStyles.getResponsiveWidth(context, 12),
                          top: EcliniqTextStyles.getResponsiveHeight(context, 0),
                          bottom:
                              EcliniqTextStyles.getResponsiveHeight(context, 12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveWidth(context, 12),
                          ),
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveWidth(context, 12),
                          ),
                        ),
                        title: Text(
                          '${index + 1}. ${faq['question']}',
                          style: EcliniqTextStyles.responsiveHeadlineZMedium(
                                  context)
                              .copyWith(
                            color: Color(0xff424242),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: SvgPicture.asset(
                          isExpanded
                              ? EcliniqIcons.arrowUp.assetPath
                              : EcliniqIcons.arrowDown.assetPath,
                          width:
                              EcliniqTextStyles.getResponsiveIconSize(context, 24),
                          height:
                              EcliniqTextStyles.getResponsiveIconSize(context, 24),
                          colorFilter: ColorFilter.mode(
                              Color(0xff424242), BlendMode.srcIn),
                        ),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            expandedIndex = expanded ? index : null;
                          });
                        },
                        children: [
                          Text(
                            faq['answer']!,
                            style: EcliniqTextStyles.responsiveTitleXLarge(context)
                                .copyWith(
                              color: Color(0xff757575),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < faqs.length - 1)
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}