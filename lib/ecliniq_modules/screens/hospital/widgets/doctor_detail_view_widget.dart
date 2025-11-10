import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../profile/my_doctors/model/doctor_details.dart';


class DoctorDetailView extends StatefulWidget {
  final FavouriteDoctor doctor;

  const DoctorDetailView({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailView> createState() => _DoctorDetailViewState();
}

class _DoctorDetailViewState extends State<DoctorDetailView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade800),
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: EcliniqText(
                          widget.doctor.profileInitial,
                          style: EcliniqTextStyles.bodyMedium.copyWith(
                            color: Colors.blue,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    if (widget.doctor.isVerified)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SvgPicture.asset('lib/ecliniq_icons/assets/Verified Check.svg', height: 24, width: 24,),
                      ),
                  ],
                ),
                SizedBox(width: 16,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EcliniqText(
                      widget.doctor.name,
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    EcliniqText(
                      widget.doctor.specialization,
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    EcliniqText(
                      widget.doctor.qualification,
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              spacing: 5,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    SvgPicture.asset(
                      'lib/ecliniq_icons/assets/Medical Kit.svg',
                      height: 24,
                      width: 24,
                    ),
                    EcliniqText(
                      '${widget.doctor.experienceYears} years of exp',
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Icon(Icons.circle, size: 7, color: Colors.grey),
                    Container(
                      height: 24,
                      width: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Color(0xffFEF9E6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 5,
                        children: [
                          SvgPicture.asset('lib/ecliniq_icons/assets/Star.svg'),
                          EcliniqText(
                            '${widget.doctor.rating}',
                            style: EcliniqTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xffBE8B00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.circle, size: 7, color: Colors.grey),
                    EcliniqText(
                      '₹${widget.doctor.fee}',
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 10,
                  children: [
                    SvgPicture.asset(
                      'lib/ecliniq_icons/assets/Appointment Remindar.svg',
                      height: 24,
                      width: 24,
                    ),
                    EcliniqText(
                      widget.doctor.availableTime,
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    EcliniqText(
                      '(${widget.doctor.availableDays})',
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.green.shade50,
              ),
              child: EcliniqText(
                '  ${widget.doctor.availableTokens} Token Available   ',
                style: EcliniqTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade200,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EcliniqText(
                          'Next Available',
                          style: EcliniqTextStyles.bodyMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        EcliniqText(
                          widget.doctor.nextAvailable,
                          style: EcliniqTextStyles.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () {},
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.blue.shade800,
                      ),
                      child: Center(
                        child: EcliniqText(
                          'Book Appointment',
                          style: EcliniqTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}