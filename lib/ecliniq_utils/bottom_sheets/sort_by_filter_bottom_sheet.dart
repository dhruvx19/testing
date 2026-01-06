import 'package:flutter/material.dart';

class SortByBottomSheet extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const SortByBottomSheet({super.key, required this.onChanged});

  @override
  State<SortByBottomSheet> createState() => _SortByBottomSheetState();
}

class _SortByBottomSheetState extends State<SortByBottomSheet> {
  String? selectedSortOption;

  final List<String> sortOptions = [
    'Relevance',
    'Price: Low - High',
    'Price: High - Low',
    'Experience - Most Experience first',
    'Distance - Nearest First',
    'Order A-Z',
    'Order Z-A',
    'Rating High - low',
    'Rating Low - High',
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
          // Title
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),

       

          // List of sort options
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(left: 16, right: 16),
              itemCount: sortOptions.length,
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final isSelected = selectedSortOption == option;
                return _buildSortOption(option, isSelected);
              },
            ),
          ),

          // Apply button
        ],
      ),
    );
  }

  Widget _buildSortOption(String option, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedSortOption = option;
        });
        widget.onChanged(option);
      },
      child: Padding(
        padding: EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            Container(
              height: 24,
              width: 24,
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
                      margin: const EdgeInsets.all(5),
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
