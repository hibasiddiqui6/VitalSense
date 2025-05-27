import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vitalsense/widgets/splash_screen.dart';
import 'package:vitalsense/Modules/patient_dashboard.dart';
import 'package:vitalsense/Modules/specialist_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final homeScreen = await initApp();
  runApp(VitalSenseApp(home: homeScreen));
}

  Future<Widget> initApp() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final role = prefs.getString('role'); // e.g., 'patient' or 'specialist'

  if (isLoggedIn) {
    if (role == 'patient') {
      return PatientDashboard(); 
    } else if (role == 'specialist') {
      return SpecialistDashboard(); 
    }
  }

  return SplashScreen(); // Default if not logged in
}

class VitalSenseApp extends StatelessWidget {
  final Widget home;
  const VitalSenseApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalSense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: home,
    );
  }
}
