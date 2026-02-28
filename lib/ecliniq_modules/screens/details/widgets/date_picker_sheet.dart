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

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

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
    final effectiveMaxDate = widget.maximumDate ?? DateTime.now();
    final effectiveMinDate = widget.minimumDate ?? DateTime(1900);

    selectedDate = widget.initialDate;
    if (selectedDate.isAfter(effectiveMaxDate)) {
      selectedDate = effectiveMaxDate;
    } else if (selectedDate.isBefore(effectiveMinDate)) {
      selectedDate = effectiveMinDate;
    }

    selectedDay = selectedDate.day;
    selectedMonth = selectedDate.month;
    selectedYear = selectedDate.year;

    final minYear = effectiveMinDate.year;
    _dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    _monthController =
        FixedExtentScrollController(initialItem: selectedMonth - 1);
    _yearController =
        FixedExtentScrollController(initialItem: selectedYear - minYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  bool _isDateInRange(DateTime date) {
    final minDate = widget.minimumDate ?? DateTime(1900);
    final maxDate = widget.maximumDate ?? DateTime.now();

    final dateOnly = DateTime(date.year, date.month, date.day);
    final minDateOnly = DateTime(minDate.year, minDate.month, minDate.day);
    final maxDateOnly = DateTime(maxDate.year, maxDate.month, maxDate.day);

    if (dateOnly.isBefore(minDateOnly)) return false;
    if (dateOnly.isAfter(maxDateOnly)) return false;

    return true;
  }

  void _updateSelectedDate() {
    final effectiveMaxDate = widget.maximumDate ?? DateTime.now();
    final effectiveMinDate = widget.minimumDate ?? DateTime(1900);

    // 1. Validate and cap Year
    if (selectedYear > effectiveMaxDate.year) {
      selectedYear = effectiveMaxDate.year;
      if (_yearController.hasClients) {
        _yearController.jumpToItem(selectedYear - effectiveMinDate.year);
      }
    } else if (selectedYear < effectiveMinDate.year) {
      selectedYear = effectiveMinDate.year;
      if (_yearController.hasClients) {
        _yearController.jumpToItem(0);
      }
    }

    // 2. Validate and cap Month
    int maxMonth = 12;
    if (selectedYear == effectiveMaxDate.year) {
      maxMonth = effectiveMaxDate.month;
    }

    if (selectedMonth > maxMonth) {
      selectedMonth = maxMonth;
      if (_monthController.hasClients) {
        _monthController.jumpToItem(selectedMonth - 1);
      }
    }

    // 3. Validate and cap Day
    final daysInMonth = _getDaysInMonth(selectedYear, selectedMonth);
    int maxDay = daysInMonth;
    if (selectedYear == effectiveMaxDate.year &&
        selectedMonth == effectiveMaxDate.month) {
      maxDay = effectiveMaxDate.day;
    }

    if (selectedDay > maxDay) {
      selectedDay = maxDay;
      if (_dayController.hasClients) {
        _dayController.jumpToItem(selectedDay - 1);
      }
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
    required FixedExtentScrollController controller,
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
        height: EcliniqTextStyles.getResponsiveSize(context, 180.0),
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: EcliniqTextStyles.getResponsiveSize(context, 44.0),
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          useMagnifier: true,
          magnification: 1.2,
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
                    fontSize: EcliniqTextStyles.getResponsiveSize(context, 18.0),
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
    final effectiveMaxDate = widget.maximumDate ?? DateTime.now();
    final minYear = widget.minimumDate?.year ?? 1900;
    final maxYear = effectiveMaxDate.year;

    int monthCount = 12;
    if (selectedYear >= maxYear) {
      monthCount = effectiveMaxDate.month;
    }

    int dayCount = _getDaysInMonth(selectedYear, selectedMonth);
    if (selectedYear >= maxYear && selectedMonth >= effectiveMaxDate.month) {
      dayCount = effectiveMaxDate.day;
    }

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
                          controller: _dayController,
                          itemCount: dayCount,
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
                          controller: _monthController,
                          itemCount: monthCount,
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
                          controller: _yearController,
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
