import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/splash_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/provider/eta_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/provider/notification_provider.dart';
import 'package:ecliniq/ecliniq_core/notifications/push_notification.dart';
import 'package:ecliniq/ecliniq_core/notifications/appointment_lock_screen_notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final authProvider = AuthProvider();

  final futures = [
    authProvider.initialize(),
    SharedPreferences.getInstance(),
    EcliniqPushNotifications.init(),
    AppointmentLockScreenNotification.init(),
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
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => HealthFilesProvider()),
        ChangeNotifierProvider(create: (_) => AddDependentProvider()),
        ChangeNotifierProvider(create: (_) => ETAProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: EcliniqRouter.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
