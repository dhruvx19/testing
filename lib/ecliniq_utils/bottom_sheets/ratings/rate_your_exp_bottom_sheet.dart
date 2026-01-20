import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class RatingBottomSheet extends StatefulWidget {
  final int? initialRating;
  final String doctorName;
  final String appointmentId;
  final Function(int rating)? onRatingSubmitted;
  final VoidCallback? onRefetch;

  const RatingBottomSheet({
    super.key,
    this.initialRating,
    required this.doctorName,
    required this.appointmentId,
    this.onRatingSubmitted,
    this.onRefetch,
  });

  /// Static method to show the bottom sheet
  static Future<int?> show({
    required BuildContext context,
    int? initialRating,
    required String doctorName,
    required String appointmentId,
    Function(int rating)? onRatingSubmitted,
    VoidCallback? onRefetch,
  }) {
    // Don't allow opening if rating already exists
    if (initialRating != null && initialRating > 0) {
      return Future.value(null);
    }
    
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => RatingBottomSheet(
        initialRating: initialRating,
        doctorName: doctorName,
        appointmentId: appointmentId,
        onRatingSubmitted: onRatingSubmitted,
        onRefetch: onRefetch,
      ),
    );
  }

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  int _tempRating = 0;
  bool _isSubmitting = false;
  bool _isButtonPressed = false;
  final _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _tempRating = widget.initialRating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EcliniqTextStyles.getResponsivePadding(context, 16),
        EcliniqTextStyles.getResponsivePadding(context, 16),
        EcliniqTextStyles.getResponsivePadding(context, 16),
        MediaQuery.of(context).viewInsets.bottom + EcliniqTextStyles.getResponsivePadding(context, 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          ),
          Text(
            'How was your Experience with ${widget.doctorName}?',
            style:  EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
       
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          ),
          _buildRatingStars(),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
          ),
          _buildSubmitButton(),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 2),
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          width: double.infinity,
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Rate your Experience :',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2372EC),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
              ),
              Row(
                children: List.generate(5, (index) {
                  final filled = index < _tempRating;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _tempRating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                        context,
                        right: 18,
                        top: 0,
                        bottom: 0,
                        left: 0,
                      ),
                      child: SvgPicture.asset(
                        filled
                            ? EcliniqIcons.starRateExp.assetPath
                            : EcliniqIcons.starRateExpUnfilled.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                        height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRating() async {
    if (_tempRating == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        Navigator.of(context).pop();
        return;
      }

      final res = await _appointmentService.rateAppointment(
        appointmentId: widget.appointmentId,
        rating: _tempRating,
        authToken: authToken,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // Call the callback if provided
        if (widget.onRatingSubmitted != null) {
          widget.onRatingSubmitted!(_tempRating);
        }

        // Refetch appointment details to get updated rating
        if (widget.onRefetch != null) {
          widget.onRefetch!();
        }

        // Close bottom sheet first
        Navigator.of(context).pop(_tempRating);

        // Show thank you dialog immediately after submission
        if (mounted) {
          _showThankYouDialog();
        }

        // Show success snackbar after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
       
            CustomSuccessSnackBar.show(
              context: context,
              title: 'Rating Submitted',
              subtitle: res['message']?.toString() ?? 'Thank you for your feedback!',
              duration: const Duration(seconds: 3),
      
          );
        }
      } else {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Failed to submit rating',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF3EAF3F),
              size: 64,
            ),
            const SizedBox(height: 16),
             Text(
              'Thank You!',
              style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
             
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
             Text(
              'Your feedback helps us improve our services',
              textAlign: TextAlign.center,
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
           
                color: Color(0xFF8E8E8E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child:  Text(
              'OK',
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                
                fontWeight: FontWeight.w500,
                color: Color(0xFF2372EC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isButtonEnabled = _tempRating > 0 && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: GestureDetector(
        onTap: isButtonEnabled ? _submitRating : null,
        onTapDown: isButtonEnabled
            ? (_) {
                setState(() {
                  _isButtonPressed = true;
                });
              }
            : null,
        onTapUp: isButtonEnabled
            ? (_) {
                setState(() {
                  _isButtonPressed = false;
                });
              }
            : null,
        onTapCancel: isButtonEnabled
            ? () {
                setState(() {
                  _isButtonPressed = false;
                });
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: _isButtonPressed
                ? const Color(0xFF0E4395)
                : isButtonEnabled
                    ? EcliniqButtonType.brandPrimary.backgroundColor(context)
                    : EcliniqButtonType.brandPrimary.disabledBackgroundColor(
                        context,
                      ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSubmitting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                Text(
                  'Submit Feedback',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: _isButtonPressed
                        ? Colors.white
                        : isButtonEnabled
                            ? Colors.white
                            : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: isButtonEnabled ? Colors.white : Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
