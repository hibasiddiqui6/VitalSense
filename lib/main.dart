import 'package:flutter/material.dart';
// import 'package:vitalsense/Modules/websocket.dart';
import 'package:vitalsense/widgets/splash_screen.dart';
// import 'package:firebase_core/firebase_core.dart'; // Add this
// import 'package:vitalsense/Modules/ecg.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized(); // Ensure binding
  // await Firebase.initializeApp(); // Initialize Firebase
  runApp(const VitalSenseApp());
}

class VitalSenseApp extends StatelessWidget {
  const VitalSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalSense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}
