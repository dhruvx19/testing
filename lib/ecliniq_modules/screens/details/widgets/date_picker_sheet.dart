import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/cupertino.dart';
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
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  bool _isButtonPressed = false;

  // Today is used as the effective maximum when no maximumDate is provided
  final DateTime _today = DateTime.now();

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
    selectedDay = widget.initialDate.day;
    selectedMonth = widget.initialDate.month;
    selectedYear = widget.initialDate.year;

    final minYear = widget.minimumDate?.year ?? 1900;

    _dayController = FixedExtentScrollController(initialItem: selectedDay - 1);
    _monthController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: selectedYear - minYear,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  /// Effective maximum date: widget.maximumDate if provided, otherwise today
  DateTime get _effectiveMaxDate => widget.maximumDate ?? _today;

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// How many days are valid for the currently selected year+month,
  /// capped so the user cannot scroll into the future.
  int _getAvailableDaysInMonth(int year, int month) {
    final daysInMonth = _getDaysInMonth(year, month);
    final max = _effectiveMaxDate;
    if (year == max.year && month == max.month) {
      return max.day; // only up to today's day
    }
    return daysInMonth;
  }

  /// How many months are valid for the currently selected year,
  /// capped so the user cannot scroll into the future.
  int _getAvailableMonthsForYear(int year) {
    final max = _effectiveMaxDate;
    if (year == max.year) {
      return max.month; // only up to today's month
    }
    return 12;
  }

  DateTime get _selectedDate =>
      DateTime(selectedYear, selectedMonth, selectedDay);

  bool _isDateInRange(DateTime date) {
    if (widget.minimumDate != null && date.isBefore(widget.minimumDate!))
      return false;
    if (date.isAfter(_effectiveMaxDate)) return false;
    return true;
  }

  /// Clamp day and month whenever the year/month changes so the selection
  /// never points at a date that doesn't exist or is in the future.
  void _clampSelectedDate({bool jumpControllers = true}) {
    // Clamp month
    final availableMonths = _getAvailableMonthsForYear(selectedYear);
    if (selectedMonth > availableMonths) {
      selectedMonth = availableMonths;
      if (jumpControllers) {
        _monthController.jumpToItem(selectedMonth - 1);
      }
    }

    // Clamp day
    final availableDays = _getAvailableDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > availableDays) {
      selectedDay = availableDays;
      if (jumpControllers) {
        _dayController.jumpToItem(selectedDay - 1);
      }
    }
  }

  Future<void> _saveDate() async {
    if (!_isDateInRange(_selectedDate)) return;

    setState(() => _isButtonPressed = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) Navigator.pop(context, _selectedDate);
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required Function(int) onSelected,
    int flex = 3,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final selectedFontSize = screenWidth * 0.050; // ~20px on 390px screen
    final unselectedFontSize = screenWidth * 0.041; // ~16px on 390px screen
    return Expanded(
      flex: flex,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 34,
        diameterRatio: 3.0,
        perspective: 0.001,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          onSelected(index);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) {
            final isSelected =
                controller.hasClients && controller.selectedItem == index;
            return Center(
              child: FittedBox(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    // Selected: 20 | Unselected (adjacent items): 14
                    fontSize: isSelected
                        ? selectedFontSize
                        : unselectedFontSize,
                    fontWeight: FontWeight.w400,
                    color: isSelected
                        ? const Color(0xff424242)
                        : const Color(0xFFB8B8B8),
                  ),
                  child: Text(itemBuilder(index)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _isDateInRange(_selectedDate);
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
                style: EcliniqTextStyles.responsiveHeadlineMedium(
                  context,
                ).copyWith(color: isEnabled ? Colors.white : Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minYear = widget.minimumDate?.year ?? 1900;
    final maxYear = _effectiveMaxDate.year; // capped to today's year
    final yearCount = maxYear - minYear + 1;

    return SafeArea(
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
              style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                  .copyWith(
                    color: const Color(0xff424242),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
            ),

            // Picker area
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // Selection highlight bar
                  Center(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Fade top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Fade bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Pickers row
                  Row(
                    children: [
                      // Day — item count is capped to prevent scrolling into future
                      _buildPicker(
                        controller: _dayController,
                        itemCount: _getAvailableDaysInMonth(
                          selectedYear,
                          selectedMonth,
                        ),
                        itemBuilder: (i) => (i + 1).toString().padLeft(2, '0'),
                        onSelected: (i) => setState(() {
                          selectedDay = i + 1;
                          _clampSelectedDate(jumpControllers: false);
                        }),
                      ),
                      // Month — item count is capped to prevent scrolling into future
                      _buildPicker(
                        controller: _monthController,
                        itemCount: _getAvailableMonthsForYear(selectedYear),
                        itemBuilder: (i) => months[i],
                        onSelected: (i) => setState(() {
                          selectedMonth = i + 1;
                          _clampSelectedDate();
                        }),
                        flex: 2,
                      ),
                      // Year
                      _buildPicker(
                        controller: _yearController,
                        itemCount: yearCount,
                        itemBuilder: (i) => (minYear + i).toString(),
                        onSelected: (i) => setState(() {
                          selectedYear = minYear + i;
                          _clampSelectedDate();
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            ),
            _buildSaveButton(),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 20.0),
            ),
          ],
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
