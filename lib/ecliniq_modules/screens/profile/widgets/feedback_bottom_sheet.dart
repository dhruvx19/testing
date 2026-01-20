import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/ratings/thank_you.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class FeedbackBottomSheet extends StatefulWidget {
  const FeedbackBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FeedbackBottomSheet(),
    );
  }

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;
  bool _isButtonPressed = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _selectedRating > 0;

  Future<void> _submitFeedback() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    // TODO: Add your API call here
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 200));
      await _showThankYouSheet(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    }
  }

  Future<void> _showThankYouSheet(BuildContext context) async {
    await EcliniqBottomSheet.show(context: context, child: ThankYou());
  }

  Widget _buildSubmitButton() {
    final isButtonEnabled = _isFormValid && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTapDown: isButtonEnabled
            ? (_) => setState(() => _isButtonPressed = true)
            : null,
        onTapUp: isButtonEnabled
            ? (_) {
                setState(() => _isButtonPressed = false);
                _submitFeedback();
              }
            : null,
        onTapCancel: isButtonEnabled
            ? () => setState(() => _isButtonPressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isLoading
                ? const Color(0xff2372EC)
                : _isButtonPressed
                ? const Color(0xFF0E4395) // Pressed color
                : _isFormValid
                ? const Color(0xff2372EC) // Enabled color
                : const Color(0xffF9F9F9), // Disabled color
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: EcliniqLoader(size: 20, color: Colors.white),
                  )
                : Text(
                    'Submit Feedback',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
             
                      fontWeight: FontWeight.w600,
                      color: _isFormValid
                          ? Colors.white
                          : const Color(0xffD6D6D6),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
          bottom: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
             Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Send Feedback',
                style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
             
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),

            // Rating Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Rate your Experience :',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                 
                      fontWeight: FontWeight.w400,
                      color: Color(0xff2372EC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SvgPicture.asset(
                            index < _selectedRating
                                ? EcliniqIcons.starRateExp.assetPath
                                : EcliniqIcons.starRateExpUnfilled.assetPath,
                            width: 32,
                            height: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Feedback Text Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Tell us what you love about the app, or what we could do better.',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
               
                      color: Color(0xff626060),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Enter your feedback here...',
                      hintStyle: const TextStyle(color: Color(0xffD6D6D6)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xff8E8E8E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xff8E8E8E)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xff8E8E8E)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSubmitButton(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
