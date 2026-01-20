import 'package:ecliniq/ecliniq_api/models/wallet.dart';
import 'package:ecliniq/ecliniq_api/wallet_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'Widgets/transaction_widgets.dart';

class UpcharCoin extends StatefulWidget {
  const UpcharCoin({super.key});
  @override
  State<UpcharCoin> createState() => _UpcharCoinState();
}

class _UpcharCoinState extends State<UpcharCoin> {
  final WalletService _walletService = WalletService();
  WalletBalanceData? _walletBalance;
  WalletTransactionsData? _transactionsData;
  bool _isLoadingBalance = true;
  bool _isLoadingTransactions = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      setState(() {
        _isLoadingBalance = false;
        _isLoadingTransactions = false;
      });
      return;
    }

    // Fetch balance first, then transactions (so we can use the year from transactions response)
    await _fetchBalance(authToken);
    // Fetch transactions without specifying year - let API return the year with data
    await _fetchTransactions(authToken);
  }

  Future<void> _fetchBalance(String authToken) async {
    try {
      final response = await _walletService.getBalance(authToken: authToken);
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _walletBalance = response.data;
          }
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _fetchTransactions(String authToken, {int? year}) async {
    final yearToFetch = year ?? _selectedYear;
    try {
      final response = await _walletService.getTransactions(
        authToken: authToken,
        year: yearToFetch,
      );
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _transactionsData = response.data;
            // Always use the year from API response (API may return data for a different year)
            _selectedYear = response.data!.year;
          }
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 58.0),
        titleSpacing: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Upchar-Q Coins',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 0.2),
          ),
          child: Container(
            color: Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
        ),
        actions: [
          Row(
            children: [
              SvgPicture.asset(
                EcliniqIcons.questionCircleFilled.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
              ),
              Text(
                ' Help',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
                      color: EcliniqColors.light.textPrimary,

                      fontWeight: FontWeight.w400,
                    ),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 20.0),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
          context,
          top: 24.0,
          left: 16.0,
          right: 16.0,
          bottom: 24.0,
        ),
        child: Column(
          children: [
            SizedBox(
              child: _isLoadingBalance
                  ? _buildBalanceShimmer()
                  : Stack(
                      children: [
                        Positioned(
                          child: Container(
                            width: double.infinity,
                            height: EcliniqTextStyles.getResponsiveHeight(
                              context,
                              160.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(
                                  context,
                                  8.0,
                                ),
                              ),
                              color: Color(0xFFBE8B00),
                              border: Border.all(
                                color: Color(0xFFB8B8B8),
                                width: EcliniqTextStyles.getResponsiveSize(
                                  context,
                                  0.6,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                    context,
                                    horizontal: 12.0,
                                    vertical: 6,
                                  ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    _walletBalance?.balance.toStringAsFixed(
                                          0,
                                        ) ??
                                        '0',
                                    style:
                                        EcliniqTextStyles.responsiveBodyLarge(
                                          context,
                                        ).copyWith(
                                          fontSize:
                                              EcliniqTextStyles.getResponsiveFontSize(
                                                context,
                                                48.0,
                                              ),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                  ),
                                  // SizedBox(
                                  //   height:
                                  //       EcliniqTextStyles.getResponsiveSpacing(
                                  //         context,
                                  //         2.0,
                                  //       ),
                                  // ),
                                  Text(
                                    'Total Coins Balance Available',
                                    style:
                                        EcliniqTextStyles.responsiveTitleXLarge(
                                          context,
                                        ).copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: EcliniqTextStyles.getResponsiveSize(
                            context,
                            95.0,
                          ),
                          bottom: 0,
                          child: Container(
                            width: double.infinity,
                            height: EcliniqTextStyles.getResponsiveHeight(
                              context,
                              65.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(
                                  context,
                                  8.0,
                                ),
                              ),
                              color: Color(0xBAFFFFFF),
                            ),
                            child: Padding(
                              padding:
                                  EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                                    context,
                                    top: 12.0,
                                    right: 12.0,
                                  ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_walletBalance?.totalDeposited.toStringAsFixed(0) ?? '0'} Coins',
                                    style:
                                        EcliniqTextStyles.responsiveTitleXLarge(
                                          context,
                                        ).copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                  ),
                                  Text(
                                    'Total Deposited Till Date',
                                    style:
                                        EcliniqTextStyles.responsiveTitleXLarge(
                                          context,
                                        ).copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            -14.0,
                          ),
                          left: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            8.0,
                          ),
                          child: Image.asset(
                            EcliniqIcons.upcharCoin.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              130.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              200.0,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                top: 20.0,
                bottom: 10.0,
              ),
              child: Row(
                children: [
                  Text(
                    'Transaction History',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff626060),
                        ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () => _showYearSelector(context),
                    child: Container(
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        74.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveHeight(
                        context,
                        30.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            6.0,
                          ),
                        ),
                        color: Color(0xffF9F9F9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_selectedYear',
                            style:
                                EcliniqTextStyles.responsiveTitleXLarge(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff424242),
                                ),
                          ),
                          SvgPicture.asset(
                            EcliniqIcons.angleDown.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              18.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              18.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TransactionDetailsWidget(
              key: ValueKey('transactions_$_selectedYear'),
              transactionsData: _transactionsData,
              isLoading: _isLoadingTransactions,
              selectedYear: _selectedYear,
              onYearChanged: (year) {
                setState(() {
                  _selectedYear = year;
                  _isLoadingTransactions = true;
                });
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final authToken = authProvider.authToken;
                if (authToken != null) {
                  _fetchTransactions(authToken, year: year);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showYearSelector(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Year',
              style: EcliniqTextStyles.responsiveHeadlineLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: Color(0xff424242)),
            ),
            SizedBox(height: 16),
            ...years.map(
              (year) => ListTile(
                title: Text(
                  year.toString(),
                  style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                      .copyWith(
                        color: year == _selectedYear
                            ? Color(0xFF2372EC)
                            : Color(0xff424242),
                        fontWeight: year == _selectedYear
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (year != _selectedYear) {
                    setState(() {
                      _selectedYear = year;
                      _isLoadingTransactions = true;
                    });
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final authToken = authProvider.authToken;
                    if (authToken != null) {
                      _fetchTransactions(authToken, year: year);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceShimmer() {
    return Container(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveHeight(context, 160.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
        ),
        color: Colors.grey[100],
        border: Border.all(
          color: Color(0xFFB8B8B8),
          width: EcliniqTextStyles.getResponsiveSize(context, 0.6),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 120.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                ShimmerLoading(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 200.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: EcliniqTextStyles.getResponsiveSize(context, 95.0),
            bottom: 0,
            child: Container(
              width: double.infinity,
              height: EcliniqTextStyles.getResponsiveHeight(context, 65.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                ),
                color: Colors.white.withOpacity(0.7),
              ),
              child: Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  top: 12.0,
                  right: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        100.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        20.0,
                      ),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          4.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        4.0,
                      ),
                    ),
                    ShimmerLoading(
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        150.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        16.0,
                      ),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          4.0,
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
    );
  }
}
