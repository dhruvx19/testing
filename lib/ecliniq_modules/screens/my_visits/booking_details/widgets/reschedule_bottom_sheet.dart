import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/widgets/common.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final AppointmentDetailModel appointment;

  const RescheduleBottomSheet({super.key, required this.appointment});

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(16)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 22, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(EcliniqIcons.reschedule.assetPath),
           const SizedBox(height: 8),
           EcliniqText(
            'Are you sure you want Reschedule the Confirmed Appointment?',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
         
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
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
                    onTap: () {
                      
                      final isAlreadyRescheduled =
                          widget.appointment.isRescheduled;
                      if (isAlreadyRescheduled) {
                        Navigator.pop(context, false);
                
                          CustomErrorSnackBar.show(
                            context: context,
                            title: 'Cannot Reschedule',
                            subtitle:
                                'This appointment has already been rescheduled. You cannot reschedule it again.',
                            duration: const Duration(seconds: 3),
                      
                        );
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xFF96BFFF),
                          width: 0.5,
                        ),
                        color: Color(0xFFF2F7FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Yes',
                            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                              color: Color(0xff2372EC),
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
                    onTap: () {
                      Navigator.pop(context, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xff8E8E8E),
                          width: 0.5,
                        ),
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
