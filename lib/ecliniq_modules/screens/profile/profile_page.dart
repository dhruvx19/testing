import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/account_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/dependent.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/more_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/notification_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/physical_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/user_info.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSettings() {}

  void _handleAddDependent() {}

  void _handleDependentTap(Dependent dependent) {}

  void _handleAppUpdate() {}

  void _navigateToPersonalDetails() {}

  void _navigateToCreateAbha() {}

  void _navigateToMedicalRecords() {}

  void _navigateToSecuritySettings() {}

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userName = "Ketan Patni";
        final userPhone = "+91 91753 67487";
        final userEmail = "ketanpatni@gmail.com";
        final isPhoneVerified = true;
        final age = "29y 3m";
        final gender = "Male";
        final bloodGroup = "B+";
        final healthStatus = "Healthy";
        final bmi = 22.5;
        final height = "180.3 cm";
        final weight = "69 kg";
        final currentVersion = "v1.0.0";
        final newVersion = "v1.0.1";

        final dependents = [
          Dependent(id: "1", name: "Father's Name", relation: "Father"),
        ];

        return EcliniqScaffold(
          body: Stack(
            children: [

              Container(
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2372EC), Color(0xFFDFE8FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),


              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
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

              Column(
                children: [
                  // Header
                  ProfileHeader(
                    onSettingsPressed: _handleSettings,
                  ),


                  Expanded(
                    child: ClipPath(
                      clipper: _CircleCutoutClipper(
                        cutoutRadius: 52,
                        cutoutCenter: Offset(
                          MediaQuery.of(context).size.width / 2,
                          3,
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.only(
                          top: 60,),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              UserInfoSection(
                                name: userName,
                                phone: userPhone,
                                email: userEmail,
                                isPhoneVerified: isPhoneVerified,
                              ),

                              const SizedBox(height: 30),

                              BasicInfoCards(
                                age: age,
                                gender: gender,
                                bloodGroup: bloodGroup,
                              ),

                              const SizedBox(height: 30),

                              PhysicalHealthCard(
                                status: healthStatus,
                                bmi: bmi,
                                height: height,
                                weight: weight,
                              ),

                              const SizedBox(height: 30),

                              DependentsSection(
                                dependents: dependents,
                                onAddDependent: _handleAddDependent,
                                onDependentTap: _handleDependentTap,
                              ),

                              const SizedBox(height: 30),

                              AppUpdateBanner(
                                currentVersion: currentVersion,
                                newVersion: newVersion,
                                onUpdate: _handleAppUpdate,
                              ),

                              const SizedBox(height: 20),

                              AccountSettingsMenu(
                                onPersonalDetailsPressed:
                                _navigateToPersonalDetails,
                                onCreateAbhaPressed: _navigateToCreateAbha,
                                onMedicalRecordsPressed:
                                _navigateToMedicalRecords,
                                onSecuritySettingsPressed:
                                _navigateToSecuritySettings,
                              ),

                              const SizedBox(height: 20),

                              NotificationsSettingsWidget(
                                onSettingsChanged: (settings) {},
                              ),

                              const SizedBox(height: 20),

                              MoreSettingsMenuWidget(
                                appVersion: 'v1.0.0',
                                supportEmail: 'Support@eclinicq.com',
                                onReferEarnPressed: () {},
                                onHelpSupportPressed: () {},
                                onTermsPressed: () {},
                                onPrivacyPressed: () {},
                                onFaqPressed: () {},
                                onAboutPressed: () {},
                                onLogoutPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text(
                                        'Are you sure you want to logout?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                onDeleteAccountPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Account'),
                                      content: const Text(
                                        'Are you sure you want to delete your account? This action cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),


              Positioned(
                top: 150,
                left: (MediaQuery.of(context).size.width / 2) - 45,
                child: Container(
                  height: 90,
                  width: 90,
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
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange[100],
                    child: Image.asset('lib/ecliniq_icons/assets/specs/Group.svg', fit: BoxFit.cover,),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _CircleCutoutClipper extends CustomClipper<Path> {
  final double cutoutRadius;
  final Offset cutoutCenter;

  _CircleCutoutClipper({
    required this.cutoutRadius,
    required this.cutoutCenter,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));


    final circlePath = Path()
      ..addOval(Rect.fromCircle(
        center: cutoutCenter,
        radius: cutoutRadius,
      ));


    return Path.combine(PathOperation.difference, path, circlePath);
  }

  @override
  bool shouldReclip(_CircleCutoutClipper oldClipper) {
    return oldClipper.cutoutRadius != cutoutRadius ||
        oldClipper.cutoutCenter != cutoutCenter;
  }
}