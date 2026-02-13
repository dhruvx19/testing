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
  final VoidCallback? onBackPressed;

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
    required this.onBackPressed,
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
          _buildHeaderSection(),

          _buildStatsCards(),

          HorizontalDivider(),

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
        Container(
          height: EcliniqTextStyles.getResponsiveHeight(context, 210.0),
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
              Positioned(
                top: EcliniqTextStyles.getResponsiveSize(context, 44.0),
                left: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
                child: _buildCircleButton(EcliniqIcons.arrowLeft, () {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else {
                    Navigator.pop(context);
                  }
                }),
              ),

              Positioned(
                top: EcliniqTextStyles.getResponsiveSize(context, 44.0),
                right: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
                child: _buildCircleButton(EcliniqIcons.share, () {}),
              ),
            ],
          ),
        ),

        Builder(
          builder: (context) {
            final headerHeight = EcliniqTextStyles.getResponsiveHeight(
              context,
              210.0,
            );
            final circleSize = EcliniqTextStyles.getResponsiveSize(
              context,
              80.0,
            );
            final circleRadius = circleSize / 2;
            
            final topPosition = headerHeight - circleRadius;

            return Positioned(
              top: topPosition,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xff2372EC),
                      width: EcliniqTextStyles.getResponsiveSize(
                        context,
                        2.0,
                      ),
                    ),
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
                                  width: EcliniqTextStyles.getResponsiveSize(
                                    context,
                                    94.0,
                                  ),
                                  height: EcliniqTextStyles.getResponsiveSize(
                                    context,
                                    94.0,
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.local_hospital,
                                      size: EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        60.0,
                                      ),
                                      color: Colors.orange[700],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.local_hospital,
                                size: EcliniqTextStyles.getResponsiveIconSize(
                                  context,
                                  60.0,
                                ),
                                color: Colors.orange[700],
                              ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SvgPicture.asset(
                          EcliniqIcons.verified.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            24.0,
                          ),
                          height: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

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
                widget.hospitalName,
                style: EcliniqTextStyles.responsiveHeadlineXLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff424242),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.hospitalType ?? 'Multi-Specialty',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
                  ),
                  Container(
                    width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                    height: EcliniqTextStyles.getResponsiveHeight(context, 20.0),
                    color: const Color(0xffD6D6D6),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
                  ),
                  Text(
                    'All Branches Near You',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
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
      borderRadius: BorderRadius.circular(
        EcliniqTextStyles.getResponsiveBorderRadius(context, 20.0),
      ),
      child: Container(
        width: EcliniqTextStyles.getResponsiveSize(context, 40.0),
        height: EcliniqTextStyles.getResponsiveSize(context, 40.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            icon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
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
            DashedVerticalDivider(
              height: EcliniqTextStyles.getResponsiveHeight(context, 110.0),
            ),
            _buildStatCard(
              EcliniqIcons.stethoscopeBlue,
              'Doctors',
              '$totalDoctors',
            ),
            DashedVerticalDivider(
              height: EcliniqTextStyles.getResponsiveHeight(context, 110.0),
            ),
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
      width: EcliniqTextStyles.getResponsiveWidth(context, 140.0),
      child: Column(
        children: [
          SvgPicture.asset(
            icon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
          Text(
            label,
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff626060)),
            textAlign: TextAlign.center,
          ),
        
          Text(
            value,
            style: EcliniqTextStyles.responsiveHeadlineXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Color(0xff2372EC)),
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
      separatorBuilder: (context, index) =>
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 0)),
      itemBuilder: (context, index) {
        return _buildBranchCard(_branches[index]);
      },
    );
  }

  Widget _buildBranchCard(BranchModel branch) {
    return Column(
      children: [
        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
            left: 12.0,
            right: 12.0,
            top: 24.0,
            bottom: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    branch.name,
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          color: Color(0xff424242),
                        ),
                  ),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0)),
                  SvgPicture.asset(
                    EcliniqIcons.verified.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                  ),
                ],
              ),
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),

              Text(
                '${branch.type} | ${branch.doctorCount}+ Doctors | ${branch.bedCount} Beds',
                style: EcliniqTextStyles.responsiveTitleXLarge(context)
                    .copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),

              Row(
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.mapPointBlack.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 26.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 26.0),
                  ),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                  Text(
                    branch.location,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Container(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 6.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF9F9F9),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                      ),
                      border: Border.all(
                        color: const Color(0xffB8B8B8),
                        width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(branch.distance / 1000).toStringAsFixed(0)} KM',
                          style: EcliniqTextStyles.responsiveBodySmall(context)
                              .copyWith(
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                        SvgPicture.asset(
                          EcliniqIcons.mapArrow.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 12.0),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 12.0),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 6.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF9E6),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 6.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.star.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 18.0),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 18.0),
                        ),
                        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                        Text(
                          branch.rating.toString(),
                          style:
                              EcliniqTextStyles.responsiveTitleXLarge(
                                context,
                              ).copyWith(
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

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.clockCircle.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                  ),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                  Expanded(
                    child: Text(
                      'OPD Timing: ${branch.opdTiming}',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context)
                          .copyWith(
                            color: Color(0xff424242),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4D2372EC),
                            offset: Offset(
                              EcliniqTextStyles.getResponsiveSize(context, 2.0),
                              EcliniqTextStyles.getResponsiveSize(context, 2.0),
                            ),
                            blurRadius: EcliniqTextStyles.getResponsiveSize(context, 10.0),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      height: EcliniqTextStyles.getResponsiveButtonHeight(
                        context,
                        baseHeight: 52.0,
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          EcliniqRouter.push(
                            HospitalDetailScreen(hospitalId: branch.id),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2372EC),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View All Doctors',
                              style:
                                  EcliniqTextStyles.responsiveHeadlineBMedium(
                                    context,
                                  ).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
                            SvgPicture.asset(
                              EcliniqIcons.arrowRight.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                              height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
                  IconButton(
                    onPressed: () => PhoneLauncher.launchPhoneCall(null),
                    icon: SvgPicture.asset(
                      EcliniqIcons.phone.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
        HorizontalDivider(color: Color(0xffD6D6D6)),
      ],
    );
  }

  Widget _buildShimmerScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: EcliniqTextStyles.getResponsiveHeight(context, 200.0),
              color: Colors.white,
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 60.0)),

          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: EcliniqTextStyles.getResponsiveHeight(context, 28.0),
              width: EcliniqTextStyles.getResponsiveWidth(context, 200.0),
              margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16.0,
                vertical: 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: EcliniqTextStyles.getResponsiveHeight(context, 20.0),
              width: EcliniqTextStyles.getResponsiveWidth(context, 250.0),
              margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16.0,
                vertical: 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0)),

          _buildShimmerStats(),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),

          _buildShimmerCard(),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerStats() {
    return Padding(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16.0,
        vertical: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (index) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: EcliniqTextStyles.getResponsiveWidth(context, 100.0),
              height: EcliniqTextStyles.getResponsiveHeight(context, 80.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16.0,
        vertical: 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveHeight(context, 22.0),
                width: EcliniqTextStyles.getResponsiveWidth(context, 200.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
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
                height: EcliniqTextStyles.getResponsiveHeight(context, 16.0),
                width: EcliniqTextStyles.getResponsiveWidth(context, 250.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveHeight(context, 16.0),
                width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveHeight(context, 16.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveHeight(context, 48.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
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
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64.0),
              color: Colors.grey.shade400,
            ),
            SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
            Text(
              'No Branches Found',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                  .copyWith(
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
              style: EcliniqTextStyles.responsiveBodySmall(
                context,
              ).copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

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
