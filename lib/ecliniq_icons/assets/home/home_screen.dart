import 'package:ecliniq/ecliniq_core/router/navigation_helper.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/top_doctor/top_doctors.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/easy_to_book.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/not_feeling_well.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/quick_actions.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/searched_specialities.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/location_search.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_hospitals.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/notification_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/provider/notification_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_navigation/bottom_navigation.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final int _currentIndex = 0;
  bool _hasShownLocationSheet = false;
  bool _hasInitializedDoctors = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLocationSheet();
      _initializeDoctors();
      Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
    });
  }

  void _checkAndShowLocationSheet() {
    if (!_hasShownLocationSheet && mounted) {
      _hasShownLocationSheet = true;
      final hospitalProvider = Provider.of<HospitalProvider>(
        context,
        listen: false,
      );

      if (!hospitalProvider.hasLocation) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showLocationBottomSheet(context);
          }
        });
      }
    }
  }

  void _initializeDoctors() {
    if (!_hasInitializedDoctors && mounted) {
      _hasInitializedDoctors = true;
      final doctorProvider = Provider.of<DoctorProvider>(
        context,
        listen: false,
      );

      // Check if doctors need to be fetched
      if (!doctorProvider.hasDoctors && !doctorProvider.isLoading) {
        // Use default coordinates or get from hospital provider
        final hospitalProvider = Provider.of<HospitalProvider>(
          context,
          listen: false,
        );

        final latitude = hospitalProvider.currentLatitude ?? 28.6139;
        final longitude = hospitalProvider.currentLongitude ?? 77.209;

        doctorProvider.fetchTopDoctors(
          latitude: latitude,
          longitude: longitude,
          isRefresh: true,
        );
      }
    }
  }

  void _showLocationBottomSheet(BuildContext context) {
    EcliniqBottomSheet.show(
      context: context,
      child: const LocationBottomSheet(currentLocation: ''),
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      return;
    }
    NavigationHelper.navigateToTab(context, index, _currentIndex);
  }

  Future<void> _onRefresh() async {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    await doctorProvider.refreshDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return EcliniqScaffold(
          backgroundColor: EcliniqScaffold.primaryBlue,
          body: SizedBox.expand(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildAppBar(),
                LocationSelectorWidget(
                  currentLocation: 'Vishnu Dev Nagar, Wakad',
                ),
                SearchBarWidget(
                  hintText: 'Search Doctors',
                  onSearch: (query) {},
                  onClear: () {},
                  onVoiceSearch: () {},
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            
                            onRefresh: _onRefresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24),
                                  QuickActionsWidget(),
                                const SizedBox(height: 24),
                                  _buildTopDoctorsSection(),
                                  const SizedBox(height: 48),
                                  MostSearchedSpecialities(),
                                  const SizedBox(height: 30),
                                  NotFeelingWell(),
                                  const SizedBox(height: 10),
                                  TopHospitalsWidget(),
                                  const SizedBox(height: 30),
                                  EasyWayToBookWidget(),
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ),
                          ),
                        ),
                        EcliniqBottomNavigationBar(
                          currentIndex: _currentIndex,
                          onTap: _onTabTapped,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          SvgPicture.asset(
            EcliniqIcons.nameLogo.assetPath,
            height: 28,
            width: 140,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await EcliniqRouter.push(NotificationScreen());
              if (mounted) {
                Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCount();
              }
            },
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Badge(
                  label: Text(
                    '${provider.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  isLabelVisible: provider.unreadCount > 0,
                  backgroundColor: Colors.red,
                  child: SvgPicture.asset(
                    EcliniqIcons.notificationBell.assetPath,
                    height: 32,
                    width: 32,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDoctorsSection() {
    return Consumer<DoctorProvider>(
      builder: (context, doctorProvider, child) {
        // Show error state if there's an error
        if (doctorProvider.errorMessage != null &&
            !doctorProvider.isLoading &&
            !doctorProvider.hasDoctors) {
          return _buildErrorState(doctorProvider);
        }

        // Show doctors or shimmer
        return TopDoctorsWidget(
          doctors: doctorProvider.doctors,
          showShimmer: doctorProvider.isLoading,
        );
      },
    );
  }

  Widget _buildErrorState(DoctorProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load doctors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.errorMessage ?? 'Unknown error occurred',
            style: TextStyle(fontSize: 14, color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.retry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
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
}
