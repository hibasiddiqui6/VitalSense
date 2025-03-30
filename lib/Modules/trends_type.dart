import 'package:flutter/material.dart';
import 'package:vitalsense/Modules/patient_dashboard.dart';
import 'package:vitalsense/Modules/respiration_trends.dart';
import 'package:vitalsense/Modules/temp_trends.dart';
import 'ecg_trends.dart';

void main() {
  runApp(const MyApp());
}

// Main Application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 118, 150, 108),
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const PatientTrends(),
    );
  }
}

// Patient Reports Screen
class PatientTrends extends StatelessWidget {
  const PatientTrends({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 118, 150, 108),
        elevation: 0,
        leading: const BackButtonWidget(),
        title: const SearchBarWidget(), // Add Search Bar // Add Back Button
      ),
      body: Column(
        children: [
          const CurvedHeader(),
          Expanded(child: ReportsScreen()),
        ],
      ),
    );
  }
}

// Custom App Bar with Back Button & Search Field
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 242, 244, 241),
        borderRadius: BorderRadius.circular(30),
      ),
      margin: const EdgeInsets.only(left:0.0),
      child: Container(
        width: screenWidth,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 242, 244, 241),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Search patient...",
                  hintStyle:
                      TextStyle(color: Color.fromARGB(179, 103, 103, 103)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Icon(Icons.search, color: Color.fromARGB(179, 103, 103, 103)),
          ],
        ),
      ),
    );
  }

  //@override
  //Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PatientDashboard()),
        );
      },
    );
  }
}

// Curved Header
class CurvedHeader extends StatelessWidget {
  const CurvedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 118, 150, 108),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: const Text(
        "TRENDS",
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

// Reports List
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  //const ReportsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                MaterialPageRoute(
                    builder: (context) => RespirationChartScreen()),
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
