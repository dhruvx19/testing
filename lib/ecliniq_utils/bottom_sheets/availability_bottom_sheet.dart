import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class AvailabilityFilterBottomSheet extends StatefulWidget {
  const AvailabilityFilterBottomSheet({super.key});

  @override
  State<AvailabilityFilterBottomSheet> createState() =>
      _AvailabilityFilterBottomSheetState();
}

class _AvailabilityFilterBottomSheetState
    extends State<AvailabilityFilterBottomSheet> {
  String? selectedAvailability;

  final List<String> availabilityOptions = [
    'Now',
    'Today',
    'Tomorrow',
    'Tuesday, 19 Aug',
    'Wednesday, 20 Aug',
    'Thursday, 21 Aug',
    'Friday, 22 Aug',
    'Saturday, 23 Aug',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
           Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Availability Filter',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
            
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // List of availability options
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(left: 16, right: 16),
              itemCount: availabilityOptions.length,
              itemBuilder: (context, index) {
                final option = availabilityOptions[index];
                final isSelected = selectedAvailability == option;
                return _buildAvailabilityOption(option, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityOption(String option, bool isSelected) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, option);
      },
      child: Padding(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
          context,
          top: 16,
          bottom: 8,
          left: 0,
          right: 0,
        ),
        child: Row(
          children: [
            Container(
              height: EcliniqTextStyles.getResponsiveHeight(context, 24),
              width: EcliniqTextStyles.getResponsiveWidth(context, 24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF8E8E8E),
                  width: 1,
                ),
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              ),
              child: isSelected
                  ? Container(
                      margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option,
                style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
               
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
