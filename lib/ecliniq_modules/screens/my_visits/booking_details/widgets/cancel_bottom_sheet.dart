import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class CancelBottomSheet extends StatefulWidget {
  final String appointmentId;
  final VoidCallback? onCancelled;

  const CancelBottomSheet({
    super.key,
    required this.appointmentId,
    this.onCancelled,
  });

  @override
  State<CancelBottomSheet> createState() => _CancelBottomSheetState();
}

class _CancelBottomSheetState extends State<CancelBottomSheet> {
  bool _isLoading = false;
  final _appointmentService = AppointmentService();

  Future<void> _handleCancel() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        if (mounted) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Authentication Error',
            subtitle: 'Authentication required. Please login again.',
            duration: const Duration(seconds: 4),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final response = await _appointmentService.cancelAppointment(
        appointmentId: widget.appointmentId,
        authToken: authToken,
      );

      if (!mounted) return;

      bool isSuccess = response.success;
      if (response.data != null) {
        isSuccess = isSuccess && response.data!.success;
      }

      if (isSuccess) {
        CustomSuccessSnackBar.show(
          context: context,
          title: 'Booking Cancelled',
          subtitle: 'Your appointment has been cancelled successfully',
          duration: const Duration(seconds: 3),
        );
        // Call onCancelled BEFORE pop so parent navigates from its own live context
        widget.onCancelled?.call();
        Navigator.of(context).pop();
      } else {
        String errorMessage = response.message;
        if (response.data != null) {
          if (response.data!.errors != null) {
            errorMessage = response.data!.errors.toString();
          } else if (response.data!.message != null) {
            errorMessage = response.data!.message.toString();
          }
        }

        if (mounted) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Cancellation Failed',
            subtitle: errorMessage,
            duration: const Duration(seconds: 4),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Error',
          subtitle: 'Failed to cancel appointment: $e',
          duration: const Duration(seconds: 4),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(16)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.only(top: 22, right: 16, left: 16, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            EcliniqIcons.cancelGif.assetPath,
          ),
          const SizedBox(height: 12),
          EcliniqText(
            'Are you sure you want cancel the booking?',
            style:
                EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          EcliniqText(
            'You can also change this booking at any time. Please note that the Service Fee and Tax are non-refundable if you cancel.',
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _handleCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Color(0xFFEB8B85), width: 0.5),
                        color: Color(0xFFFFF8F8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _isLoading
                            ? EcliniqLoader(
                                size: 20,
                                color: const Color(0xffF04248),
                              )
                            : Text(
                                'Yes',
                                style: EcliniqTextStyles.responsiveHeadlineMedium(
                                        context)
                                    .copyWith(
                                  color: Color(0xffF04248),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Color(0xff8E8E8E), width: 0.5),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No',
                            style: EcliniqTextStyles.responsiveHeadlineMedium(
                                    context)
                                .copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
