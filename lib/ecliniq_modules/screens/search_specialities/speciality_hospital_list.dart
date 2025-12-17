import 'dart:async';

import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/location_search.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_details.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/widgets/horizontal_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SpecialityHospitalList extends StatefulWidget {
  final String? initialSpeciality;

  const SpecialityHospitalList({super.key, this.initialSpeciality});

  @override
  State<SpecialityHospitalList> createState() => _SpecialityHospitalListState();
}

class _SpecialityHospitalListState extends State<SpecialityHospitalList> {
  final HospitalService _hospitalService = HospitalService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();

  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final String _currentLocation = 'Vishnu Dev Nagar, Wakad';

  final double _latitude = 28.6139;
  final double _longitude = 77.209;

  // Updated category list for hospitals
  final List<String> _categories = [
    'All',
    'Multispeciality',
    'Super Speciality',
    'Eye Care',
    'Dental Care',
    'Orthopaedic',
    'Cardiac Care',
    'Maternity',
    'Children',
    'Cancer Care',
  ];

  // Keys for each category to measure their positions
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize keys for all categories
    for (var category in _categories) {
      _categoryKeys[category] = GlobalKey();
    }

    if (widget.initialSpeciality != null) {
      _selectedCategory = widget.initialSpeciality!;
      // Add initial speciality if not in list
      if (!_categories.contains(widget.initialSpeciality)) {
        _categories.insert(1, widget.initialSpeciality!);
        _categoryKeys[widget.initialSpeciality!] = GlobalKey();
      }
    }

    _fetchHospitals();
    _searchController.addListener(_onSearchChanged);

    // Auto scroll to initial category after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCategory(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      final RenderBox renderBox =
          key!.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(context).size.width;
      final boxWidth = renderBox.size.width;

      // Calculate scroll offset to center the selected category
      final scrollOffset =
          _categoryScrollController.offset +
          position.dx -
          (screenWidth / 2) +
          (boxWidth / 2);

      _categoryScrollController.animateTo(
        scrollOffset.clamp(
          0.0,
          _categoryScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _scrollToCategory(category);
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _hospitalService.getAllHospitals(
        latitude: _latitude,
        longitude: _longitude,
      );

      if (response.success && mounted) {
        setState(() {
          _hospitals = response.data;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load hospitals: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<Hospital> get _filteredHospitals {
    List<Hospital> filtered = _hospitals;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((hospital) {
        final type = hospital.type.toLowerCase();
        final category = _selectedCategory.toLowerCase();
        return type.contains(category) || category.contains(type);
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((hospital) {
        final name = hospital.name.toLowerCase();
        final city = hospital.city.toLowerCase();
        return name.contains(_searchQuery) || city.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Hospital',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: const Color(0xff424242),
            ),
          ),
        ),
        actions: [
          SvgPicture.asset(
            EcliniqIcons.sortAlt.assetPath,
            width: 32,
            height: 32,
          ),
          VerticalDivider(
            color: Color(0xffD6D6D6),
            thickness: 1,
            width: 24,
            indent: 18,
            endIndent: 18,
          ),
          SvgPicture.asset(
            EcliniqIcons.filter.assetPath,
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFB8B8B8), height: 0.5),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildLocationSection(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(child: _buildHospitalList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return GestureDetector(
      onTap: () {
        EcliniqBottomSheet.show(
          context: context,
          child: LocationBottomSheet(
            currentLocation: 'Vishnu Dev Nagar, Wakad',
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.mapPointBlue.assetPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _currentLocation,
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: const Color(0xff424242),
              ),
            ),
            SizedBox(width: 10),
            Container(height: 20, width: 0.5, color: Color(0xffD6D6D6)),
            const SizedBox(width: 8.0),
            SvgPicture.asset(
              EcliniqIcons.arrowDown.assetPath,
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF626060), width: 0.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: SvgPicture.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: 24,
              height: 24,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Color(0xFF424242),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Search Hospital',
                hintStyle: TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              cursorColor: Color(0xFF2372EC),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SvgPicture.asset(
                EcliniqIcons.microphone.assetPath,
                width: 32,
                height: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: SingleChildScrollView(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                key: _categoryKeys[category],
                onTap: () => _onCategorySelected(category),
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? Color(0xFF2372EC)
                                  : Color(0xFF626060),
                            ),
                          ),
                        ),
                        Container(
                          height: 2,
                          color: isSelected
                              ? Color(0xFF2372EC)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    final hospitals = _filteredHospitals;

    if (hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(EcliniqIcons.noHospital.assetPath),
            const SizedBox(height: 8),
            Text(
              'No Hospital Match Found',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: Color(0xff424242),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: hospitals.length,
      itemBuilder: (context, index) {
        return _buildHospitalCard(hospitals[index]);
      },
    );
  }

  Widget _buildShimmerLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: Colors.grey.shade100,
                ),
                child:
                    hospital.image.isNotEmpty &&
                        _isValidImageUrl(hospital.image)
                    ? Image.network(
                        hospital.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF9E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.star.assetPath,
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            '4.0',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xffBE8B00),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xffF8FAFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xff96BFFF), width: 0.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          hospital.name.isNotEmpty
                              ? hospital.name.substring(0, 1)
                              : 'H',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: SvgPicture.asset(
                          EcliniqIcons.verified.assetPath,
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 12.0,
              bottom: 12.0,
              top: 28.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xff424242),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${hospital.type} | ${hospital.numberOfDoctors}+ Doctors',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff424242),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.mapPointBlack.assetPath,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${hospital.city}, ${hospital.state}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffF9F9F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xffB8B8B8),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              hospital.distance > 0
                                  ? '${hospital.distance.toStringAsFixed(1)} Km'
                                  : 'Nearby',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.clockCircle.assetPath,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'OPD: 10:00 AM - 2:00 PM , 4:00 PM - 6:00 PM',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4D2372EC),
                              offset: Offset(2, 2),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            EcliniqRouter.push(
                              HospitalDetailScreen(hospitalId: hospital.id),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2372EC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'View All Doctors',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(width: 2),
                              SvgPicture.asset(
                                EcliniqIcons.arrowRight.assetPath,
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    SvgPicture.asset(
                      EcliniqIcons.phone.assetPath,
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          HorizontalDivider(color: Color(0xffD6D6D6)),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    if (url.startsWith('file://') || url.startsWith('/hospitals/')) {
      return false;
    }
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital,
          size: 40,
          color: Colors.blue.shade300,
        ),
      ),
    );
  }
}
