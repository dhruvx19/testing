import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final String? title;
  final DateTime? minimumDate;
  final DateTime? maximumDate;

  const DatePickerBottomSheet({
    super.key,
    required this.initialDate,
    this.title,
    this.minimumDate,
    this.maximumDate,
  });

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime selectedDate;
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  bool _isButtonPressed = false;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedDay = selectedDate.day;
    selectedMonth = selectedDate.month;
    selectedYear = selectedDate.year;
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  bool _isDateInRange(DateTime date) {
    if (widget.minimumDate != null && date.isBefore(widget.minimumDate!)) {
      return false;
    }
    if (widget.maximumDate != null && date.isAfter(widget.maximumDate!)) {
      return false;
    }
    return true;
  }

  void _updateSelectedDate() {
    final daysInMonth = _getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > daysInMonth) {
      selectedDay = daysInMonth;
    }
    selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
  }

  Future<void> _saveDate() async {
    if (!_isDateInRange(selectedDate)) {
      return;
    }

    setState(() {
      _isButtonPressed = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      Navigator.pop(context, selectedDate);
    }
  }

  Widget _buildSaveButton() {
    final isEnabled = _isDateInRange(selectedDate);

    return SizedBox(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      child: GestureDetector(
        onTapDown: isEnabled
            ? (_) => setState(() => _isButtonPressed = true)
            : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isButtonPressed = false);
                _saveDate();
              }
            : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isButtonPressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: !isEnabled
                ? Colors.grey[300]
                : _isButtonPressed
                ? const Color(0xFF0E4395)
                : const Color(0xFF2372EC),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.checkRounded.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                colorFilter: ColorFilter.mode(
                  isEnabled ? Colors.white : Colors.grey[400]!,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
              ),
              Text(
                'Save',
                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                  color: isEnabled ? Colors.white : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinearPicker({
    required int itemCount,
    required int selectedIndex,
    required Function(int) onTap,
    required String Function(int) itemBuilder,
    required bool Function(int)? isItemEnabled,
    int flex = 1,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: SizedBox(
        height: EcliniqTextStyles.getResponsiveSize(context, 160.0),
        child: ListWheelScrollView.useDelegate(
          itemExtent: EcliniqTextStyles.getResponsiveSize(context, 36.0),
          perspective: 0.005,
          diameterRatio: 1.2,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            if (isItemEnabled?.call(index) ?? true) {
              onTap(index);
            }
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              final isSelected = index == selectedIndex;
              final isEnabled = isItemEnabled?.call(index) ?? true;

              return Container(
                alignment: Alignment.center,
                child: Text(
                  itemBuilder(index),
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: EcliniqTextStyles.getResponsiveSize(context, isSelected ? 20.0 : 16.0),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isEnabled
                        ? (isSelected ? const Color(0xff424242) : const Color(0xffB8B8B8))
                        : const Color(0xffD6D6D6),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minYear = widget.minimumDate?.year ?? 1900;
    final maxYear = widget.maximumDate?.year ?? DateTime.now().year;

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 0.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
              ),
              topRight: Radius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EcliniqText(
                widget.title ?? 'Select Date Of Birth',
                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 20.0),
              ),
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  right: 22.0,
                  left: 22.0,
                ),
                child: Stack(
                  children: [
                    
                    Positioned(
                      top: EcliniqTextStyles.getResponsiveSize(context, 84.0),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: EcliniqTextStyles.getResponsiveSize(context, 30.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildLinearPicker(
                          itemCount: _getDaysInMonth(
                            selectedYear,
                            selectedMonth,
                          ),
                          selectedIndex: selectedDay - 1,
                          onTap: (index) {
                            setState(() {
                              selectedDay = index + 1;
                              _updateSelectedDate();
                            });
                          },
                          itemBuilder: (index) =>
                              (index + 1).toString().padLeft(2, '0'),
                          isItemEnabled: (index) {
                            final testDate = DateTime(
                              selectedYear,
                              selectedMonth,
                              index + 1,
                            );
                            return _isDateInRange(testDate);
                          },
                        ),
                        _buildLinearPicker(
                          itemCount: 12,
                          selectedIndex: selectedMonth - 1,
                          onTap: (index) {
                            setState(() {
                              selectedMonth = index + 1;
                              _updateSelectedDate();
                            });
                          },
                          itemBuilder: (index) => months[index],
                          isItemEnabled: (index) {
                            final testDate = DateTime(
                              selectedYear,
                              index + 1,
                              1,
                            );
                            return _isDateInRange(testDate);
                          },
                          flex: 0,
                        ),
                        _buildLinearPicker(
                          itemCount: maxYear - minYear + 1,
                          selectedIndex: selectedYear - minYear,
                          onTap: (index) {
                            setState(() {
                              selectedYear = minYear + index;
                              _updateSelectedDate();
                            });
                          },
                          itemBuilder: (index) => (minYear + index).toString(),
                          isItemEnabled: (index) {
                            final year = minYear + index;
                            return year >= minYear && year <= maxYear;
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 22.0),
              ),
              _buildSaveButton(),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 20.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class EcliniqDatePicker {
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    required DateTime initialDateTime,
    DateTime? minimumDateTime,
    DateTime? maximumDateTime,
    String? title,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        initialDate: initialDateTime,
        minimumDate: minimumDateTime,
        maximumDate: maximumDateTime,
        title: title,
      ),
    );
  }
}
