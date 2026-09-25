import 'package:flutter/material.dart';

import 'routes/app_route_observer.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const SmartHealthcarePatientApp());
}

class SmartHealthcarePatientApp extends StatelessWidget {
  const SmartHealthcarePatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Healthcare Patient',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      navigatorObservers: [
        appRouteObserver,
      ],
      home: const LoginScreen(),
    );
  }
}