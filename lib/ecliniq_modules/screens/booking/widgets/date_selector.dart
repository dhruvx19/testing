import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DateSelector extends StatelessWidget {
  final String selectedDate;
  final DateTime? selectedDateValue;
  final Function(DateTime) onDateChanged;
  final Map<DateTime, int>? tokenCounts; // Map of date to token count
  final bool isLoading;

  const DateSelector({
    super.key,
    required this.selectedDate,
    this.selectedDateValue,
    required this.onDateChanged,
    this.tokenCounts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = <DateTime>[];

    // Generate dates for next 7 days
    for (int i = 0; i < 7; i++) {
      dates.add(now.add(Duration(days: i)));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((date) {
          final isSelected =
              selectedDateValue != null &&
              date.year == selectedDateValue!.year &&
              date.month == selectedDateValue!.month &&
              date.day == selectedDateValue!.day;

          final label = _formatDateLabel(date);

          // Find matching token count for this date
          int? tokenCount;
          if (tokenCounts != null && !isLoading) {
            final dateOnly = DateTime(date.year, date.month, date.day);
            for (final key in tokenCounts!.keys) {
              final keyDateOnly = DateTime(key.year, key.month, key.day);
              if (keyDateOnly == dateOnly) {
                tokenCount = tokenCounts![key];
                break;
              }
            }
          }

          return Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              right: 10.0,
            ),
            child: GestureDetector(
              onTap: isLoading ? null : () => onDateChanged(date),
              child: isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: EcliniqTextStyles.getResponsiveWidth(context, 100.0),
                        height: EcliniqTextStyles.getResponsiveHeight(context, 70.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2372EC)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2372EC)
                              : Color(0xffB8B8B8),
                          width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                        ),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: EcliniqTextStyles.responsiveTitleXBLarge(context).copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : Color(0xff424242),
                            ),
                          ),
                          Text(
                            tokenCount != null
                                ? '$tokenCount Tokens Available'
                                : 'Tap to view slots',
                            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF3EAF3F),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final monthName = _getMonthName(date.month);

    if (dateOnly == today) {
      return 'Today, ${date.day} $monthName';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow, ${date.day} $monthName';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]}, ${date.day} $monthName';
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
