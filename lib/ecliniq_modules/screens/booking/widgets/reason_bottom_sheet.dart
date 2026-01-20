import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class ReasonBottomSheet extends StatelessWidget {
  final List<String> reasons;
  final String? selectedReason;

  const ReasonBottomSheet({
    super.key,
    required this.reasons,
    this.selectedReason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Select Reason for Visit',
            style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
          
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reasons.length,
              itemBuilder: (context, index) {
                final reason = reasons[index];
                final isSelected = reason == selectedReason;

                return _ReasonOption(
                  reason: reason,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.pop(context, reason);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  final String reason;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonOption({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2B7FFF)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  reason,
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2B7FFF),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
