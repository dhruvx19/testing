import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/health_files.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/home_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login_trouble.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/terms_and_conditions.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => HealthFilesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: EcliniqRouter.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
            
    );
  }
}
