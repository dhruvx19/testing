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

  // Effective maximum is always today unless caller passes an earlier maximumDate.
  DateTime get _effectiveMaxDate {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    if (widget.maximumDate == null) return todayDate;
    final callerMax = DateTime(
      widget.maximumDate!.year,
      widget.maximumDate!.month,
      widget.maximumDate!.day,
    );
    return callerMax.isBefore(todayDate) ? callerMax : todayDate;
  }

  bool _isDateInRange(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    if (widget.minimumDate != null) {
      final min = DateTime(
        widget.minimumDate!.year,
        widget.minimumDate!.month,
        widget.minimumDate!.day,
      );
      if (d.isBefore(min)) return false;
    }
    if (d.isAfter(_effectiveMaxDate)) return false;
    return true;
  }

  void _updateSelectedDate() {
    final daysInMonth = _getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > daysInMonth) {
      selectedDay = daysInMonth;
    }
    selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    // Clamp to effective max if the resulting date is in the future
    if (selectedDate.isAfter(_effectiveMaxDate)) {
      selectedDate = _effectiveMaxDate;
      selectedDay = selectedDate.day;
      selectedMonth = selectedDate.month;
      selectedYear = selectedDate.year;
    }
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
    double dragDistance = 0;
    final double dragThreshold = 30.0;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          dragDistance = 0;
        },
        onVerticalDragUpdate: (details) {
          dragDistance += details.delta.dy;

          if (dragDistance.abs() >= dragThreshold) {
            if (dragDistance > 0) {
              // Dragging down = go to previous item (clamp at 0, no wrap)
              final newIndex = selectedIndex - 1;
              if (newIndex >= 0 && (isItemEnabled?.call(newIndex) ?? true)) {
                onTap(newIndex);
              }
              dragDistance = 0;
            } else {
              // Dragging up = go to next item (clamp at end, no wrap)
              final newIndex = selectedIndex + 1;
              if (newIndex < itemCount && (isItemEnabled?.call(newIndex) ?? true)) {
                onTap(newIndex);
              }
              dragDistance = 0;
            }
          }
        },
        onVerticalDragEnd: (details) {
          dragDistance = 0;
        },
        child: Column(
          children: List.generate(7, (index) {
            final offset = index - 3;

            int actualIndex = (selectedIndex + offset) % itemCount;
            if (actualIndex < 0) {
              actualIndex += itemCount;
            }

            final isEnabled = isItemEnabled?.call(actualIndex) ?? true;

            double fontSize;
            Color textColor;
            switch (offset.abs()) {
              case 0: // Selected
                fontSize = 20;
                textColor = const Color(0xff424242);
                break;
              case 1:
                fontSize = 16;
                textColor = const Color(0xffB8B8B8);
                break;
              case 2:
                fontSize = 14;
                textColor = const Color(0xffD6D6D6);
                break;
              case 3:
                fontSize = 12;
                textColor = const Color(0xffD6D6D6);
                break;
              default:
                fontSize = 12;
                textColor = const Color(0xffD6D6D6);
            }

            return GestureDetector(
              onTap: isEnabled ? () => onTap(actualIndex) : null,
              child: Container(
                height: EcliniqTextStyles.getResponsiveSize(context, 28.0),
                alignment: Alignment.center,
                child: Text(
                  itemBuilder(actualIndex),
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: EcliniqTextStyles.getResponsiveSize(context, fontSize),
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minYear = widget.minimumDate?.year ?? 1900;
    final maxYear = _effectiveMaxDate.year;

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
                  color: const Color(0xff424242),
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
                    // Selection highlight bar — positioned at center row (index 3 of 7)
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
                            // Month is selectable if at least day 1 of it is within range
                            final firstDay = DateTime(selectedYear, index + 1, 1);
                            return _isDateInRange(firstDay);
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
                            return year >= minYear && year <= _effectiveMaxDate.year;
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