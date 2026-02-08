import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/appointment_detail_item.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/confirmed.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/requested.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/cancelled.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/booking_details/completed.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String? doctorName;
  final String? doctorSpecialization;
  final String selectedSlot;
  final String selectedDate;
  final String? hospitalAddress;
  final String? tokenNumber;
  final String patientName;
  final String patientSubtitle;
  final String patientBadge;

  final String? merchantTransactionId;
  final String? paymentMethod;
  final double? totalAmount;
  final double? walletAmount;
  final double? gatewayAmount;

  final String? appointmentId;
  final String? bookingStatus;

  const BookingConfirmedScreen({
    super.key,
    this.doctorName,
    this.doctorSpecialization,
    required this.selectedSlot,
    required this.selectedDate,
    this.hospitalAddress,
    this.tokenNumber,
    required this.patientName,
    required this.patientSubtitle,
    required this.patientBadge,
    this.merchantTransactionId,
    this.paymentMethod,
    this.totalAmount,
    this.walletAmount,
    this.gatewayAmount,
    this.appointmentId,
    this.bookingStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                context,
                16.0,
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                  SvgPicture.asset(
                    EcliniqIcons.appointment2.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      185.0,
                    ),
                    height: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      185.0,
                    ),
                  ),

                  Text(
                    'Booking Confirmed',
                    style: EcliniqTextStyles.responsiveHeadlineXLarge(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'With ',
                      style: EcliniqTextStyles.responsiveHeadlineXLarge(
                        context,
                      ).copyWith(color: Color(0xff424242)),
                      children: [
                        TextSpan(
                          text: doctorName ?? 'Doctor',
                          style: EcliniqTextStyles.responsiveHeadlineXLarge(
                            context,
                          ).copyWith(color: Color(0xff0D47A1)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      24.0,
                    ),
                  ),

                  if (tokenNumber != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                        context,
                        8.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2FFF3),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            8.0,
                          ),
                        ),
                        border: Border.all(
                          color: const Color(0xFF2E7D32),
                          width: EcliniqTextStyles.getResponsiveSize(
                            context,
                            0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your Token Number',
                            style: EcliniqTextStyles.responsiveHeadlineXLMedium(
                              context,
                            ).copyWith(color: Color(0xff424242)),
                          ),
                          SizedBox(
                            height: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              2.0,
                            ),
                          ),
                          Text(
                            tokenNumber!,
                            style: EcliniqTextStyles.responsiveHeadlineXXLarge(
                              context,
                            ).copyWith(color: Color(0xFF3EAF3F)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        24.0,
                      ),
                    ),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Color(0xffB8B8B8),
                        width: EcliniqTextStyles.getResponsiveSize(
                          context,
                          0.5,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12.0,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                        context,
                        top: 10.0,
                      ),
                      child: Column(
                        children: [
                          AppointmentDetailItem(
                            iconAssetPath: EcliniqIcons.userBlue.assetPath,
                            title: patientName,
                            subtitle: patientSubtitle,
                            badge: patientBadge,
                            showEdit: false,
                          ),
                          Divider(
                            thickness: EcliniqTextStyles.getResponsiveSize(
                              context,
                              0.5,
                            ),
                            color: Color(0xffB8B8B8),
                            indent: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              15.0,
                            ),
                            endIndent: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              15.0,
                            ),
                          ),
                          AppointmentDetailItem(
                            iconAssetPath: EcliniqIcons.calendar.assetPath,
                            title: selectedSlot,
                            subtitle: selectedDate,
                            showEdit: false,
                          ),
                          Divider(
                            thickness: EcliniqTextStyles.getResponsiveSize(
                              context,
                              0.5,
                            ),
                            color: Color(0xffB8B8B8),
                            indent: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              15.0,
                            ),
                            endIndent: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              15.0,
                            ),
                          ),
                          AppointmentDetailItem(
                            iconAssetPath:
                                EcliniqIcons.hospitalBuilding1.assetPath,
                            title: 'In-Clinic Consultation',
                            subtitle:
                                hospitalAddress ?? 'Address not available',
                            showEdit: false,
                          ),
                          SizedBox(
                            height: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              4.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      20.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.all(
              EcliniqTextStyles.getResponsiveSize(context, 16),
            ),
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: EcliniqTextStyles.getResponsiveButtonHeight(
                  context,
                  baseHeight: 52.0,
                ),
                child: OutlinedButton(
                  onPressed: () {
                    if (appointmentId != null) {
                      Widget detailPage;
                      switch (bookingStatus) {
                        case 'requested':
                          detailPage = BookingRequestedDetail(appointmentId: appointmentId!);
                          break;
                        case 'cancelled':
                        case 'failed':
                          detailPage = BookingCancelledDetail(appointmentId: appointmentId!);
                          break;
                        case 'completed':
                          detailPage = BookingCompletedDetail(appointmentId: appointmentId!);
                          break;
                        default:
                          detailPage = BookingConfirmedDetail(appointmentId: appointmentId!);
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => detailPage),
                        (route) => route.isFirst,
                      );
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Color(0xFF96BFFF),
                      width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                    ),
                    backgroundColor: Color(0xffF2F7FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          4.0,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Details',
                        style: EcliniqTextStyles.responsiveHeadlineMedium(
                          context,
                        ).copyWith(color: Color(0xFF2372EC)),
                      ),
                      Transform.rotate(
                        angle: 3.14159,
                        child: SvgPicture.asset(
                          EcliniqIcons.backArrow.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            24.0,
                          ),
                          height: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            24.0,
                          ),
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF2372EC),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
