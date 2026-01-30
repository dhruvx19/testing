import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/easy_to_book.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/branches.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_doctors.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/surgeries_list.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/provider/hospital_detail_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/widgets/about_hospital.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/widgets/address_widget.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/widgets/appointment_timing.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/widgets/specialities.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class HospitalDetailScreen extends StatefulWidget {
  final String hospitalId;

  const HospitalDetailScreen({super.key, required this.hospitalId});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen>
    with SingleTickerProviderStateMixin {
  late final HospitalDetailProvider _provider;
  late TabController _tabController;
  int _currentTabIndex = 0;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _provider = HospitalDetailProvider();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.fetchHospitalDetails(hospitalId: widget.hospitalId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  /// Get image URL from storage key
  /// @description Gets the public URL for a storage key if it starts with "public/",
  /// otherwise returns a fallback URL
  /// @param imageKey - Image key or URL
  /// @returns Future<String> - Public URL or fallback URL
  Future<String> _getImageUrl(String? imageKey) async {
    return await _storageService.getImageUrl(
      imageKey,
      fallbackUrl:
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ChangeNotifierProvider<HospitalDetailProvider>.value(
        key: ValueKey('hospital_detail_provider_${widget.hospitalId}'),
        value: _provider,
        child: Consumer<HospitalDetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildShimmerScreen();
            }

            if (provider.errorMessage != null) {
              return _buildErrorScreen(
                errorMessage: provider.errorMessage!,
                onRetry: () {
                  provider.retry(hospitalId: widget.hospitalId);
                },
              );
            }

            if (!provider.hasHospitalDetail) {
              return _buildEmptyScreen();
            }

            final hospital = provider.hospitalDetail!;
            return _buildContent(hospital);
          },
        ),
      ),
    );
  }

  Widget _buildContent(hospital) {
    return Stack(
      children: [
        // Tab Content
        IndexedStack(
          index: _currentTabIndex,
          children: [
            // Details Tab
            _buildDetailsContent(hospital),
            // Doctors Tab
            _buildDoctorsContent(hospital),

            _buildSurgeriesContent(),
            _buildBranchesContent(),
          ],
        ),
        // Floating Tab Section (only show for Details tab)
        if (_currentTabIndex == 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: _buildFloatingTabSection(),
          ),
        // Bottom Section (only show for Details tab)
        if (_currentTabIndex == 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSection(),
          ),
      ],
    );
  }

  Widget _buildDetailsContent(hospital) {
    return RefreshIndicator(
      onRefresh: () async =>
          await _provider.fetchHospitalDetails(hospitalId: widget.hospitalId),
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(hospital),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                ),
                _buildHospitalInfo(hospital),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                ),
                _buildStatsCards(hospital),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                ),
                HorizontalDivider(),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                ),
                const AppointmentTimingWidget(),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                ),
                AddressWidget(hospital: hospital),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                ),
                AboutHospital(hospital: hospital),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                ),
                if (hospital.specialties.isNotEmpty)
                  MedicalSpecialtiesWidget(specialties: hospital.specialties),
                if (hospital.specialties.isNotEmpty)
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                  ),
                if (hospital.hospitalServices.isNotEmpty)
                  HospitalServicesWidget(services: hospital.hospitalServices),
                if (hospital.hospitalServices.isNotEmpty)
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                  ),
                if (hospital.accreditation.isNotEmpty)
                  CertificatesWidget(accreditation: hospital.accreditation),
                if (hospital.accreditation.isNotEmpty)
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                  ),

                const ContactDetailsWidget(),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                ),
                const EasyWayToBookWidget(),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 200),
                ),
              ],
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
                // Position circle so it's half on background and half below
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
                            child: hospital.logo.isNotEmpty
                                ? FutureBuilder<String>(
                                    future: _getImageUrl(hospital.logo),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        final logoSize =
                                            EcliniqTextStyles.getResponsiveSize(
                                              context,
                                              94.0,
                                            );
                                        return SizedBox(
                                          width: logoSize,
                                          height: logoSize,
                                          child: const Center(
                                            child: EcliniqLoader(),
                                          ),
                                        );
                                      }
                                      final imageUrl =
                                          snapshot.data ??
                                          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
                                      final logoSize =
                                          EcliniqTextStyles.getResponsiveSize(
                                            context,
                                            94.0,
                                          );
                                      return ClipOval(
                                        child: Image.network(
                                          imageUrl,
                                          width: logoSize,
                                          height: logoSize,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.local_hospital,
                                                  size:
                                                      EcliniqTextStyles.getResponsiveIconSize(
                                                        context,
                                                        60.0,
                                                      ),
                                                  color: Colors.orange[700],
                                                );
                                              },
                                        ),
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.local_hospital,
                                    size:
                                        EcliniqTextStyles.getResponsiveIconSize(
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
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsContent(hospital) {
    return FutureBuilder<String?>(
      future: SessionService.getAuthToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: EcliniqLoader());
        }

        final authToken = snapshot.data ?? '';

        if (authToken.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Authentication required',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff424242),
                      ),
                ),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                ),
                Text(
                  'Please log in to view doctors',
                  style: EcliniqTextStyles.responsiveBodySmall(
                    context,
                  ).copyWith(color: Color(0xff626060)),
                ),
              ],
            ),
          );
        }

        return HospitalDoctorsScreen(
          hospitalId: widget.hospitalId,
          hospitalName: hospital.name,
          authToken: authToken,
          hideAppBar: true,
        );
      },
    );
  }

  Widget _buildHeaderImage(hospital) {
    return FutureBuilder<String>(
      future: _getImageUrl(hospital.image),
      builder: (context, snapshot) {
        final imageUrl =
            snapshot.data ??
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
        final headerHeight = EcliniqTextStyles.getResponsiveHeight(
          context,
          210.0,
        );
        return Container(
          height: headerHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {},
            ),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              Positioned(
                top: EcliniqTextStyles.getResponsiveSize(context, 44.0),
                left: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
                right: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCircleButton(
                      EcliniqIcons.arrowLeft,
                      () => EcliniqRouter.pop(),
                    ),
                    Row(
                      children: [
                        _buildCircleButton(EcliniqIcons.share, () => {}),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildHospitalInfo(hospital) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: EcliniqTextStyles.getResponsiveSize(context, 40.0),
        left: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
        right: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            hospital.name,
            style: EcliniqTextStyles.responsiveHeadlineXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Color(0xff424242)),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hospital.type,
                style: EcliniqTextStyles.responsiveTitleXLarge(context)
                    .copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(width: 6),
              Container(width: 0.5, height: 20, color: Color(0xffD6D6D6)),
              const SizedBox(width: 6),
              Text(
                '${hospital.numberOfDoctors}+ Doctors',
                style: EcliniqTextStyles.responsiveTitleXLarge(context)
                    .copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Established in ${hospital.establishmentYear} (${DateTime.now().year - (int.tryParse(hospital.establishmentYear) ?? 0)} Years of Experience)',
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(color: Color(0xff424242), fontWeight: FontWeight.w400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.mapPointBlue.assetPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${hospital.city}, ${hospital.state}',
                  style: EcliniqTextStyles.responsiveTitleXLarge(context)
                      .copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff424242),
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xffF9F9F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 4),
                    Center(
                      child: Text(
                        '4KM ',
                        style: EcliniqTextStyles.responsiveTitleXLarge(context)
                            .copyWith(
                              color: Color(0xff424242),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                    SizedBox(width: 2),
                    SvgPicture.asset(
                      EcliniqIcons.mapArrow.assetPath,
                      width: 18,
                      height: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(hospital) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard(
              EcliniqIcons.usersGroupRounded,
              'Patients Served',
              hospital.numberOfDoctors > 0
                  ? '${hospital.numberOfDoctors * 1000}'
                  : 'N/A',
            ),
            DashedVerticalDivider(height: 110),
            _buildStatCard(
              EcliniqIcons.stethoscopeBlue,
              'Doctors',
              '${hospital.numberOfDoctors}',
            ),
            DashedVerticalDivider(height: 110),
            _buildStatCard(
              EcliniqIcons.bed,
              'Total Beds',
              '${hospital.noOfBeds}',
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
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff626060)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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

  Widget _buildFloatingTabSection() {
    return Padding(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
      child: Container(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          vertical: 8.0,
          horizontal: 12.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0x80000000),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 30.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabController.animateTo(0);
                },
                child: _buildTab('Details', _currentTabIndex == 0),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabController.animateTo(1);
                },
                child: _buildTab('Doctors', _currentTabIndex == 1),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabController.animateTo(2);
                },
                child: _buildTab('Surgeries', _currentTabIndex == 2),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabController.animateTo(3);
                },
                child: _buildTab('Branches', _currentTabIndex == 3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 2.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 23.0),
        ),
        border: Border.all(
          color: isActive ? Color(0xFF96BFFF) : Colors.transparent,
          width: EcliniqTextStyles.getResponsiveSize(context, 1.0),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
            color: isActive ? Color(0xff2372EC) : Colors.white,
            fontWeight: FontWeight.w400,
          ),
          // overflow: TextOverflow.ellipsis,
          maxLines: 1,
          //  textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x332372EC),
                  offset: Offset(7, 4),
                  blurRadius: 5.3,
                  spreadRadius: 0,
                ),
              ],
            ),
            height: EcliniqTextStyles.getResponsiveButtonHeight(
              context,
              baseHeight: 52.0,
            ),

            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2372EC),
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                  ),
                ),
              ),
              child: Text(
                'Book Appointment',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShimmerScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildShimmerHeaderImage(),
            const SizedBox(height: 16),
            _buildShimmerHospitalInfo(),
            const SizedBox(height: 16),
            _buildShimmerStatsCards(),
            const SizedBox(height: 16),
            _buildShimmerSection(),
            const SizedBox(height: 16),
            _buildShimmerSection(),
            const SizedBox(height: 16),
            _buildShimmerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerHeaderImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(height: 280, color: Colors.white),
    );
  }

  Widget _buildShimmerHospitalInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 32,
              width: 200,
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
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerStatsCards() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(right: index < 2 ? 40 : 0),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 24,
              width: 150,
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
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen({
    required String errorMessage,
    required VoidCallback onRetry,
  }) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Hospital Details',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: EcliniqTextStyles.responsiveBodySmall(
                  context,
                ).copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2372EC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return const Scaffold(
      body: Center(child: Text('No hospital details available')),
    );
  }
}

Widget _buildSurgeriesContent() {
  return SurgeryList();
}

Widget _buildBranchesContent() {
  return BranchesPage(hospitalId: '', hospitalName: ' ');
}
