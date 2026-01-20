import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TimeSlotCard extends StatefulWidget {
  final String title;
  final String time;
  final int available;
  final String iconPath;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const TimeSlotCard({
    super.key,
    required this.title,
    required this.time,
    required this.available,
    required this.iconPath,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  State<TimeSlotCard> createState() => _TimeSlotCardState();
}

class _TimeSlotCardState extends State<TimeSlotCard> {
  bool _isPressed = false;

  Color _getAvailabilityColor() {
    if (widget.isDisabled || widget.available == 0) {
      return Color(0xffB8B8B8);
    }
    if (widget.available <= 2) return const Color(0xFFBE8B00);
    if (widget.available <= 5) return const Color(0xFFBE8B00);
    return const Color(0xFF3EAf3f);
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (widget.isDisabled) {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFB8B8B8);
      textColor = Color(0xffB8B8B8);
    } else if (_isPressed) {
      backgroundColor = const Color(0xFF2372EC);
      borderColor = const Color(0xFF2372EC);
      textColor = Colors.white;
    } else if (widget.isSelected) {
      backgroundColor = const Color(0xFFF8FAFF);
      borderColor = const Color(0xFF0D47A1);
      textColor = const Color(0xFF0D47A1);
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFB8B8B8);
      textColor = Colors.black87;
    }

    return Listener(
      onPointerDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onPointerUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onPointerCancel: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: Opacity(
          opacity: widget.isDisabled ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    left: 12,
                    top: 20,
                    bottom: 20,
                    right: 10,
                  ),
                  child: SvgPicture.asset(
                    widget.iconPath,
                    width: 32,
                    height: 32,
                    colorFilter: widget.isDisabled
                        ? const ColorFilter.mode(Colors.grey, BlendMode.srcIn)
                        : _isPressed
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : null,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.title} (${widget.time})',
                          style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDisabled
                                ? Colors.transparent
                                : _isPressed
                                ? Colors.white.withOpacity(0.9)
                                : _getAvailabilityColor().withOpacity(0.15),
                            border: Border.all(
                              color: widget.isSelected
                                  ? Color(0xff2372EC)
                                  : Colors.transparent,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.available == 0
                                ? 'No tokens available'
                                : '${widget.available} Tokens Available',
                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                              color: _getAvailabilityColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
