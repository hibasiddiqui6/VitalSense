import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
import 'package:vitalsense/Modules/patient_dashboard.dart';
import 'package:vitalsense/Modules/patient_profile.dart';
import 'package:vitalsense/Modules/respiration.dart';
import 'package:vitalsense/Modules/specialist_dashboard.dart';
import 'package:vitalsense/Modules/specialist_patient_trends.dart';
import 'package:vitalsense/Modules/specialist_profile.dart';
import 'package:vitalsense/Modules/temp_trends.dart';
import 'package:vitalsense/Modules/temperature.dart';
import 'package:vitalsense/Modules/patient_trends_type.dart';
import 'package:vitalsense/Modules/trusted_contacts.dart';
import 'package:vitalsense/widgets/splash_screen.dart';
import 'Modules/welcome_page.dart'; // Import the welcome page

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const VitalSenseApp());
}

class VitalSenseApp extends StatelessWidget {
  const VitalSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalSense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}
