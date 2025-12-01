import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/booking_confirmed_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/appointment_detail_item.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
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
    await Future.delayed(const Duration(seconds: 5));

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
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  EcliniqIcons.appointment1.assetPath,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Appointment Request',
                style: EcliniqTextStyles.headlineXLarge.copyWith(
                  color: Color(0xff424242),
                ),
              ),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'sent to ',
                  style: EcliniqTextStyles.headlineXLarge.copyWith(
                    color: Color(0xff424242),
                  ),
                  children: [
                    TextSpan(
                      text: widget.doctorName ?? 'Doctor',
                      style: EcliniqTextStyles.headlineXLarge.copyWith(
                        color: Color(0xfff0d47a1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(6),
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
                        style: EcliniqTextStyles.titleXLarge.copyWith(
                          color: Color(0xff0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
                ),
                child: Column(
                  children: [
                    AppointmentDetailItem(
                      iconAssetPath: EcliniqIcons.user.assetPath,
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
                      iconAssetPath: EcliniqIcons.hospitalBuilding.assetPath,
                      title: 'In-Clinic Consultation',
                      subtitle:
                          widget.hospitalAddress ?? 'Address not available',
                      showEdit: false,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleOkPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ok',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
