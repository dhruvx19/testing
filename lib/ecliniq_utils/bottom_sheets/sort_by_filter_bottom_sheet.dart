import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class SortByBottomSheet extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? initialSortOption;

  const SortByBottomSheet({
    super.key,
    required this.onChanged,
    this.initialSortOption,
  });

  @override
  State<SortByBottomSheet> createState() => _SortByBottomSheetState();
}

class _SortByBottomSheetState extends State<SortByBottomSheet> {
  late String? selectedSortOption;

  @override
  void initState() {
    super.initState();
    selectedSortOption = widget.initialSortOption;
  }

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
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
          topRight: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
          bottomLeft: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
          bottomRight: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
        ),
      ),
      child: Column(
        children: [
          
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 16,
              right: 16,
              top: 22,
              bottom: 0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                  ),
                  GestureDetector(
                    onTap: _resetSort,
                    child: Text(
                      'Clear',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff2372EC),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          
          Expanded(
            child: ListView.builder(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                left: 16,
                right: 16,
                top: 0,
                bottom: 0,
              ),
              itemCount: sortOptions.length,
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final isSelected = selectedSortOption == option;
                return _buildSortOption(option, isSelected);
              },
            ),
          ),

          
        ],
      ),
    );
  }

  void _resetSort() {
    setState(() {
      selectedSortOption = null;
    });
    
    widget.onChanged('');
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
        padding: EdgeInsets.only(
          top: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          bottom: EcliniqTextStyles.getResponsiveSpacing(context, 4),
        ),
        child: Row(
          children: [
            Container(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
              width: EcliniqTextStyles.getResponsiveSpacing(context, 24),
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
                      margin: EdgeInsets.all(
                        EcliniqTextStyles.getResponsiveSpacing(context, 5),
                      ),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 10),
            ),
            Expanded(
              child: Text(
                option,
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
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
