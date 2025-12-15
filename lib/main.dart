import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/widgets/searched_specialities.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/notification_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/provider/eta_provider.dart';
import 'package:ecliniq/ecliniq_core/notifications/push_notification.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/search_specialities_page.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Warning: Firebase initialization failed: $e');
    print('Make sure GoogleService-Info.plist is added to ios/Runner/');
  }

  final futures = [
    AuthProvider().initialize(),
    SharedPreferences.getInstance(),
    EcliniqPushNotifications.init(),
  ];
  await Future.wait(futures);
  EcliniqPushNotifications.setNotificationListeners();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => HealthFilesProvider()),
        ChangeNotifierProvider(create: (_) => AddDependentProvider()),
        ChangeNotifierProvider(create: (_) => ETAProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    
    await Future.delayed(const Duration(seconds: 1));
    await EcliniqPushNotifications.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: EcliniqRouter.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SpecialityDoctorsList(),
    );
  }
}
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   Widget? _initialScreen;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     // Use microtask to allow first frame to render
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _determineInitialScreen();
//     });
//   }

//   Future<void> _determineInitialScreen() async {
//     try {
//       // Optimize: Run auth check in parallel with screen preparation
//       final initialRoute = await AuthFlowManager.getInitialRoute();

//       Widget? screen;
//       switch (initialRoute) {
//         case 'onboarding':
//           screen = const EcliniqWelcomeScreen();
//           break;
//         case 'login':
//           screen = const LoginPage();
//           break;
//         case 'home':
//           screen = const HomeScreen();
//           break;
//         default:
//           screen = const EcliniqWelcomeScreen();
//       }

//       // Small delay to ensure smooth transition
//       await Future.delayed(const Duration(milliseconds: 100));

//       if (mounted) {
//         setState(() {
//           _initialScreen = screen;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error determining initial screen: $e');
//       if (mounted) {
//         setState(() {
//           _initialScreen = const EcliniqWelcomeScreen();
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return MaterialApp(
//         debugShowCheckedModeBanner: false,
//         home: Scaffold(
//           backgroundColor: const Color(0xFF2372EC),
//           body: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset(
//                   EcliniqIcons.main.assetPath,
//                   width: 120,
//                   height: 120,
//                   cacheWidth: 240,
//                   cacheHeight: 240,
//                 ),
//                 const SizedBox(height: 32),
//                 const ShimmerFullScreenLoading(),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return MaterialApp(
//       navigatorKey: EcliniqRouter.navigatorKey,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         // Optimize performance
//         useMaterial3: true,
//       ),
//       debugShowCheckedModeBanner: false,
//       home: _initialScreen ?? const EcliniqWelcomeScreen(),
//     );
//   }
// }
