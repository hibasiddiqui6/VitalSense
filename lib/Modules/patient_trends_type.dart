import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/Modules/ecg_trends.dart';
import 'package:vitalsense/Modules/respiration_trends.dart';
import 'package:vitalsense/Modules/temp_trends.dart';
import '../widgets/patient_drawer.dart';
import '../widgets/specialist_drawer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF9F4),
      ),
      home: const PatientTrends(),
    );
  }
}

class PatientTrends extends StatefulWidget {
  const PatientTrends({super.key});

  @override
  State<PatientTrends> createState() => _PatientTrendsState();
}

class _PatientTrendsState extends State<PatientTrends> {
  String role = "-";
  String fullName = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
      role = prefs.getString("role") ?? "-";
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: PatientDrawer(
          fullName: fullName, // fetched and stored in State
          email: email, // fetched and stored in State
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Center(
              child: Text(
                'Trends and History',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.032),

            const Expanded(child: TrendsScreen()),
          ],
        ),
      ),
    );
  }
}

//Trends

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  //const ReportsList({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.032),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ECGChartScreen()),
              );
            },
            style: CustomButtonStyle.elevatedButtonStyle(
                context), // Call the custom style
            child: const Text("ECG Trends / History"),
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RespirationChartScreen()),
              );
            },
            style: CustomButtonStyle.elevatedButtonStyle(
                context), // Call the custom style
            child: const Text("Respiration Trends / History"),
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TempChartScreen()),
              );
            },
            style: CustomButtonStyle.elevatedButtonStyle(
                context), // Call the custom style
            child: const Text("Temperature Trends / History"),
          ),
        ],
      ),
    );
  }
}

class CustomButtonStyle {
  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 90, 145, 85), // Button color
      foregroundColor: Colors.white, // Text color
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.024), // Padding
      textStyle: TextStyle(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.bold), // Font styling
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(screenWidth * 0.024), // Rounded corners
      ),
      elevation: 4, // Shadow effect
    );
  }
}
