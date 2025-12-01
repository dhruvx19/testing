// import 'package:ecliniq/ecliniq_core/notifications/push_notification.dart';
// import 'package:ecliniq/ecliniq_core/router/route.dart';
// import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
// import 'package:ecliniq/ecliniq_modules/screens/doctor_details/doctor_branches.dart';
// import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
// import 'package:ecliniq/ecliniq_modules/screens/home/provider/doctor_provider.dart';
// import 'package:ecliniq/ecliniq_modules/screens/home/provider/hospital_provider.dart';
// import 'package:ecliniq/ecliniq_modules/screens/my_visits/provider/eta_provider.dart';
// import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase with error handling
//   try {
//     await Firebase.initializeApp();
//   } catch (e) {
//     print('Warning: Firebase initialization failed: $e');
//     print('Make sure GoogleService-Info.plist is added to ios/Runner/');
//   }

//   final futures = [
//     AuthProvider().initialize(),
//     SharedPreferences.getInstance(),
//     EcliniqPushNotifications.init(),
//   ];
//   await Future.wait(futures);
//   EcliniqPushNotifications.setNotificationListeners();

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => HospitalProvider()),
//         ChangeNotifierProvider(create: (_) => DoctorProvider()),
//         ChangeNotifierProvider(create: (_) => HealthFilesProvider()),
//         ChangeNotifierProvider(create: (_) => AddDependentProvider()),
//         ChangeNotifierProvider(create: (_) => ETAProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     _requestNotificationPermission();
//   }

//   Future<void> _requestNotificationPermission() async {
//     await Future.delayed(const Duration(seconds: 1));
//     await EcliniqPushNotifications.requestPermission();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: EcliniqRouter.navigatorKey,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       debugShowCheckedModeBanner: false,
//       home: const Branches(),
//     );
//   }
// }
// // class MyApp extends StatefulWidget {
// //   const MyApp({super.key});

// //   @override
// //   State<MyApp> createState() => _MyAppState();
// // }

// // class _MyAppState extends State<MyApp> {
// //   Widget? _initialScreen;
// //   bool _isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     // Use microtask to allow first frame to render
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       _determineInitialScreen();
// //     });
// //   }

// //   Future<void> _determineInitialScreen() async {
// //     try {
// //       // Optimize: Run auth check in parallel with screen preparation
// //       final initialRoute = await AuthFlowManager.getInitialRoute();

// //       Widget? screen;
// //       switch (initialRoute) {
// //         case 'onboarding':
// //           screen = const EcliniqWelcomeScreen();
// //           break;
// //         case 'login':
// //           screen = const LoginPage();
// //           break;
// //         case 'home':
// //           screen = const HomeScreen();
// //           break;
// //         default:
// //           screen = const EcliniqWelcomeScreen();
// //       }

// //       // Small delay to ensure smooth transition
// //       await Future.delayed(const Duration(milliseconds: 100));

// //       if (mounted) {
// //         setState(() {
// //           _initialScreen = screen;
// //           _isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       print('Error determining initial screen: $e');
// //       if (mounted) {
// //         setState(() {
// //           _initialScreen = const EcliniqWelcomeScreen();
// //           _isLoading = false;
// //         });
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isLoading) {
// //       return MaterialApp(
// //         debugShowCheckedModeBanner: false,
// //         home: Scaffold(
// //           backgroundColor: const Color(0xFF2372EC),
// //           body: Center(
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Image.asset(
// //                   EcliniqIcons.main.assetPath,
// //                   width: 120,
// //                   height: 120,
// //                   cacheWidth: 240,
// //                   cacheHeight: 240,
// //                 ),
// //                 const SizedBox(height: 32),
// //                 const ShimmerFullScreenLoading(),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     return MaterialApp(
// //       navigatorKey: EcliniqRouter.navigatorKey,
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //         // Optimize performance
// //         useMaterial3: true,
// //       ),
// //       debugShowCheckedModeBanner: false,
// //       home: _initialScreen ?? const EcliniqWelcomeScreen(),
// //     );
// //   }
// // }

import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/onboarding_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/provider/eta_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecliniq/ecliniq_services/phonepe_service.dart';
// Import your firebase_options.dart if you have one
// import 'firebase_options.dart';

void main() async {
  // IMPORTANT: Must be called first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST
  await _initializeFirebase();

  // Initialize PhonePe SDK (non-blocking)
  _initializePhonePe();

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => HealthFilesProvider()),
        ChangeNotifierProvider(create: (_) => AddDependentProvider()),
        ChangeNotifierProvider(create: (_) => ETAProvider()),
      ],
      child: const MyApp(),
    ),);
}

/// Initialize Firebase
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      // Uncomment if you have firebase_options.dart generated by FlutterFire CLI
      // options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    // App can continue without Firebase, but push notifications won't work
  }
}

/// Initialize PhonePe SDK
Future<void> _initializePhonePe() async {
  try {
    final phonePe = PhonePeService();
    final prefs = await SharedPreferences.getInstance();
    
    // Get user ID or generate a unique flow ID
    String visitorId = prefs.getString('user_id') ?? '';
    if (visitorId.isEmpty) {
      // Generate a unique ID for anonymous users
      visitorId = 'visitor_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('visitor_id', visitorId);
    }

    // TODO: Replace with your actual merchant ID
    const String merchantId = 'M237OHQ3YCVAO_2511191950';
    const bool isProduction = false; // Set to true for production

    final initialized = await phonePe.initialize(
      isProduction: isProduction,
      merchantId: merchantId,
      flowId: visitorId, // THIS CANNOT BE EMPTY!
      enableLogs: !isProduction,
    );

    if (initialized) {
      debugPrint('✅ PhonePe SDK initialized successfully');
    } else {
      debugPrint('⚠️ PhonePe SDK initialization returned false');
    }
  } catch (e) {
    debugPrint('❌ PhonePe SDK initialization failed: $e');
    // App can continue, but payments won't work
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: EcliniqRouter.navigatorKey, // ✅ CRITICAL: Required for router navigation
      title: 'eCliniq',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const EcliniqWelcomeScreen(), // Replace with your home screen
    );
  }
}

// Placeholder - replace with your actual home screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('eCliniq')),
    );
  }
}