import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../model/transaction_model.dart';
import '../provider/transaction_provider.dart';

class TransactionDetailsWidget extends StatelessWidget {
  const TransactionDetailsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: const Expanded(child: TransactionList()),
    );
  }
}

class TransactionList extends StatelessWidget {
  const TransactionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1),
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
                    style: EcliniqTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  SvgPicture.asset(
                    monthlyTransaction.isExpanded
                        ? EcliniqIcons.angleDown.assetPath
                        : EcliniqIcons.angleRight.assetPath,
                    color: const Color(0xFF718096),
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
    final hour = date.hour.toString().padLeft(2, '0');
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset(EcliniqIcons.upcharCoin.assetPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EcliniqText(
                  isCredit ? 'Coin Credited' : 'Coin Used',
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF2D3748),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.date),
                  style: EcliniqTextStyles.labelMedium.copyWith(
                    color: Color(0xFF718096),
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
                  ? const Color(0xFFE6FCF5)
                  : const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: EcliniqText(
              '${isCredit ? '+' : '-'}${transaction.amount}',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: isCredit
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
