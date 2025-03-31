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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: role == 'specialist'
            ? SpecialistDrawer(fullName: fullName, email: email)
            : PatientDrawer(fullName: fullName, email: email),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu icon
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black54, size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),

            // Page Title
            Center(
              child: Text(
                'Trends and History',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Expanded(child: Trends()),
          ],
        ),
      ),
    );
  }
}

class Trends extends StatelessWidget {
  const Trends({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
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
            child: const Text("ECG Trends / History"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RespirationChartScreen()),
              );
            },
            child: const Text("Respiration Trends / History"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TempChartScreen()),
              );
            },
            child: const Text("Temperature Trends / History"),
          ),
        ],
      ),
    );
  }
}
