import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HealthFilesFilter extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApply;
  final Set<String>? initialSelectedNames;

  const HealthFilesFilter({super.key, this.onApply, this.initialSelectedNames});

  @override
  State<HealthFilesFilter> createState() => HealthFilesFilterState();
}

class HealthFilesFilterState extends State<HealthFilesFilter> {
  String _selectedCategory = 'Sort By';
  String? _selectedSortBy;
  final Set<String> _selectedRelatedTo = {};
  final TextEditingController _searchController = TextEditingController();
  final PatientService _patientService = PatientService();

  final List<String> _categories = ['Sort By', 'Related To'];
  final List<String> _sortByOptions = ['File Date', 'Upload Date'];

  List<Map<String, String>> _relatedToOptions = [];
  bool _isLoadingDependents = true;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    // Initialize with previously selected names if provided
    if (widget.initialSelectedNames != null) {
      _selectedRelatedTo.addAll(widget.initialSelectedNames!);
    }
    _fetchDependentsAndUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedRelatedTo.clear();
      _selectedSortBy = null;
      _selectedCategory = 'Sort By';
      _searchController.clear();
    });
    // Emit empty filter state to clear active filters in parent and close bottom sheet
    final result = {
      'selectedNames': <String>[],
      'sortBy': null,
    };
    widget.onApply?.call(result);
    Navigator.of(context).pop(result);
  }

  Future<void> _fetchDependentsAndUser() async {
    setState(() {
      _isLoadingDependents = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null || authToken.isEmpty) {
        setState(() {
          _isLoadingDependents = false;
        });
        return;
      }

      // Fetch current user details
      final userResponse = await _patientService.getPatientDetails(
        authToken: authToken,
      );

      // Fetch dependents
      final dependentsResponse = await _patientService.getDependents(
        authToken: authToken,
      );

      if (mounted) {
        setState(() {
          _relatedToOptions = [];

          // Add current user
          if (userResponse.success && userResponse.data != null) {
            final user = userResponse.data!;
            _currentUserName = user.fullName;
            _relatedToOptions.add({'name': user.fullName, 'relation': 'You'});
          }

          // Add dependents
          if (dependentsResponse.success) {
            for (final dependent in dependentsResponse.data) {
              _relatedToOptions.add({
                'name': dependent.fullName,
                'relation': dependent.relation,
              });
            }
          }

          _isLoadingDependents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDependents = false;
        });
      }
      debugPrint('Failed to fetch dependents and user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                  ),
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Text(
                      'Reset',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                          .copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff2372EC),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search bar
          SearchBarWidget(onSearch: (String value) {}),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 20),
          ),
          Container(
            height: 0.5,
            color: const Color(0xffD6D6D6),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 10),
          ),
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
                          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                            context,
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
                            style:
                                EcliniqTextStyles.responsiveTitleXLarge(
                                  context,
                                ).copyWith(
                                  color: isSelected
                                      ? const Color(0xff2372EC)
                                      : Colors.grey[700],

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
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          ),
          // Apply and Clear buttons
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 16,
              vertical: 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 0,
                        vertical: 14,
                      ),
                      side: const BorderSide(color: Color(0xffD6D6D6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                        ),
                      ),
                    ),
                    child: Text(
                      'Clear',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context)
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            color: Color(0xff424242),
                          ),
                    ),
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 12),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final result = {
                        'selectedNames': _selectedRelatedTo.toList(),
                        'sortBy': _selectedSortBy,
                      };
                      widget.onApply?.call(result);
                      Navigator.of(context).pop(result);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 0,
                        vertical: 14,
                      ),
                      backgroundColor: const Color(0xff2372EC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                        ),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context)
                          .copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsColumn() {
    if (_selectedCategory == 'Sort By') {
      return ListView.builder(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 0,
          vertical: 8,
        ),
        itemCount: _sortByOptions.length,
        itemBuilder: (context, index) {
          final option = _sortByOptions[index];
          final isSelected = _selectedSortBy == option;
          return InkWell(
            onTap: () => setState(() => _selectedSortBy = option),
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: EcliniqTextStyles.responsiveTitleXLarge(context)
                          .copyWith(
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
      if (_isLoadingDependents) {
        return ListView.builder(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 0,
          vertical: 8,
        ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: double.infinity,
                          height: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        ShimmerLoading(
                          width: 100,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerLoading(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            );
          },
        );
      }

      if (_relatedToOptions.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No dependents found',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Color(0xff8E8E8E)),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 0,
          vertical: 8,
        ),
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
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${option['name']} (${option['relation']})',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context)
                          .copyWith(
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
                      color: isSelected
                          ? const Color(0xff2372EC)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                            color: Colors.white,
                          )
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
