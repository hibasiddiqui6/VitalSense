import 'package:flutter/material.dart';
import 'package:vitalsense/Modules/ecg.dart';
import 'package:vitalsense/Modules/login_patient.dart';
import 'package:vitalsense/Modules/login_specialist.dart';
import 'package:vitalsense/Modules/patient_dashboard.dart';
import 'package:vitalsense/Modules/specialist_dashboard.dart';
import 'package:vitalsense/Modules/welcome_page.dart';

import 'package:vitalsense/widgets/splash_screen.dart';

import 'Modules/trends_type.dart';
// Import the welcome page

void main() {
  runApp(const VitalSenseApp());
}

class VitalSenseApp extends StatelessWidget {
  const VitalSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalSense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ECGScreen(),
    );
  }
}
