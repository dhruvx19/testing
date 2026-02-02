import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/navigation_helper.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/terms_and_conditions.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/add_dependent.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/my_doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/personal_details/personal_detail.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/account_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/dependent.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/feedback_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/more_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/notification_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/physical_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/user_info.dart'
    hide BasicInfoCards, ProfileHeader;
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_navigation/bottom_navigation.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_core/notifications/test_notification_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;
  final PatientService _patientService = PatientService();

  PatientDetailsData? _patientData;
  List<DependentData> _dependents = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchPatientDetails();
    _fetchDependents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _patientService.getPatientDetails(
        authToken: authToken,
      );

      if (response.success && response.data != null) {
        _profilePhotoUrl = null;

        final user = response.data!.user;
        if (user?.firstName != null || user?.lastName != null) {
          final firstName = user?.firstName ?? '';
          final lastName = user?.lastName ?? '';
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            await SecureStorageService.storeUserName(fullName);
          }
        }

        setState(() {
          _patientData = response.data;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load patient details: $e';
      });
    }
  }

  Future<void> _resolveProfileImageUrl(
    String key, {
    required String token,
  }) async {
    try {
      final publicUri = Uri.parse(
        '${Endpoints.storagePublicUrl}?key=${Uri.encodeComponent(key)}',
      );
      final resp = await http.get(
        publicUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['data']?['publicUrl'];
        if (url is String && url.isNotEmpty) {
          _profilePhotoUrl = url;
          return;
        }
      }
    } catch (_) {}

    try {
      final downloadUri = Uri.parse(
        '${Endpoints.storageDownloadUrl}?key=${Uri.encodeComponent(key)}',
      );
      final resp = await http.get(
        downloadUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['data']?['downloadUrl'];
        if (url is String && url.isNotEmpty) {
          _profilePhotoUrl = url;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchDependents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      return;
    }

    setState(() {});

    try {
      final response = await _patientService.getDependents(
        authToken: authToken,
      );

      if (response.success) {
        setState(() {
          _dependents = response.data;
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      setState(() {});
    }
  }

  void _handleSettings() {}

  void _handleAddDependent() {
    EcliniqBottomSheet.show(
      context: context,
      child: AddDependentBottomSheet(
        onDependentAdded: () {
          _fetchDependents();
        },
      ),
      horizontalPadding: 12,
      bottomPadding: 16,
      borderRadius: 16,
    ).then((result) {
      if (result == true) {
        _fetchDependents();
      }
    });
  }

  void _handleDependentTap(Dependent dependent) {}

  void _onTabTapped(int index) {
    NavigationHelper.navigateToTab(context, index, 3);
  }

  void _handleAppUpdate() {}

  void _navigateToPersonalDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalDetails()),
    );
  }

  void _onMyDoctorsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyDoctors()),
    );
  }

  void _navigateToSecuritySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SecuritySettingsOptions(patientData: _patientData),
      ),
    );
  }

  Future<void> _onNotificationSettingsChanged(
    NotificationSettings settings,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;
    if (authToken == null) return;

    final prefs = {
      'getPhoneNotifications': settings.sms,
      'getWhatsAppNotifications': settings.whatsApp,
      'getEmailNotifications': settings.email,
      'getInAppNotifications': settings.inApp,
      'getPromotionalMessages': settings.promotional,
    };

    final resp = await _patientService.updateNotificationPreferences(
      authToken: authToken,
      prefs: prefs,
    );

    if (resp.success && resp.data != null) {
      setState(() {
        _patientData = resp.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        double topMargin = MediaQuery.of(context).size.height * 0.19;
        return EcliniqScaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: topMargin * 1.8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2372EC), Color(0xFFF3F5FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: (MediaQuery.of(context).size.height / 3),
                      child: Opacity(
                        opacity: 0.3,
                        child: Image.asset(
                          EcliniqIcons.lottie.assetPath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    ProfileHeader(onSettingsPressed: _handleSettings),

                    Positioned(
                      top: topMargin,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipPath(
                        clipper: TopCircleCutClipper(radius: 50, topCut: 30),
                        child: Container(
                          padding: const EdgeInsets.only(top: 90),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? _buildShimmerLoading()
                              : _errorMessage != null
                              ? _buildErrorWidget()
                              : _buildProfileContent(),
                        ),
                      ),
                    ),

                    Positioned(
                      top: topMargin - 13,
                      left: MediaQuery.of(context).size.width / 2 - 43,
                      child: Container(
                        height: 86,
                        width: 86,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFDFE8FF),
                          child: _ProfileAvatarIcon(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              EcliniqBottomNavigationBar(currentIndex: 3, onTap: _onTabTapped),
            ],
          ),
        );
      },
    );
  }
}

class TopCircleCutClipper extends CustomClipper<Path> {
  final double radius;
  final double topCut;

  TopCircleCutClipper({required this.radius, required this.topCut});

  @override
  Path getClip(Size size) {
    final rectPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, topCut, size.width, size.height - topCut),
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
        ),
      );

    final circlePath = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(size.width / 2, topCut), radius: radius),
      );

    final finalPath = Path.combine(
      PathOperation.difference,
      rectPath,
      circlePath,
    );

    return finalPath;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class _ProfileAvatarIcon extends StatelessWidget {
  const _ProfileAvatarIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'lib/ecliniq_icons/assets/Group.svg',
      width: 80,
      fit: BoxFit.contain,
    );
  }
}

extension _ProfilePageContent on _ProfilePageState {
  String _uiBloodGroup(String? backendValue) {
    if (backendValue == null) return 'N/A';
    const map = {
      'A_POSITIVE': 'A+',
      'A_NEGATIVE': 'A-',
      'B_POSITIVE': 'B+',
      'B_NEGATIVE': 'B-',
      'AB_POSITIVE': 'AB+',
      'AB_NEGATIVE': 'AB-',
      'O_POSITIVE': 'O+',
      'O_NEGATIVE': 'O-',
      'OTHERS': 'Others',
    };
    return map[backendValue] ?? backendValue;
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Column(
            children: [
              ShimmerLoading(
                width: 150,
                height: 24,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              ShimmerLoading(
                width: 120,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              ShimmerLoading(
                width: 180,
                height: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    ShimmerLoading(
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 40,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    ShimmerLoading(
                      width: 50,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    ShimmerLoading(
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 50,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    ShimmerLoading(
                      width: 40,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey[300]),
              Expanded(
                child: Column(
                  children: [
                    ShimmerLoading(
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    ShimmerLoading(
                      width: 30,
                      height: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          ShimmerLoading(height: 200, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 30),

          ShimmerLoading(height: 100, borderRadius: BorderRadius.circular(16)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load patient details',
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPatientDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_patientData == null) {
      return _buildErrorWidget();
    }

    final patient = _patientData!;
    final userName = patient.fullName.isNotEmpty ? patient.fullName : 'User';
    final userPhone = patient.displayPhone;
    final userEmail = patient.displayEmail;
    final isPhoneVerified = patient.user?.phone != null;
    final age = patient.age ?? 'N/A';
    final gender = 'Male';
    final bloodGroup = _uiBloodGroup(patient.bloodGroup);
    final healthStatus = patient.healthStatus;
    final bmi = patient.bmi ?? 0.0;
    final height = patient.displayHeight;
    final weight = patient.displayWeight;
    final currentVersion = "v1.0.0";
    final newVersion = "v1.0.1";
    final dependents = _dependents
        .map(
          (dep) =>
              Dependent(id: dep.id, name: dep.fullName, relation: dep.relation),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          UserInfoSection(
            name: userName,
            phone: userPhone,
            email: userEmail,
            isPhoneVerified: isPhoneVerified,
          ),
          const SizedBox(height: 12),
          BasicInfoCards(age: age, gender: gender, bloodGroup: bloodGroup),
          const SizedBox(height: 16),
          PhysicalHealthCard(
            status: healthStatus,
            bmi: bmi,
            height: height,
            weight: weight,
          ),
          Divider(color: Color(0xffD6D6D6), thickness: 0.5, height: 40),
          DependentsSection(
            dependents: dependents,
            onAddDependent: _handleAddDependent,
            onDependentTap: _handleDependentTap,
          ),
          Divider(color: Color(0xffD6D6D6), thickness: 0.5, height: 40),
          const SizedBox(height: 14),
          AppUpdateBanner(
            currentVersion: currentVersion,
            newVersion: newVersion,
            onUpdate: _handleAppUpdate,
          ),
          const SizedBox(height: 24),
          AccountSettingsMenu(
            onPersonalDetailsPressed: _navigateToPersonalDetails,
            onMyDoctorsPressed: _onMyDoctorsPressed,
            onSecuritySettingsPressed: _navigateToSecuritySettings,
          ),
          const SizedBox(height: 24),
          NotificationsSettingsWidget(
            initialWhatsAppEnabled: patient.getWhatsAppNotifications,
            initialSmsEnabled: patient.getPhoneNotifications,
            initialInAppEnabled: patient.getInAppNotifications,
            initialEmailEnabled: patient.getEmailNotifications,
            initialPromotionalEnabled: patient.getPromotionalMessages,
            onSettingsChanged: _onNotificationSettingsChanged,
          ),
          const SizedBox(height: 24),
          MoreSettingsMenuWidget(
            appVersion: 'v1.0.0',
            supportEmail: 'Support@eclinicq.com',
            onReferEarnPressed: () {},
            onHelpSupportPressed: () {},
            onTermsPressed: () {
              EcliniqRouter.push(TermsAndConditionsPage());
            },
            onPrivacyPressed: () {},
            onFaqPressed: () {},
            onAboutPressed: () {},
            onFeedbackPressed: () {
              EcliniqBottomSheet.show(
                context: context,
                child: FeedbackBottomSheet(),
              );
            },
            onLogoutPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
