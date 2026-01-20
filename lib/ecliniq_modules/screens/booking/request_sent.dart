import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/booking_confirmed_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/appointment_detail_item.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppointmentRequestScreen extends StatefulWidget {
  final String? doctorName;
  final String? doctorSpecialization;
  final String selectedSlot;
  final String selectedDate;
  final String? hospitalAddress;
  final String? tokenNumber;
  final String patientName;
  final String patientSubtitle;
  final String patientBadge;

  // Payment details (optional)
  final String? merchantTransactionId;
  final String? paymentMethod;
  final double? totalAmount;
  final double? walletAmount;
  final double? gatewayAmount;

  const AppointmentRequestScreen({
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
  });

  @override
  State<AppointmentRequestScreen> createState() =>
      _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  @override
  void initState() {
    super.initState();
    _makeApiCall();
  }

  Future<void> _makeApiCall() async {
    await Future.delayed(const Duration(seconds: 30000000));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmedScreen(
            doctorName: widget.doctorName,
            doctorSpecialization: widget.doctorSpecialization,
            selectedSlot: widget.selectedSlot,
            selectedDate: widget.selectedDate,
            hospitalAddress: widget.hospitalAddress,
            tokenNumber: widget.tokenNumber,
            patientName: widget.patientName,
            patientSubtitle: widget.patientSubtitle,
            patientBadge: widget.patientBadge,
            merchantTransactionId: widget.merchantTransactionId,
            paymentMethod: widget.paymentMethod,
            totalAmount: widget.totalAmount,
            walletAmount: widget.walletAmount,
            gatewayAmount: widget.gatewayAmount,
          ),
        ),
      );
    }
  }

  void _handleOkPressed() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                    SvgPicture.asset(EcliniqIcons.appointment1.assetPath, 
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 240.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 185.0),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Appointment Request',
                      style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                        color: Color(0xff424242),
                      ),
                    ),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'sent to ',
                        style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                        children: [
                          TextSpan(
                            text: widget.doctorName ?? 'Doctor',
                            style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                              color: Color(0xff0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ),

  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9E6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFBE8B00),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.requestedIcon.assetPath,
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Your booking request will be confirmed once the doctor approves it. You will receive your token number details via WhatsApp and SMS.',
                              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                color: Color(0xff0D47A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xffB8B8B8),
                          width: 0.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Column(
                          children: [
                            AppointmentDetailItem(
                              iconAssetPath: EcliniqIcons.userBlue.assetPath,
                              title: widget.patientName,
                              subtitle: widget.patientSubtitle,
                              badge: widget.patientBadge,
                              showEdit: false,
                            ),
                            Divider(
                              thickness: 0.5,
                              color: Color(0xffB8B8B8),
                              indent: 15,
                              endIndent: 15,
                            ),
                            AppointmentDetailItem(
                              iconAssetPath: EcliniqIcons.calendar.assetPath,
                              title: widget.selectedSlot,
                              subtitle: widget.selectedDate,
                              showEdit: false,
                            ),
                            Divider(
                              thickness: 0.5,
                              color: Color(0xffB8B8B8),
                              indent: 15,
                              endIndent: 15,
                            ),
                            AppointmentDetailItem(
                              iconAssetPath:
                                  EcliniqIcons.hospitalBuilding.assetPath,
                              title: 'In-Clinic Consultation',
                              subtitle:
                                  widget.hospitalAddress ??
                                  'Address not available',
                              showEdit: false,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  ],
                ),
              ),
            ),

            // Fixed OK button at bottom
            Container(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: BoxDecoration(color: Colors.white),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: EcliniqTextStyles.getResponsiveButtonHeight(
                    context,
                    baseHeight: 52.0,
                  ),
                  child: ElevatedButton(
                    onPressed: _handleOkPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,

                      side: BorderSide(color: Color(0xff8E8E8E), width: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ok',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff424242),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
