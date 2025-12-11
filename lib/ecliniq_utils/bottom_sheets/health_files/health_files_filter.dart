import 'package:flutter/material.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/filter_bottom_sheet.dart';

class HealthFilesFilter extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApply;

  const HealthFilesFilter({super.key, this.onApply});

  @override
  State<HealthFilesFilter> createState() => HealthFilesFilterState();
}

class HealthFilesFilterState extends State<HealthFilesFilter> {
  String _selectedCategory = 'Sort By';
  String? _selectedSortBy;
  final Set<String> _selectedRelatedTo = {};
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Sort By', 'Related To'];

  final List<String> _sortByOptions = ['File Date', 'Upload Date'];

  final List<Map<String, String>> _relatedToOptions = [
    {'name': 'Ketan Patni', 'relation': 'You'},
    {'name': 'Archana Patni', 'relation': 'Mother'},
    {'name': 'Devendra Patni', 'relation': 'Father'},
    {'name': 'Pooja Patni', 'relation': 'Wife'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),
          // Search bar
          SearchBarWidget(onSearch: (String value) {}),
          const SizedBox(height: 20),
          Container(height: 0.5, color: const Color(0xffD6D6D6)),
          const SizedBox(height: 10),
          // Two column layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Categories
                SizedBox(
                  width: 130,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final tab = _categories[index];
                      final isSelected = _selectedCategory == tab;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = tab;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xffF8FAFF)
                                : Colors.transparent,
                            border: Border(
                              top: BorderSide(
                                color: isSelected
                                    ? const Color(0xff96BFFF)
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              bottom: BorderSide(
                                color: isSelected
                                    ? const Color(0xff96BFFF)
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              right: BorderSide(
                                color: isSelected
                                    ? const Color(0xff96BFFF)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xff2372EC)
                                  : Colors.grey[700],
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Divider
                Container(width: 0.5, color: const Color(0xffD6D6D6)),
                // Right column - Options
                Expanded(child: _buildOptionsColumn()),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionsColumn() {
    if (_selectedCategory == 'Sort By') {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sortByOptions.length,
        itemBuilder: (context, index) {
          final option = _sortByOptions[index];
          final isSelected = _selectedSortBy == option;
          return InkWell(
            onTap: () => setState(() => _selectedSortBy = option),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff2372EC)
                            : Colors.grey[400]!,
                        width: 2,
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
                ],
              ),
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _relatedToOptions.length,
        itemBuilder: (context, index) {
          final option = _relatedToOptions[index];
          final isSelected = _selectedRelatedTo.contains(option['name']);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedRelatedTo.remove(option['name']);
                } else {
                  _selectedRelatedTo.add(option['name']!);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${option['name']} (${option['relation']})',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff2372EC)
                            : const Color(0xff8E8E8E),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: isSelected ? Colors.blue : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

// Usage example:
// showModalBottomSheet(
//   context: context,
//   isScrollControlled: true,
//   backgroundColor: Colors.transparent,
//   builder: (context) => const FilterBottomSheet(),
// );
