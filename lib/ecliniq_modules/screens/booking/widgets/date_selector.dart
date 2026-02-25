import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DateSelector extends StatelessWidget {
  final String selectedDate;
  final DateTime? selectedDateValue;
  final Function(DateTime) onDateChanged;
  final Map<DateTime, int>? tokenCounts; 
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
    // Derive dates from API response: only dates present in tokenCounts with tokens > 0
    final List<_DateEntry> entries;

    if (isLoading) {
      // Show shimmer placeholders while loading
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(4, (_) {
            return Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 10.0,
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 130.0),
                  height: EcliniqTextStyles.getResponsiveHeight(context, 54.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    if (tokenCounts != null && tokenCounts!.isNotEmpty) {
      // Only show dates from the API that have available tokens
      final sortedEntries = tokenCounts!.entries
          .where((e) => e.value > 0)
          .map((e) {
            final d = e.key;
            return _DateEntry(DateTime(d.year, d.month, d.day), e.value);
          })
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      entries = sortedEntries;
    } else {
      // Fallback: show today only when no API data
      final now = DateTime.now();
      entries = [_DateEntry(DateTime(now.year, now.month, now.day), null)];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.map((entry) {
          final date = entry.date;
          final tokenCount = entry.tokenCount;

          final isSelected =
              selectedDateValue != null &&
              date.year == selectedDateValue!.year &&
              date.month == selectedDateValue!.month &&
              date.day == selectedDateValue!.day;

          final label = _formatDateLabel(date);

          return Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              right: 10.0,
            ),
            child: GestureDetector(
              onTap: () => onDateChanged(date),
              child: Container(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2372EC) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2372EC)
                        : const Color(0xffB8B8B8),
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
                        color: isSelected ? Colors.white : const Color(0xff424242),
                      ),
                    ),
                    Text(
                      tokenCount != null
                          ? '$tokenCount Tokens Available'
                          : 'Tap to view slots',
                      style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                        color: isSelected ? Colors.white : const Color(0xFF3EAF3F),
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

class _DateEntry {
  final DateTime date;
  final int? tokenCount;

  _DateEntry(this.date, this.tokenCount);
}
