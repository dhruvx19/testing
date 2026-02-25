import 'dart:convert';
import 'dart:io';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

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
  bool _isLoadingApps = true;
  List<Map<String, dynamic>> _paymentMethods = [];

  // All known UPI apps — only shown if installed on the device
  static final List<Map<String, dynamic>> _knownUpiApps = [
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
    if (widget.currentSelectedMethod != null &&
        widget.currentSelectedPackage != null) {
      _selectedMethod = widget.currentSelectedMethod;
      _selectedMethodPackage = widget.currentSelectedPackage;
    } else {
      _selectedMethod = 'Gpay';
      _selectedMethodPackage = 'com.google.android.apps.nbu.paisa.user';
    }
    _useWallet = widget.useWallet;
    _loadInstalledUpiApps();
  }

  Future<void> _loadInstalledUpiApps() async {
    try {
      if (Platform.isAndroid) {
        final appsJson = await PhonePePaymentSdk.getUpiAppsForAndroid();
        if (appsJson != null) {
          final List<dynamic> apps = jsonDecode(appsJson);
          final installedPackages =
              apps.map((a) => a['packageName'] as String).toSet();

          final filtered = _knownUpiApps
              .where((app) =>
                  installedPackages.contains(app['packageName'] as String))
              .toList();

          if (mounted) {
            setState(() {
              _paymentMethods =
                  filtered.isNotEmpty ? filtered : List.from(_knownUpiApps.where((a) => a['packageName'] != 'com.phonepe.simulator'));
              _isLoadingApps = false;
              // If the previously selected app is not installed, reset to first available
              if (_selectedMethodPackage != null &&
                  !_paymentMethods
                      .any((m) => m['packageName'] == _selectedMethodPackage)) {
                _selectedMethod = _paymentMethods.isNotEmpty
                    ? _paymentMethods.first['name'] as String
                    : null;
                _selectedMethodPackage = _paymentMethods.isNotEmpty
                    ? _paymentMethods.first['packageName'] as String
                    : null;
              }
            });
          }
          return;
        }
      }
    } catch (_) {
      // SDK not initialized or unsupported platform — fall back to static list
    }

    // Fallback: show all known apps except the simulator duplicate
    if (mounted) {
      setState(() {
        _paymentMethods = List.from(
          _knownUpiApps.where((a) => a['packageName'] != 'com.phonepe.simulator'),
        );
        _isLoadingApps = false;
      });
    }
  }

  void _handleConfirm() {
    if (_selectedMethodPackage != null && _selectedMethod != null) {
      
      Navigator.pop(context, {
        'name': _selectedMethod!,
        'packageName': _selectedMethodPackage!,
        'useWallet': _useWallet,
      });
      
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
    
    Navigator.pop(context, {
      'name': name,
      'packageName': packageName,
      'useWallet': _useWallet,
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
                          style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                        
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
                                  size: 20,
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
                  
                  Text(
                    'Recommended Method',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                      color: const Color(0xff424242),
                    
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingApps)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ..._paymentMethods.map(
                      (method) => _buildPaymentMethodCard(
                        method['packageName'] as String,
                        method['name'] as String,
                        method['icon'] as EcliniqIcons,
                      ),
                    ),

                  const SizedBox(height: 22),

                  
                  Text(
                    'Cards',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                      color: const Color(0xff424242),
                 
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

                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  const SizedBox(height: 24),

                  
                  
                  
                  
                  
                  
                  
                  
                  

                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          
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
                
                Container(height: 0.5, color: const Color(0xffB8B8B8)),
                const SizedBox(height: 8),
                
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
                                const SizedBox(width: 4),
                                Flexible(
                                  child:  Text(
                                    'Pay using',
                                    style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                                     
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff424242),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                            
                            Text(
                              _selectedMethod ??
                                  widget.selectedPaymentMethod ??
                                  'Gpay',
                              style: EcliniqTextStyles.responsiveButtonXLargeProminent(context).copyWith(
                         
                                fontWeight: FontWeight.w300,
                                color: const Color(0xff424242),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    
                    GestureDetector(
                      onTap: widget.isBooking ? null : _handleConfirm,
                      child: Container(
                        height: EcliniqTextStyles.getResponsiveButtonHeight(
                          context,
                          baseHeight: 52.0,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: widget.isBooking
                              ? null
                              : [
                                  const BoxShadow(
                                    color: Color(0x4D2372EC),
                                    offset: Offset(2, 2),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ],
                          color: widget.isBooking
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF2372EC),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                          ),
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
                                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                                  context,
                                  left: 12,
                                  top: 6,
                                  bottom: 6,
                                  right: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    
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
                                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                            
                                              fontWeight: FontWeight.w500,
                                              color: widget.isBooking
                                                  ? const Color(0xff8E8E8E)
                                                  : Colors.white,
                                              height: 1.0,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                            height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
                                          ),
                                           Text(
                                            'Total',
                                            style: EcliniqTextStyles.responsiveLabelSmall(context).copyWith(
                                            
                                              fontWeight: FontWeight.w300,
                                              color: Colors.white,
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: EcliniqTextStyles.getResponsiveSpacing(context, 34),
                                    ),
                                    
                                    Expanded(
                                      child: Text(
                                        'Pay & Confirm',
                                        style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                             
                                          fontWeight: FontWeight.w500,
                                          color: widget.isBooking
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
                                          widget.isBooking
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
                style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
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
          border: Border.all(color: const Color(0xFFD6D6D6), width: 0.5),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFffffff),
        ),
        child: Row(
          children: [
            Image.asset(EcliniqIcons.visa.assetPath, width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    bankName,
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                      color: const Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    ' | ',
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                      color: const Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  Text(
                    cardNumber,
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                      color: const Color(0xff424242),
                      fontWeight: FontWeight.w400,
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
    final method = _knownUpiApps.firstWhere(
      (m) => m['packageName'] == packageName,
      orElse: () => {'icon': EcliniqIcons.googlePay},
    );
    return (method['icon'] as EcliniqIcons).assetPath;
  }
}
