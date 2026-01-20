import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/doctor_details.dart';

class DoctorInfoWidget extends StatefulWidget {
  final FavouriteDoctor doctor;

  const DoctorInfoWidget({super.key, required this.doctor});

  @override
  State<DoctorInfoWidget> createState() => _DoctorInfoWidgetState();
}

class _DoctorInfoWidgetState extends State<DoctorInfoWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: EcliniqTextStyles.getResponsiveWidth(context, 64),
                        height: EcliniqTextStyles.getResponsiveHeight(context, 64),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff96BFFF),
                            width: 0.5,
                          ),
                          color: Color(0xffF8FAFF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: EcliniqText(
                            widget.doctor.profileInitial,
                            style: EcliniqTextStyles.responsiveHeadlineXXXLarge(context).copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: 0,
                        child: SvgPicture.asset(
                          EcliniqIcons.verified.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          child: EcliniqText(
                            widget.doctor.name,
                            style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                            
                              fontWeight: FontWeight.w600,
                              color: Color(0xff424242),
                            ),
                          ),
                        ),
                        EcliniqText(
                          widget.doctor.specialization,
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424242),
                          ),
                        ),
                        EcliniqText(
                          widget.doctor.qualification,
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424242),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Color(0xfffff8f8),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        EcliniqIcons.heart.assetPath,
                        height: 20,
                        width: 20,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                spacing: 8,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.medicalKit.assetPath,
                        height: 24,
                        width: 24,
                      ),
                      EcliniqText(
                        '${widget.doctor.experienceYears} years of exp',
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      
                          fontWeight: FontWeight.w400,
                          color: Color(0xff626060),
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        size: EcliniqTextStyles.getResponsiveIconSize(context, 6),
                        color: Color(0xff8E8E8E),
                      ),
                      Container(
                        height: 24,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Color(0xffFEF9E6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            SvgPicture.asset(
                              EcliniqIcons.star.assetPath,
                              width: 18,
                              height: 18,
                            ),
                            EcliniqText(
                              '${widget.doctor.rating}',
                              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                fontWeight: FontWeight.w400,
                                color: Color(0xffBE8B00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        size: EcliniqTextStyles.getResponsiveIconSize(context, 6),
                        color: Color(0xff8E8E8E),
                      ),
                      EcliniqText(
                        '₹${widget.doctor.fee}',
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff626060),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      SvgPicture.asset(
                        'lib/ecliniq_icons/assets/Appointment Remindar.svg',
                        height: 24,
                        width: 24,
                        colorFilter: ColorFilter.mode(
                          Colors.grey.shade600,
                          BlendMode.srcIn,
                        ),
                      ),
                      EcliniqText(
                        widget.doctor.availableTime,
                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff626060),
                        ),
                      ),
                      EcliniqText(
                        '(${widget.doctor.availableDays})',
                        style:EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          
                          fontWeight: FontWeight.w400,
                          color: Color(0xff626060),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.mapPoint.assetPath,
                        height: 24,
                        width: 24,
                        colorFilter: ColorFilter.mode(
                          Colors.grey.shade600,
                          BlendMode.srcIn,
                        ),
                      ),
                      Flexible(
                        child: EcliniqText(
                          widget.doctor.location,
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                          
                            fontWeight: FontWeight.w400,
                            color: Color(0xff626060),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        height: 24,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Color(0xffF9F9F9),
                          border: Border.all(
                            color: Color(0xffB8B8B8),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: EcliniqText(
                            '${widget.doctor.distanceKm} km',
                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                             
                              fontWeight: FontWeight.w400,
                              color: Color(0xff424242),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xffF2FFF3),
                  borderRadius: BorderRadius.circular(6),
                ),

                child: Text(
                  '${widget.doctor.availableTokens} Token Available',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff3EAF3F),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xffF2FFF3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          'Queue Not Started',
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            color: Color(0xff3EAF3F),
                    
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4D2372EC),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          EcliniqRouter.push(
                            ClinicVisitSlotScreen(
                              doctorId: 'doctor.id',
                              hospitalId: 'widget.hospitalId',
                              doctorName: 'doctor.name',
                              doctorSpecialization:
                                  'doctor.specializations.isNotEmpty',
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2372EC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Book Appointment',
                          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                            color: Colors.white,

                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(height: 0.5, color: Color(0xffD6D6D6)),
            ],
          ),
        ),
      ),
    );
  }
}
