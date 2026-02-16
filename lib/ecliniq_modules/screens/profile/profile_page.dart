import 'dart:convert';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/navigation_helper.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/privacy_policy.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/terms_and_conditions.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/about_upcharq/about_upcharq.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/add_dependent.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/edit_dependent.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/faq/faq.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/my_doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/personal_details/personal_detail.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/account_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/dependent.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/feedback_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/logout_bottom_sheet.dart';
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
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  bool _isDependentsLoading = false;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication required';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _patientService.getPatientDetails(
        authToken: authToken,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final user = response.data!.user;
        if (user?.firstName != null || user?.lastName != null) {
          final firstName = user?.firstName ?? '';
          final lastName = user?.lastName ?? '';
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            await SecureStorageService.storeUserName(fullName);
          }
        }

        // Load profile photo asynchronously without blocking UI
        final profilePhotoKey = user?.profilePhoto;
        if (profilePhotoKey is String && profilePhotoKey.isNotEmpty) {
          _resolveProfileImageUrl(profilePhotoKey, token: authToken).then((
            value,
          ) {
            if (mounted) setState(() {});
          });
        } else {
          _profilePhotoUrl = null;
        }

        if (mounted) {
          setState(() {
            _patientData = response.data;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load patient details: $e';
        });
      }
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

    if (authToken == null || !mounted) {
      return;
    }

    setState(() {
      _isDependentsLoading = true;
    });

    try {
      final response = await _patientService.getDependents(
        authToken: authToken,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _dependents = response.data;
          _isDependentsLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isDependentsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDependentsLoading = false;
        });
      }
    }
  }

  void _handleSettings() {}

  void _handleAddDependent() {
    EcliniqBottomSheet.show(
      context: context,
      child: AddDependentBottomSheet(
        onDependentAdded: () {
          // Will fetch after sheet closes
        },
      ),
      horizontalPadding: 12,
      bottomPadding: 16,
      borderRadius: 16,
    ).then((result) {
      // Only fetch once when sheet closes
      if (result == true && mounted) {
        _fetchDependents();
      }
    });
  }

  Future<void> _handleDependentTap(Dependent dependent) async {
    // Find the full dependent data
    final fullDependent = _dependents.firstWhere(
      (dep) => dep.id == dependent.id,
      orElse: () => throw Exception('Dependent not found'),
    );

    // Show edit dependent bottom sheet
    await EcliniqBottomSheet.show(
      context: context,
      child: EditDependentBottomSheet(
        dependentData: fullDependent,
        onDependentUpdated: () {
          // Fetch dependents immediately when updated
          if (mounted) {
            _fetchDependents();
          }
        },
        onDependentDeleted: () {
          // Fetch dependents immediately when deleted
          if (mounted) {
            _fetchDependents();
          }
        },
      ),
      horizontalPadding: 12,
      bottomPadding: 16,
      borderRadius: 16,
    );
  }

  void _onTabTapped(int index) {
    NavigationHelper.navigateToTab(context, index, 3);
  }

  void _handleAppUpdate() {}

  Future<void> _navigateToPersonalDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalDetails()),
    );

    // Refresh patient details when returning from personal details page
    if (mounted) {
      await _fetchPatientDetails();
    }
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

  void _navigateToAboutUpcharq() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutUpcharqPage()),
    );
  }

  void _navigateTofaq() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FaqPage()),
    );
  }

  Future<void> _launchEmailSupport() async {
    try {
      // Get device information
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceType = '';
      String osVersion = '';
      String platform = '';

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceType = iosInfo.model;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        platform = 'ios';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceType = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release}';
        platform = 'android';
      }

      // Get app version
      final appVersion = packageInfo.version;

      // Get user information
      final phoneNumber = _patientData?.user?.phone ?? '';
      final userName = _patientData?.fullName ?? '';

      // Get region/locale
      final locale = Platform.localeName;
      final regionParts = locale.split('_');
      final region = regionParts.length > 1
          ? '${regionParts[1]}, ${regionParts[0]}'
          : locale;

      // Construct email subject
      final subject = '[upcharq-$platform]: Issue in logging in upcharq app';

      // Construct email body
      final body =
          '''
Issue:

Phone Number: $phoneNumber

Name: $userName

App Version: $appVersion
Device Type: $deviceType
os Details: $osVersion
Region: $region


Sent from my ${Platform.isIOS ? 'iPhone' : 'Android device'}''';

      // Create mailto URL
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@upcharq.com',
        query: _encodeQueryParameters(<String, String>{
          'subject': subject,
          'body': body,
        }),
      );

      // Try launching directly without canLaunchUrl check
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email app. Please ensure you have an email app installed.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
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

    if (resp.success && resp.data != null && mounted) {
      // Only update if data actually changed
      if (_patientData != resp.data) {
        setState(() {
          _patientData = resp.data;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double topMargin = MediaQuery.of(context).size.height * 0.19;
    return EcliniqScaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                RepaintBoundary(
                  child: Container(
                    height: topMargin * 1.8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2372EC), Color(0xFFF3F5FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: (MediaQuery.of(context).size.height / 3),
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        EcliniqIcons.lottie.assetPath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: (MediaQuery.of(context).size.width * 2)
                            .toInt(),
                        cacheHeight:
                            ((MediaQuery.of(context).size.height / 3) * 2)
                                .toInt(),
                      ),
                    ),
                  ),
                ),

                RepaintBoundary(
                  child: ProfileHeader(onSettingsPressed: _handleSettings),
                ),

                Positioned(
                  top: topMargin,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RepaintBoundary(
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
                ),

                Positioned(
                  top: topMargin - 13,
                  left: MediaQuery.of(context).size.width / 2 - 43,
                  child: RepaintBoundary(
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
                      child: ClipOval(
                        child: Container(
                          width: 86,
                          height: 86,
                          color: const Color(0xFFDFE8FF),
                          child:
                              _profilePhotoUrl != null &&
                                  _profilePhotoUrl!.isNotEmpty
                              ? Image.network(
                                  _profilePhotoUrl!,
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.cover,
                                  cacheWidth: 172,
                                  cacheHeight: 172,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const _ProfileAvatarIcon();
                                  },
                                )
                              : const _ProfileAvatarIcon(),
                        ),
                      ),
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    if (oldClipper is! TopCircleCutClipper) return true;
    return oldClipper.radius != radius || oldClipper.topCut != topCut;
  }
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
    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
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

            ShimmerLoading(
              height: 200,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 30),

            ShimmerLoading(
              height: 100,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
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

  Widget _buildDependentsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: EcliniqTextStyles.getResponsiveSpacing(context, 5)),
          child: Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: EcliniqTextStyles.getResponsiveWidth(context, 120),
                height: EcliniqTextStyles.getResponsiveHeight(context, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 20)),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: EdgeInsets.only(right: EcliniqTextStyles.getResponsiveSpacing(context, 15)),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Column(
                      children: [
                        Container(
                          width: EcliniqTextStyles.getResponsiveSize(context, 52),
                          height: EcliniqTextStyles.getResponsiveSize(context, 52),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
                        Container(
                          width: EcliniqTextStyles.getResponsiveWidth(context, 50),
                          height: EcliniqTextStyles.getResponsiveHeight(context, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    final gender = patient.displayGender ?? 'N/A';
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
              Dependent(id: dep.id, name: dep.fullName, relation: dep.formattedRelation),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        children: [
          RepaintBoundary(
            key: ValueKey('user_info_$userName'),
            child: UserInfoSection(
              name: userName,
              phone: userPhone,
              email: userEmail,
              isPhoneVerified: isPhoneVerified,
            ),
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: ValueKey('basic_info_$age$gender$bloodGroup'),
            child: BasicInfoCards(
              age: age,
              gender: gender,
              bloodGroup: bloodGroup,
            ),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: ValueKey('physical_$healthStatus$bmi'),
            child: PhysicalHealthCard(
              status: healthStatus,
              bmi: bmi,
              height: height,
              weight: weight,
            ),
          ),
          const Divider(color: Color(0xffD6D6D6), thickness: 0.5, height: 40),
          RepaintBoundary(
            key: ValueKey('dependents_${dependents.length}'),
            child: _isDependentsLoading
                ? _buildDependentsShimmer()
                : DependentsSection(
                    dependents: dependents,
                    onAddDependent: _handleAddDependent,
                    onDependentTap: _handleDependentTap,
                  ),
          ),
          const Divider(color: Color(0xffD6D6D6), thickness: 0.5, height: 40),
          const SizedBox(height: 14),
          RepaintBoundary(
            child: AppUpdateBanner(
              currentVersion: currentVersion,
              newVersion: newVersion,
              onUpdate: _handleAppUpdate,
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            child: AccountSettingsMenu(
              onPersonalDetailsPressed: _navigateToPersonalDetails,
              onMyDoctorsPressed: _onMyDoctorsPressed,
              onSecuritySettingsPressed: _navigateToSecuritySettings,
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            key: ValueKey(
              'notifications_${patient.getWhatsAppNotifications}${patient.getPhoneNotifications}',
            ),
            child: NotificationsSettingsWidget(
              initialWhatsAppEnabled: patient.getWhatsAppNotifications,
              initialSmsEnabled: patient.getPhoneNotifications,
              initialInAppEnabled: patient.getInAppNotifications,
              initialEmailEnabled: patient.getEmailNotifications,
              initialPromotionalEnabled: patient.getPromotionalMessages,
              onSettingsChanged: _onNotificationSettingsChanged,
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            child: MoreSettingsMenuWidget(
              appVersion: 'v1.0.0',
              supportEmail: 'Support@eclinicq.com',
              onReferEarnPressed: () {},
              onHelpSupportPressed: _launchEmailSupport,
              onTermsPressed: () {
                EcliniqRouter.push(TermsAndConditionsPage());
              },
              onPrivacyPressed: () {
                EcliniqRouter.push(PrivacyPolicyPage());
              },
              onFaqPressed: () {
                _navigateTofaq();
              },
              onAboutPressed: _navigateToAboutUpcharq,
              onFeedbackPressed: () {
                EcliniqBottomSheet.show(
                  context: context,
                  child: FeedbackBottomSheet(),
                );
              },
              onLogoutPressed: () async {
                final result = await EcliniqBottomSheet.show(
                  context: context,
                  child: const LogoutBottomSheet(),
                );

                if (result == true && mounted) {
                  // User confirmed logout
                  try {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final authToken = authProvider.authToken;

                    // Call logout API
                    final authService = AuthService();
                    final logoutResponse = await authService.logout(
                      authToken: authToken,
                    );

                    // Clear local data regardless of API response
                    await authProvider.logout();

                    // Navigate to login page
                    if (mounted) {
                      EcliniqRouter.pushAndRemoveUntil(
                        const LoginPage(),
                        (route) => false,
                      );

                      // Show success message after navigation completes
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          CustomSuccessSnackBar.show(
                            context: context,
                            title: 'Logged Out',
                            subtitle:
                                logoutResponse['message'] ??
                                'Logged out successfully',
                            duration: const Duration(seconds: 3),
                          );
                        }
                      });
                    }
                  } catch (e) {
                    // Even if API fails, clear local data and logout
                    if (mounted) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();
                      EcliniqRouter.pushAndRemoveUntil(
                        const LoginPage(),
                        (route) => false,
                      );
                    }
                  }
                }
              },
            ),
          ),
          RepaintBoundary(
            child: Image.asset(
              EcliniqIcons.profileLogo.assetPath,
              width: 128,
              height: 30,
              cacheWidth: 256,
              cacheHeight: 60,
            ),
          ),
          const SizedBox(height: 4),
          RepaintBoundary(
            child: Text(
              'v1.0.0',
              style: EcliniqTextStyles.responsiveBodySmallProminent(
                context,
              ).copyWith(color: Color(0xffB8B8B8), fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
