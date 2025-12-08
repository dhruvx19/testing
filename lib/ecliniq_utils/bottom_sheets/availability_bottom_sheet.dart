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
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Availability Filter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List of availability options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xff2372EC) : Color(0xff8E8E8E),
                  width: 1,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff2372EC),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 18,
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
