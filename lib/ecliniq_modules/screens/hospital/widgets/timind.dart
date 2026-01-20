import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class AppointmentTimingWidget extends StatelessWidget {
  final String time;
  final String days;
  final VoidCallback? onInquirePressed;

  const AppointmentTimingWidget({
    super.key,
    required this.time,
    required this.days,
    this.onInquirePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Appointment & OPD timing',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith( fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF0E4395)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        days,
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith( color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: onInquirePressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E4395),
                  side: const BorderSide(color: Color(0xFF0E4395)),
                ),
                child: const Text('Inquire Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
