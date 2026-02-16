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

  final List<Map<String, dynamic>> faqs = [
    {
      'question': 'What is Upchar-Q?',
      'answer':
          'Upchar-Q is a smart healthcare queue and appointment management app that helps patients book tokens, track their turn in real time, and reduce waiting time at hospitals and clinics.',
    },
    {
      'question': 'Do I need to create an account to use Upchar-Q?',
      'answer':
          'Yes — to use Upchar-Q, you need to create an account.\nYou sign up with your mobile number and verify it with a one-time password (OTP), which lets you book tokens, track your appointments, and receive real-time updates',
    },
    {
      'question': 'Is Upchar-Q free to use?',
      'answer':
          'Upchar-Q charges a small booking fee when you book a token or appointment.',
    },
    {
      'question': 'How do I ask a question on Upchar-Q?',
      'answer':
          'Questions can be asked with the help of the support centre on the application.',
    },
    {
      'question': 'Can I upload reports or images?',
      'answer':
          'Yes. You can upload medical reports, prescriptions, and images on Upchar-Q locally.',
    },
    {
      'question': 'Can I choose a specific doctor?',
      'answer':
          'Yes. You can select a specific doctor while booking your appointment, based on availability at the clinic or hospital.',
    },
    {
      'question': 'What does “queue” mean?',
      'answer':
          'A queue is the digital waiting line that shows the order in which patients will be seen by the doctor. Your position in the queue helps you know when your turn is likely to come.',
    },
    {
      'question': 'Why is my queue position delayed?',
      'answer':
          'Your queue position may be delayed due to longer consultations, emergency cases, walk-in patients, or a delay in the doctor’s schedule. Upchar Q updates the queue in real time and notifies you if there are any changes.',
    },
    {
      'question': 'What does “Token not available” mean?',
      'answer':
          'It means the doctor’s or clinic’s token limit for that session is already full. so no new tokens can be booked at the moment. You can try booking for another session or check back later.',
    },
    {
      'question': 'Can my appointment be rescheduled?',
      'answer':
          'Yes. You can reschedule your appointment based on the doctor\'s availability and clinic rules. Some rescheduling limits or timelines may apply, and you\'ll be notified if rescheduling is not allowed for a particular booking.',
    },
    {
      'question': 'What payment methods are supported?',
      'answer':
          'Upchar Q supports secure online payments through options such as UPI, debit cards, credit cards, and net banking. Supported payment options will be shown in the app during checkout.',
    },
    {
      'question': 'What if my payment fails?',
      'answer':
          'If payment fails, the amount is usually not deducted. If it is, it will be refunded automatically within a few days.',
    },
    {
      'question': 'Can I get a refund?',
      'answer':
          'Refunds will only be processed against provider-side cancelled consultations.',
    },
    {
      'question': 'Is my medical information safe?',
      'answer': 'Yes. Your data is stored locally and not shared anywhere.',
    },
    {
      'question': 'Will my information be shared?',
      'answer': 'No. Your health information remains private and confidential.',
    },
    {
      'question': 'The app is not working properly. What should I do?',
      'answer':
          'Try: • Restarting the app • Checking your internet connection • Updating the app. If the issue continues, contact support.',
    },
    {
      'question': 'I didn’t get a doctor response. What should I do?',
      'answer':
          'Check your queue status and notifications. If the issue persists, reach out to customer support.',
    },
    {
      'question': 'How do I contact support?',
      'answer':
          'You can reach support through the Help & Support section in the app.',
    },
    {
      'question': 'Can Upchar-Q be used for emergencies?',
      'answer':
          'No. Upchar-Q is not meant for medical emergencies. Please visit the nearest hospital or call emergency services.',
    },
    {
      'question': 'Can I use Upchar-Q for family members?',
      'answer': 'Yes. You can manage dependents.',
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
            "FAQ's",
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: const Color(0xff424242)),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16,
          vertical: 16,
        ),
        child: Column(
          children: List.generate(faqs.length, (index) {
            final faq = faqs[index];
            final isExpanded = expandedIndex == index;

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xffD6D6D6),
                      width: 0.5,
                    ),
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
                        left: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          12,
                        ),
                        right: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          12,
                        ),
                        top: 0,
                        bottom: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          8,
                        ),
                      ),
                      title: Text(
                        "${index + 1}. ${faq['question']}",
                        style:
                            EcliniqTextStyles.responsiveHeadlineZMedium(
                              context,
                            ).copyWith(
                              color: const Color(0xff424242),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      trailing: SvgPicture.asset(
                        isExpanded
                            ? EcliniqIcons.arrowUp.assetPath
                            : EcliniqIcons.arrowDown.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24,
                        ),
                        colorFilter: const ColorFilter.mode(
                          Color(0xff424242),
                          BlendMode.srcIn,
                        ),
                      ),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          expandedIndex = expanded ? index : null;
                        });
                      },
                      children: [
                        _buildRichAnswer(faq['answer'], faq['bold'] ?? []),
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
          }),
        ),
      ),
    );
  }

  /// Helper to render bold words inside text
  Widget _buildRichAnswer(String text, List<String> boldWords) {
    if (boldWords.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.start,
        style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
          color: const Color(0xff757575),
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      );
    }

    List<TextSpan> spans = [];
    String remaining = text;

    for (var word in boldWords) {
      if (!remaining.contains(word)) continue;

      final parts = remaining.split(word);

      spans.add(TextSpan(text: parts[0]));
      spans.add(
        TextSpan(
          text: word,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

      remaining = parts.sublist(1).join(word);
    }

    spans.add(TextSpan(text: remaining));

    return Text.rich(
      TextSpan(
        style: EcliniqTextStyles.responsiveHeadlineZMedium(context).copyWith(
          color: const Color(0xff424242),
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        children: spans,
      ),
      textAlign: TextAlign.start,
    );
  }
}
