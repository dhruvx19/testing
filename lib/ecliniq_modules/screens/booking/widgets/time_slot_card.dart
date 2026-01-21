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

  Color _getAvailabilityColorToken() {
    if (widget.isDisabled || widget.available == 0) {
      return Color(0xffB8B8B8);
    }
    if (widget.available <= 2) return const Color(0xFFFEF9E6);
    if (widget.available <= 5) return const Color(0xFFFEF9E6);
    return const Color(0xFFF2FFF3);
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color titleColor;
    Color timeColor;

    if (widget.isDisabled) {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFD6D6D6);
      titleColor = const Color(0xFFD6D6D6);
      timeColor = const Color(0xFFD6D6D6);
    } else if (_isPressed) {
      backgroundColor = const Color(0xFF2372EC);
      borderColor = const Color(0xFF2372EC);
      titleColor = Colors.white;
      timeColor = Colors.white;
    } else if (widget.isSelected) {
      backgroundColor = const Color(0xFFF8FAFF);
      borderColor = const Color(0xFF0D47A1);
      titleColor = const Color(0xFF424242);
      timeColor = const Color(0xFF424242);
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFB8B8B8);
      titleColor = const Color(0xFF424242);
      timeColor = const Color(0xFF424242);
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
                 
                        Row(
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: titleColor,
                              ),
                            ),
                        SizedBox(width: 4,),
                        Text(
                          '(${widget.time})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: timeColor,
                          ),
                        ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        // Only show container when tokens are available
                        if (widget.available > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isPressed
                                  ? Colors.white.withOpacity(0.9)
                                  : _getAvailabilityColorToken(),
                              border: Border.all(
                                color: widget.isSelected
                                    ? Color(0xff2372EC)
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.available} Tokens Available',
                              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                color: _getAvailabilityColor(),
                              ),
                            ),
                          )
                        else
                          // Simple text without container padding when no tokens
                          Text(
                            'No tokens available',
                            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                              color: _getAvailabilityColor(),
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