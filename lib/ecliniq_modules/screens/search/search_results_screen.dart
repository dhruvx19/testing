import 'dart:developer' as developer;
import 'package:ecliniq/ecliniq_api/search_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Search results screen displaying doctors and hospitals from search API
class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final String? authToken;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    this.authToken,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _searchResults;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Perform search using the search service
  /// @description Calls the search API and updates the UI with results
  Future<void> _performSearch({String? query}) async {
    final searchQuery = query ?? _searchController.text;
    
    if (searchQuery.length < 3) {
      setState(() {
        _errorMessage = 'Search query must be at least 3 characters';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _searchService.searchProviders(
        query: searchQuery,
        authToken: widget.authToken,
      );

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _searchResults = response;
            _isLoading = false;
          });
          developer.log('Search results: ${response['data']}');
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Search failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error performing search: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 58,
        titleSpacing: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Results',
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
            color: Color(0xff424242),
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12,left: 16,right: 16, bottom: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search Doctors, Hospitals...',
          hintStyle: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
            color: Colors.grey.shade400,
          ),
         
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xff1C63D5),
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _performSearch(query: value.trim());
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
            ),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 32,
                vertical: 0,
              ),
              child: Text(
                _errorMessage!,
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1C63D5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults == null || _searchResults!['data'] == null) {
      return const Center(
        child: Text('No results found'),
      );
    }

    final data = _searchResults!['data'];
    final doctors = data['doctors'] as List<dynamic>? ?? [];
    final hospitals = data['hospitals'] as List<dynamic>? ?? [];

    if (doctors.isEmpty && hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'No results found for "${_searchController.text}"',
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Combine doctors and hospitals into a single list
    final List<Map<String, dynamic>> allItems = [];
    if (doctors.isNotEmpty) {
      allItems.add({'type': 'header', 'title': 'Doctors', 'count': doctors.length});
      for (var doctor in doctors) {
        allItems.add({'type': 'doctor', 'data': doctor});
      }
    }
    if (hospitals.isNotEmpty) {
      if (doctors.isNotEmpty) {
        allItems.add({'type': 'divider'});
      }
      allItems.add({'type': 'header', 'title': 'Hospitals', 'count': hospitals.length});
      for (var hospital in hospitals) {
        allItems.add({'type': 'hospital', 'data': hospital});
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      separatorBuilder: (_, index) {
        if (index < allItems.length - 1) {
          final current = allItems[index];
          final next = allItems[index + 1];
          // Don't add separator after headers, before headers, or after dividers
          if (current['type'] == 'header' || 
              next['type'] == 'header' || 
              current['type'] == 'divider') {
            return const SizedBox.shrink();
          }
        }
        return SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
        );
      },
      itemBuilder: (context, index) {
        final item = allItems[index];
        if (item['type'] == 'header') {
          return _buildSectionHeader(item['title'] as String, item['count'] as int);
        } else if (item['type'] == 'divider') {
          return const SizedBox(height: 8);
        } else if (item['type'] == 'doctor') {
          return _buildDoctorCard(item['data'] as Map<String, dynamic>);
        } else if (item['type'] == 'hospital') {
          return _buildHospitalCard(item['data'] as Map<String, dynamic>);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$title ($count)',
        style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
          color: Color(0xFF424242),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to doctor details
            developer.log('Navigate to doctor: ${doctor['id']}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: doctor['image'] != null
                      ? NetworkImage(doctor['image'] as String)
                      : null,
                  child: doctor['image'] == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Unknown Doctor',
                        style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (doctor['headline'] != null)
                        Text(
                          doctor['headline'] as String,
                          style: EcliniqTextStyles.responsiveBodyLarge(context).copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      if (doctor['specialties'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            (doctor['specialties'] as List).join(', '),
                            style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      if (doctor['workplaces'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            doctor['workplaces'] as String,
                            style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to hospital details
            developer.log('Navigate to hospital: ${hospital['id']}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: hospital['image'] != null
                      ? NetworkImage(hospital['image'] as String)
                      : null,
                  child: hospital['image'] == null
                      ? const Icon(Icons.local_hospital, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital['name'] ?? 'Unknown Hospital',
                        style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hospital['city'] != null)
                        Text(
                          hospital['city'] as String,
                          style: EcliniqTextStyles.responsiveBodyLarge(context).copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      if (hospital['specialties'] != null &&
                          (hospital['specialties'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            (hospital['specialties'] as List).join(', '),
                            style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build shimmer loading widget for search results
  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section header shimmer
        ShimmerLoading(
          width: 120,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        // Doctor card shimmers
        ...List.generate(3, (index) => _buildDoctorCardShimmer()),
        const SizedBox(height: 24),
        // Section header shimmer for hospitals
        ShimmerLoading(
          width: 120,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        // Hospital card shimmers
        ...List.generate(2, (index) => _buildHospitalCardShimmer()),
      ],
    );
  }

  /// Build shimmer for a doctor card
  Widget _buildDoctorCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ShimmerLoading(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(30),
        ),
        title: ShimmerLoading(
          width: 200,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ShimmerLoading(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: ShimmerLoading(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Build shimmer for a hospital card
  Widget _buildHospitalCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ShimmerLoading(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        title: ShimmerLoading(
          width: 200,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoading(
                width: 150,
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
        trailing: ShimmerLoading(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}