import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/widgets/easy_to_book.dart';
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
import 'package:ecliniq/widgets/horizontal_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

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

  String _getImageUrl(String? imageKey) {
    if (imageKey == null || imageKey.isEmpty) {
      return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
    }
    return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ChangeNotifierProvider.value(
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
            bottom: 120,
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
      onRefresh: () async => await _provider.fetchHospitalDetails(hospitalId: widget.hospitalId),
      child: SingleChildScrollView(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderImage(hospital),
              const SizedBox(height: 16),
              _buildHospitalInfo(hospital),
              const SizedBox(height: 16),
              _buildStatsCards(hospital),
              HorizontalDivider(),
              const SizedBox(height: 28),
              const AppointmentTimingWidget(),
              const SizedBox(height: 16),
              AddressWidget(hospital: hospital),
              const SizedBox(height: 16),
              AboutHospital(hospital: hospital),
              const SizedBox(height: 16),
              if (hospital.specialties.isNotEmpty)
                MedicalSpecialtiesWidget(specialties: hospital.specialties),
              if (hospital.specialties.isNotEmpty) const SizedBox(height: 16),
              if (hospital.hospitalServices.isNotEmpty)
                HospitalServicesWidget(services: hospital.hospitalServices),
              if (hospital.hospitalServices.isNotEmpty)
                const SizedBox(height: 16),
              if (hospital.accreditation.isNotEmpty)
                CertificatesWidget(accreditation: hospital.accreditation),
              if (hospital.accreditation.isNotEmpty) const SizedBox(height: 16),
              const SizedBox(height: 16),
              const ContactDetailsWidget(),
              const SizedBox(height: 16),
              const EasyWayToBookWidget(),
              const SizedBox(height: 100),
            ],
          ),
          Positioned(
            top: 230,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 3),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: hospital.logo.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _getImageUrl(hospital.logo),
                                width: 94,
                                height: 94,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.local_hospital,
                                    size: 60,
                                    color: Colors.orange[700],
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.local_hospital,
                              size: 60,
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
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text(
                  'Authentication required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff424242),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please log in to view doctors',
                  style: TextStyle(fontSize: 14, color: Color(0xff626060)),
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
    return Container(
      height: 280,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_getImageUrl(hospital.image)),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  EcliniqIcons.arrowLeft,
                  () => EcliniqRouter.pop(),
                ),
                Row(
                  children: [
                    _buildCircleButton(EcliniqIcons.heartUnfilled, () => {}),
                    const SizedBox(width: 8),
                    _buildCircleButton(EcliniqIcons.share, () => {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(EcliniqIcons icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(icon.assetPath, width: 32, height: 32),
        ),
      ),
    );
  }

  Widget _buildHospitalInfo(hospital) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 24),
      child: Column(
        children: [
          Text(
            hospital.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xff424242),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hospital.type,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 0.5, height: 20, color: Color(0xffD6D6D6)),
              const SizedBox(width: 6),
              Text(
                '${hospital.numberOfDoctors}+ Doctors',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Established in ${hospital.establishmentYear} (${DateTime.now().year - (int.tryParse(hospital.establishmentYear) ?? 0)} Years of Experience)',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xff424242),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.mapPointBlue.assetPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '${hospital.city}, ${hospital.state}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff424242),
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
                  children: [
                    SizedBox(width: 4),
                    Center(
                      child: Text(
                        '4KM ',
                        style: EcliniqTextStyles.bodySmall.copyWith(
                          color: Color(0xff424242),
                          fontSize: 16,
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
              const SizedBox(width: 8),
              Container(width: 0.5, height: 20, color: Color(0xffD6D6D6)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2372EC),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                EcliniqIcons.shuffle.assetPath,
                width: 16,
                height: 16,
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
            DashedVerticalDivider(height: 100),
            _buildStatCard(
              EcliniqIcons.stethoscopeBlue,
              'Doctors',
              '${hospital.numberOfDoctors}',
            ),
            DashedVerticalDivider(height: 100),
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
          SvgPicture.asset(icon.assetPath, width: 32, height: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xff626060),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xff2372EC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTabSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0x80000000),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
              },
              child: _buildTab('Details', _currentTabIndex == 0),
            ),
            GestureDetector(
              onTap: () {
                _tabController.animateTo(1);
              },
              child: _buildTab('Doctors', _currentTabIndex == 1),
            ),
            GestureDetector(
              onTap: () {
                _tabController.animateTo(2);
              },
              child: _buildTab('Surgeries', _currentTabIndex == 2),
            ),
            GestureDetector(
              onTap: () {
                _tabController.animateTo(3);
              },
              child: _buildTab('Branches', _currentTabIndex == 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(color: const Color(0xff96BFFF), width: 0.5)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? const Color(0xff2372EC) : Colors.white,
          fontWeight: isActive ? FontWeight.w400 : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2372EC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Hospital Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
  return BranchesPage(
    hospitalId: '', hospitalName: ' ',
    
  );
}
