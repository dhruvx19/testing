import 'package:ecliniq/ecliniq_api/models/wallet.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../model/transaction_model.dart';
import '../provider/transaction_provider.dart';

class TransactionDetailsWidget extends StatefulWidget {
  final WalletTransactionsData? transactionsData;
  final bool isLoading;
  final int selectedYear;
  final Function(int)? onYearChanged;

  const TransactionDetailsWidget({
    Key? key,
    this.transactionsData,
    this.isLoading = false,
    this.selectedYear = 2025,
    this.onYearChanged,
  }) : super(key: key);

  @override
  State<TransactionDetailsWidget> createState() => _TransactionDetailsWidgetState();
}

class _TransactionDetailsWidgetState extends State<TransactionDetailsWidget> {
  TransactionProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = TransactionProvider(
      transactionsData: widget.transactionsData,
      isLoading: widget.isLoading,
      selectedYear: widget.selectedYear,
      onYearChanged: widget.onYearChanged,
    );
  }

  @override
  void didUpdateWidget(TransactionDetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (_provider != null) {
      _provider!.updateData(
        newTransactionsData: widget.transactionsData,
        newIsLoading: widget.isLoading,
        newSelectedYear: widget.selectedYear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider!,
      child: Expanded(child: TransactionList()),
    );
  }
}

class TransactionList extends StatelessWidget {
  const TransactionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildShimmerLoading();
        }

        if (provider.monthlyData.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No transactions found',
                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                  color: Color(0xff8E8E8E),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: provider.monthlyData.length,
          itemBuilder: (context, index) {
            return MonthlyTransactionCard(
              monthlyTransaction: provider.monthlyData[index],
              index: index,
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFD6D6D6), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: 120,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (index == 0) ...[
                  const SizedBox(height: 12),
                  ...List.generate(2, (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            ShimmerLoading(
                              width: 40,
                              height: 40,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerLoading(
                                    width: 150,
                                    height: 16,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 4),
                                  ShimmerLoading(
                                    width: 100,
                                    height: 14,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                            ShimmerLoading(
                              width: 60,
                              height: 30,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class MonthlyTransactionCard extends StatelessWidget {
  final MonthlyTransactions monthlyTransaction;
  final int index;

  const MonthlyTransactionCard({
    Key? key,
    required this.monthlyTransaction,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD6D6D6), width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              context.read<TransactionProvider>().toggleExpansion(index);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthlyTransaction.month,
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                      color: const Color(0xFF424242),
                      fontWeight: FontWeight.w500,
                     
                    ),
                  ),
                  SvgPicture.asset(
                    monthlyTransaction.isExpanded
                        ? EcliniqIcons.angleDown.assetPath
                        : EcliniqIcons.angleRight.assetPath,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF424242), BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: monthlyTransaction.transactions
                  .map(
                    (transaction) => TransactionItem(transaction: transaction),
                  )
                  .toList(),
            ),
            crossFadeState: monthlyTransaction.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final displayHour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);

    return '$day $month | ${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'credit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(EcliniqIcons.upcharCoin.assetPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EcliniqText(
                  isCredit ? 'Coin Credited' : 'Coin Used',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    color: const Color(0xFF424242),
                    fontWeight: FontWeight.w400,
         
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: EcliniqTextStyles.responsiveLabelMedium(context).copyWith(
                    color: Color(0xFF8E8E8E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFFF2FFF3)
                  : const Color(0xFFFFF8F8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: EcliniqText(
              '${isCredit ? '+' : '-'}${transaction.amount}',
              style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                color: isCredit
                    ? const Color(0xFF3EAF3F)
                    : const Color(0xFFF04248),
                fontWeight: FontWeight.w500,
               
              ),
            ),
          ),
        ],
      ),
    );
  }
}
