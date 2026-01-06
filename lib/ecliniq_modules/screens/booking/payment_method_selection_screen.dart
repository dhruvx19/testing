// Create a new file: payment_method_bottom_sheet.dart

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final double walletBalance;
  final bool useWallet;
  final Function(bool) onWalletToggle;
  final String? currentSelectedMethod;
  final String? currentSelectedPackage;
  final double serviceFee;
  final bool isBooking;
  final VoidCallback? onConfirm;
  final String? selectedPaymentMethod;

  const PaymentMethodBottomSheet({
    super.key,
    required this.walletBalance,
    required this.useWallet,
    required this.onWalletToggle,
    required this.serviceFee,
    this.currentSelectedMethod,
    this.currentSelectedPackage,
    this.isBooking = false,
    this.onConfirm,
    this.selectedPaymentMethod,
  });

  @override
  State<PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  String? _selectedMethod;
  String? _selectedMethodPackage;
  late bool _useWallet;
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'BHIM',
      'packageName': 'in.org.npci.upiapp',
      'icon': EcliniqIcons.bhimPay,
    },
    {
      'name': 'Gpay',
      'packageName': 'com.google.android.apps.nbu.paisa.user',
      'icon': EcliniqIcons.googlePay,
    },
    {
      'name': 'PhonePe',
      'packageName': 'com.phonepe.app',
      'icon': EcliniqIcons.phonePe,
    },
    {
      'name': 'PhonePe',
      'packageName': 'com.phonepe.simulator',
      'icon': EcliniqIcons.phonePe,
    },
  ];

  final List<Map<String, dynamic>> _cardMethods = [
    {
      'name': 'HDFC Bank',
      'cardNumber': '**0964',
      'cardType': 'VISA',
      'packageName': 'card_hdfc_0964',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentSelectedMethod;
    _selectedMethodPackage = widget.currentSelectedPackage;
    _useWallet = widget.useWallet;
  }

  void _handleConfirm() {
    if (_selectedMethodPackage != null && _selectedMethod != null) {
      // First return the selection
      Navigator.pop(context, {
        'name': _selectedMethod!,
        'packageName': _selectedMethodPackage!,
        'useWallet': _useWallet,
      });
      // Then call the confirm callback if provided
      if (widget.onConfirm != null) {
        widget.onConfirm!();
      }
    }
  }

  void _selectPaymentMethod(String packageName, String name) {
    setState(() {
      _selectedMethodPackage = packageName;
      _selectedMethod = name;
    });
  }

  void _confirmSelection() {
    if (_selectedMethodPackage != null && _selectedMethod != null) {
      Navigator.pop(context, {
        'name': _selectedMethod!,
        'packageName': _selectedMethodPackage!,
        'useWallet': _useWallet,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Payment methods list (scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 28, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.upcharCoinSmall.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Upchar-Q Coin Balance : ₹${widget.walletBalance.toStringAsFixed(2)}',
                          style: EcliniqTextStyles.headlineXMedium.copyWith(
                            fontSize: 14,
                            color: Color(0xff424242),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _useWallet = !_useWallet;
                          });
                          widget.onWalletToggle(_useWallet);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _useWallet
                                ? const Color(0xFF2372EC)
                                : Colors.transparent,
                            border: Border.all(
                              color: _useWallet
                                  ? const Color(0xFF2372EC)
                                  : const Color(0xFF8E8E8E),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _useWallet
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 0.5, color: const Color(0xffB8B8B8)),
                  const SizedBox(height: 8),
                  // Recommended Method section
                  Text(
                    'Recommended Method',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      color: const Color(0xff424242),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._paymentMethods.map(
                    (method) => _buildPaymentMethodCard(
                      method['packageName'] as String,
                      method['name'] as String,
                      method['icon'] as EcliniqIcons,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Cards section
                  Text(
                    'Cards',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      color: const Color(0xff424242),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._cardMethods.map(
                    (card) => _buildCardMethodCard(
                      card['packageName'] as String,
                      card['name'] as String,
                      card['cardNumber'] as String,
                      card['cardType'] as String,
                    ),
                  ),

                  // Add card button
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: Color(0xFF2372EC),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Add credit or debit cards',
                        style: EcliniqTextStyles.headlineXMedium.copyWith(
                          color: const Color(0xFF2372EC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.add,
                        color: Color(0xFF2372EC),
                        size: 24,
                      ),
                      onTap: () {
                        // Handle add card
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pay by any UPI App section
                  // Text(
                  //   'Pay by any UPI App',
                  //   style: EcliniqTextStyles.headlineMedium.copyWith(
                  //     color: const Color(0xff424242),
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  // const SizedBox(height: 12),

                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 12,
                  //     vertical: 14,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     border: Border.all(
                  //       color: const Color(0xFFE0E0E0),
                  //       width: 1,
                  //     ),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       const Icon(
                  //         Icons.phone_android,
                  //         color: Color(0xff626060),
                  //         size: 24,
                  //       ),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: TextField(
                  //           decoration: InputDecoration(
                  //             hintText: 'Enter UPI ID',
                  //             hintStyle: EcliniqTextStyles.headlineXMedium
                  //                 .copyWith(color: const Color(0xFFD6D6D6)),
                  //             border: InputBorder.none,
                  //             contentPadding: EdgeInsets.zero,
                  //             isDense: true,
                  //           ),
                  //           style: EcliniqTextStyles.headlineXMedium.copyWith(
                  //             color: const Color(0xff424242),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed bottom section - matches review screen layout
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 28,
            ),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wallet balance checkbox
                Container(height: 0.5, color: const Color(0xffB8B8B8)),
                const SizedBox(height: 8),
                // Payment method selector and button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon and "Pay using" in same row
                            Row(
                              children: [
                                if (_selectedMethodPackage != null)
                                  Image.asset(
                                    _getIconForPackage(_selectedMethodPackage!),
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.payment,
                                        size: 20,
                                        color: Color(0xFF2372EC),
                                      );
                                    },
                                  )
                                else
                                  Image.asset(
                                    EcliniqIcons.googlePay.assetPath,
                                    width: 20,
                                    height: 20,
                                  ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Pay using',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff424242),
                                  ),
                                ),
                     
                                SvgPicture.asset(
                                  EcliniqIcons.arrowUp.assetPath,
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xff626060),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Payment method name below
                            Text(
                              _selectedMethod ??
                                  widget.selectedPaymentMethod ??
                                  'Select payment method',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w300,
                                color:
                                    _selectedMethod != null ||
                                        widget.selectedPaymentMethod != null
                                    ? const Color(0xff424242)
                                    : const Color(0xff8E8E8E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right side - Pay & Confirm button
                    GestureDetector(
                      onTap:
                          (widget.isBooking || _selectedMethodPackage == null)
                          ? null
                          : _handleConfirm,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          boxShadow:
                              (widget.isBooking ||
                                  _selectedMethodPackage == null)
                              ? null
                              : [
                                  const BoxShadow(
                                    color: Color(0x4D2372EC),
                                    offset: Offset(2, 2),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                          color:
                              (widget.isBooking ||
                                  _selectedMethodPackage == null)
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF2372EC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.isBooking
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 6,
                                  bottom: 6,
                                  right: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Amount and Total
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            '₹${widget.serviceFee.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  (widget.isBooking ||
                                                      _selectedMethodPackage ==
                                                          null)
                                                  ? const Color(0xff8E8E8E)
                                                  : Colors.white,
                                              height: 1.0,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Total',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 34),
                                    // Pay & Confirm text
                                    Expanded(
                                      child: Text(
                                        'Pay & Confirm',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              (widget.isBooking ||
                                                  _selectedMethodPackage ==
                                                      null)
                                              ? const Color(0xff8E8E8E)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Transform.rotate(
                                      angle: 1.5708,
                                      child: SvgPicture.asset(
                                        EcliniqIcons.arrowUp.assetPath,
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(
                                          (widget.isBooking ||
                                                  _selectedMethodPackage ==
                                                      null)
                                              ? const Color(0xff8E8E8E)
                                              : Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String packageName,
    String name,
    EcliniqIcons icon,
  ) {
    final isSelected = _selectedMethodPackage == packageName;

    return GestureDetector(
      onTap: () => _selectPaymentMethod(packageName, name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD6D6D6), width: 0.5),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Image.asset(
              icon.assetPath,
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 20,
                    color: Color(0xff626060),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: const Color(0xff424242),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF8E8E8E),
                  width: 1,
                ),
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardMethodCard(
    String packageName,
    String bankName,
    String cardNumber,
    String cardType,
  ) {
    final isSelected = _selectedMethodPackage == packageName;

    return GestureDetector(
      onTap: () => _selectPaymentMethod(packageName, '$bankName $cardNumber'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2372EC)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color(0xFFE3F2FD).withOpacity(0.3)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1434CB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cardType,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName,
                    style: EcliniqTextStyles.headlineXMedium.copyWith(
                      color: const Color(0xff424242),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    cardNumber,
                    style: EcliniqTextStyles.buttonSmall.copyWith(
                      color: const Color(0xff626060),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF8E8E8E),
                  width: 1,
                ),
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getIconForPackage(String packageName) {
    final method = _paymentMethods.firstWhere(
      (m) => m['packageName'] == packageName,
      orElse: () => {'icon': EcliniqIcons.googlePay},
    );
    return (method['icon'] as EcliniqIcons).assetPath;
  }
}
