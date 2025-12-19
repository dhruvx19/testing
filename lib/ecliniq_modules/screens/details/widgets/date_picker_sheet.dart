import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final String? title;

  const DatePickerBottomSheet({
    super.key,
    required this.initialDate,
    this.title,
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

  void _updateSelectedDate() {
    final daysInMonth = _getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > daysInMonth) {
      selectedDay = daysInMonth;
    }
    selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
  }

  Future<void> _saveDate() async {
    setState(() {
      _isButtonPressed = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      Navigator.pop(context, selectedDate);
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isButtonPressed = true),

        onTapUp: (_) {
          setState(() => _isButtonPressed = false);
          _saveDate();
        },

        onTapCancel: () => setState(() => _isButtonPressed = false),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isButtonPressed
                ? const Color(0xFF0E4395) // Pressed color
                : const Color(0xFF2372EC), // Enabled color

            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.checkRounded.assetPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 4),
              Text(
                'Save',
                style: EcliniqTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EcliniqText(
                    widget.title ?? 'Select Date Of Birth',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Stack(
                children: [
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      selectedDay = index + 1;
                                      _updateSelectedDate();
                                    });
                                  },
                                  controller: FixedExtentScrollController(
                                    initialItem: selectedDay - 1,
                                  ),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, index) {
                                      if (index < 0 ||
                                          index >=
                                              _getDaysInMonth(
                                                selectedYear,
                                                selectedMonth,
                                              )) {
                                        return null;
                                      }
                                      final day = index + 1;
                                      final isSelected = day == selectedDay;
                                      return Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Text(
                                          day.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: _getDaysInMonth(
                                      selectedYear,
                                      selectedMonth,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      selectedMonth = index + 1;
                                      _updateSelectedDate();
                                    });
                                  },
                                  controller: FixedExtentScrollController(
                                    initialItem: selectedMonth - 1,
                                  ),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, index) {
                                      if (index < 0 || index >= 12) return null;
                                      final isSelected =
                                          index + 1 == selectedMonth;
                                      return Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          months[index],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 40,
                                  perspective: 0.005,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      selectedYear =
                                          DateTime.now().year - index;
                                      _updateSelectedDate();
                                    });
                                  },
                                  controller: FixedExtentScrollController(
                                    initialItem:
                                        DateTime.now().year - selectedYear,
                                  ),
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, index) {
                                      final year = DateTime.now().year - index;
                                      if (year < 1900) return null;
                                      final isSelected = year == selectedYear;
                                      return Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          year.toString(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: DateTime.now().year - 1900 + 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}
