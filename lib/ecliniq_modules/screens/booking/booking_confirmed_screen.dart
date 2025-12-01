import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/widgets/appointment_detail_item.dart';
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
  
  // Payment details (optional)
  final String? merchantTransactionId;
  final String? paymentMethod;
  final double? totalAmount;
  final double? walletAmount;
  final double? gatewayAmount;

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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(
              width: 250,
              height: 200,
              child: Image.asset(
                EcliniqIcons.appointment2.assetPath,
                fit: BoxFit.contain,
              ),
            ),

            Text(
              'Booking Confirmed',
              style: EcliniqTextStyles.headlineXLarge.copyWith(
                color: Color(0xff424242),
              ),
            ),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'With ',
                style: EcliniqTextStyles.headlineXLarge.copyWith(
                  color: Color(0xff424242),
                ),
                children: [
                  TextSpan(
                    text: doctorName ?? 'Doctor',
                    style: EcliniqTextStyles.headlineXLarge.copyWith(
                      color: Color(0xfff0d47a1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2FFF3),
                border: Border.all(color: const Color(0xFF2E7D32), width: 0.5),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Token Number',
                    style: EcliniqTextStyles.headlineXLMedium.copyWith(
                      color: Color(0xff424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tokenNumber ?? '--',
                    style: EcliniqTextStyles.headlineLarge.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3EAF3F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  AppointmentDetailItem(
                    iconAssetPath: EcliniqIcons.user.assetPath,
                    title: patientName,
                    subtitle: patientSubtitle,
                    badge: patientBadge,
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
                    title: selectedSlot,
                    subtitle: selectedDate,
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
                    subtitle: hospitalAddress ?? 'Address not available',
                    showEdit: false,
                  ),
                ],
              ),
            ),
            // Payment receipt section
            if (totalAmount != null && totalAmount! > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_outlined, color: Color(0xFF1976D2), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Receipt',
                          style: EcliniqTextStyles.headlineMedium.copyWith(
                            color: Color(0xff424242),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow('Total Amount', totalAmount!),
                    if (walletAmount != null && walletAmount! > 0) ...[
                      const SizedBox(height: 8),
                      _buildPaymentRow('Paid from Wallet', walletAmount!, isSubItem: true),
                    ],
                    if (gatewayAmount != null && gatewayAmount! > 0) ...[
                      const SizedBox(height: 8),
                      _buildPaymentRow('Paid via PhonePe', gatewayAmount!, isSubItem: true),
                    ],
                    if (paymentMethod != null) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Method',
                            style: EcliniqTextStyles.buttonSmall.copyWith(
                              color: Color(0xff626060),
                            ),
                          ),
                          Text(
                            _getPaymentMethodLabel(paymentMethod!),
                            style: EcliniqTextStyles.buttonSmall.copyWith(
                              color: Color(0xff424242),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (merchantTransactionId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Transaction ID: $merchantTransactionId',
                        style: EcliniqTextStyles.buttonLarge.copyWith(
                          color: Color(0xff8E8E8E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  // Navigate to My Visits tab to show appointment details
                  // This will depend on your navigation structure
                  // You might need to use named routes or a navigation service
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF96BFFF)),
                  backgroundColor: Color(0xffF2F7FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Details',
                      style: EcliniqTextStyles.headlineMedium.copyWith(
                        color: Color(0xFF2372EC),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.rotate(
                      angle: 3.14159, // 180 degrees rotation for forward arrow
                      child: SvgPicture.asset(
                        EcliniqIcons.backArrow.assetPath,
                        width: 24,
                        height: 24,
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
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isSubItem = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSubItem ? '  • $label' : label,
          style: EcliniqTextStyles.headlineXMedium.copyWith(
            color: Color(0xff626060),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: EcliniqTextStyles.headlineXMedium.copyWith(
            color: Color(0xff424242),
            fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'WALLET':
        return 'Wallet Only';
      case 'GATEWAY':
        return 'PhonePe Gateway';
      case 'HYBRID':
        return 'Wallet + PhonePe';
      default:
        return method;
    }
  }
}
