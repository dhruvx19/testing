import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:ecliniq/ecliniq_utils/phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class BranchesPage extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String? hospitalImage;
  final String? hospitalLogo;
  final String? hospitalType;
  final int? totalDoctors;
  final int? totalBeds;
  final int? patientsServed;
  final bool hideAppBar;

  const BranchesPage({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    this.hospitalImage,
    this.hospitalLogo,
    this.hospitalType,
    this.totalDoctors,
    this.totalBeds,
    this.patientsServed,
    this.hideAppBar = false,
  });

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  bool _isLoading = true;
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _branches = [
        BranchModel(
          id: '1',
          name: 'Manipal Hospital - Baner',
          type: 'Multi-speciality',
          doctorCount: 50,
          bedCount: 650,
          location: 'Wakad',
          distance: 4.0,
          rating: 4.0,
          opdTiming:
              'Mon-Fri (10:00 AM - 2:00 PM), Sat - Sun (4:00 PM - 6:00 PM)',
        ),
        BranchModel(
          id: '2',
          name: 'Manipal Hospital - Wakad',
          type: 'Multi-speciality',
          doctorCount: 20,
          bedCount: 650,
          location: 'Wakad',
          distance: 4.0,
          rating: 4.0,
          opdTiming:
              'Mon-Fri (10:00 AM - 2:00 PM), Sat - Sun (4:00 PM - 6:00 PM)',
        ),
        BranchModel(
          id: '3',
          name: 'Manipal Hospital - Kharadi',
          type: 'Multi-speciality',
          doctorCount: 35,
          bedCount: 450,
          location: 'Kharadi',
          distance: 8.5,
          rating: 4.2,
          opdTiming: 'Mon-Sat (9:00 AM - 5:00 PM)',
        ),
      ];
      _isLoading = false;
    });
  }

  String _getImageUrl(String? imageKey) {
    if (imageKey == null || imageKey.isEmpty) {
      return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
    }
    return imageKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading ? _buildShimmerScreen() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section with Image
          _buildHeaderSection(),

          // Stats Cards
          _buildStatsCards(),

          // Divider
          HorizontalDivider(),

          // Branches List
          _buildBranchesList(),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(_getImageUrl(widget.hospitalImage)),
              fit: BoxFit.cover,
            ),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 50,
                left: 16,
                child: _buildCircleButton(
                  EcliniqIcons.arrowLeft,
                  () => EcliniqRouter.pop(),
                ),
              ),
              // Share Button
              Positioned(
                top: 50,
                right: 16,
                child: _buildCircleButton(EcliniqIcons.share, () {}),
              ),
            ],
          ),
        ),

        // Hospital Logo
        Positioned(
          top: 150,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff2372EC), width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child:
                        widget.hospitalLogo != null &&
                            widget.hospitalLogo!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _getImageUrl(widget.hospitalLogo),
                              width: 94,
                              height: 94,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.local_hospital,
                                  size: 50,
                                  color: Colors.orange[700],
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.local_hospital,
                            size: 50,
                            color: Colors.orange[700],
                          ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
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
        ),

        // Hospital Info
        Container(
          margin: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
            top: 260,
            bottom: 0,
            left: 0,
            right: 0,
          ),
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 16,
            vertical: 0,
          ),
          child: Column(
            children: [
              Text(
                'Manipal Hospital',
                style:  EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
           
                  fontWeight: FontWeight.w600,
                  color: Color(0xff424242),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.hospitalType ?? 'Multi-Specialty',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Container(
                    width: 0.5,
                    height: 20,
                    color: const Color(0xffD6D6D6),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Text(
                    'All Branches Near You',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(EcliniqIcons icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            icon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalDoctors = widget.totalDoctors ?? 90;
    final totalBeds = widget.totalBeds ?? 1800;
    final patientsServed = widget.patientsServed ?? (totalDoctors * 1000);
    return Container(
      color: Colors.white,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 0,
        vertical: 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16,
          vertical: 0,
        ),
        child: Row(
          children: [
            _buildStatCard(
              EcliniqIcons.usersGroupRounded,
              'Patients Served',

              _formatNumber(patientsServed),
            ),
            DashedVerticalDivider(height: 110),
            _buildStatCard(
              EcliniqIcons.stethoscopeBlue,
              'Doctors',
              '$totalDoctors',
            ),
            DashedVerticalDivider(height: 110),
            _buildStatCard(
              EcliniqIcons.bed,
              'Total Beds',
              _formatNumber(totalBeds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(final EcliniqIcons icon, String label, String value) {
    return SizedBox(
      width: 140,
      child: Column(
        children: [
          SvgPicture.asset(
            icon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              fontWeight: FontWeight.w400,
              color: Color(0xff626060),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),
          Text(
            value,
            style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
             
              fontWeight: FontWeight.w600,
              color: Color(0xff2372EC),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

  Widget _buildBranchesList() {
    if (_branches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _branches.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => SizedBox(
        height: EcliniqTextStyles.getResponsiveSpacing(context, 0),
      ),
      itemBuilder: (context, index) {
        return _buildBranchCard(_branches[index]);
      },
    );
  }

  Widget _buildBranchCard(BranchModel branch) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Name with Verified Badge
              Row(
                children: [
                  Text(
                    branch.name,
                    style:  EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                    
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    EcliniqIcons.verified.assetPath,
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
              SizedBox(height: 4),

              // Type | Doctors | Beds
              Text(
                '${branch.type} | ${branch.doctorCount}+ Doctors | ${branch.bedCount} Beds',
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),

              // Location and Rating Row
              Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.mapPointBlack.assetPath,
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    branch.location,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF9F9F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xffB8B8B8),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${branch.distance.toStringAsFixed(0)} KM',
                          style:  EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                      
                            color: Color(0xff424242),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          EcliniqIcons.mapArrow.assetPath,
                          width: 12,
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF9E6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.star.assetPath,
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          branch.rating.toString(),
                          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                            color: Color(0xffBE8B00),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),

              // OPD Timing
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.clockCircle.assetPath,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'OPD Timing: ${branch.opdTiming}',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
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
                            HospitalDetailScreen(hospitalId: branch.id),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2372EC),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View All Doctors',
                              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
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
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => PhoneLauncher.launchPhoneCall(null),
                    icon: SvgPicture.asset(
                      EcliniqIcons.phone.assetPath,
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),
        HorizontalDivider(color: Color(0xffD6D6D6)),
      ],
    );
  }

  Widget _buildShimmerScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(height: 200, color: Colors.white),
          ),
          const SizedBox(height: 60),
          // Title Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 28,
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 20,
              width: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Stats Shimmer
          _buildShimmerStats(),
          const SizedBox(height: 16),
          // Branch Cards Shimmer
          _buildShimmerCard(),
          const SizedBox(height: 16),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (index) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 22,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 16,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Branches Found',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
          ),
            Text(
              'No branches available for this hospital',
              textAlign: TextAlign.center,
              style: EcliniqTextStyles.responsiveBodySmall(context).copyWith( color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// Branch Model
class BranchModel {
  final String id;
  final String name;
  final String type;
  final int doctorCount;
  final int bedCount;
  final String location;
  final double distance;
  final double rating;
  final String opdTiming;

  BranchModel({
    required this.id,
    required this.name,
    required this.type,
    required this.doctorCount,
    required this.bedCount,
    required this.location,
    required this.distance,
    required this.rating,
    required this.opdTiming,
  });
}
