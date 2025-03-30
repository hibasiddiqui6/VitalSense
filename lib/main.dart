import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
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
      home: const WelcomePage(),
    );
  }
}
