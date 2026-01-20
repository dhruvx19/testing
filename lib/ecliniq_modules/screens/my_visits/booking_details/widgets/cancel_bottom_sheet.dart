import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please login again.'),
              backgroundColor: Colors.red,
            ),
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

      // Check both outer and inner success flags
      bool isSuccess = response.success;
      if (response.data != null) {
        // If inner data exists, check its success flag too
        isSuccess = isSuccess && response.data!.success;
      }

      if (isSuccess) {
        // Close the bottom sheet first
        Navigator.of(context).pop();
        
        // Fetch updated appointment details
        try {
          final detailResponse = await _appointmentService.getAppointmentDetail(
            appointmentId: widget.appointmentId,
            authToken: authToken,
          );

          if (!mounted) return;

          if (detailResponse.success && detailResponse.data != null) {
            // Convert API response to UI model
            final appointmentDetail = AppointmentDetailModel.fromApiData(
              detailResponse.data!,
            );

            // Navigate to cancelled detail page
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BookingCancelledDetail(
                    appointmentId: widget.appointmentId,
                    appointment: appointmentDetail,
                  ),
                ),
              );
            }
          } else {
            // If fetching details fails, still call the callback for backward compatibility
            widget.onCancelled?.call();
          }
        } catch (e) {
          // If fetching details fails, still call the callback for backward compatibility
          if (mounted) {
            widget.onCancelled?.call();
          }
        }
      } else {
        // Handle error
        String errorMessage = response.message;
        if (response.data != null) {
          if (response.data!.errors != null) {
            errorMessage = response.data!.errors.toString();
          } else if (response.data!.message != null) {
            errorMessage = response.data!.message.toString();
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $e'),
            backgroundColor: Colors.red,
          ),
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
            // fit: BoxFit.contain,
            // height: 115,
            // width: 115,
          ),
             const SizedBox(height: 12),
           EcliniqText(
            'Are you sure you want cancel the booking?',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
         
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
                        border: Border.all(color: Color(0xFFEB8B85), width: 0.5),
                        color: Color(0xFFFFF8F8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Yes',
                            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                              color: Color(0xffF04248),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xff8E8E8E), width: 0.5),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No',
                            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
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
