import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

/// Main Application Entry Point
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HealthAlertReportScreen(),
    );
  }
}

/// Health Alert Report Screen
class HealthAlertReportScreen extends StatelessWidget {
  const HealthAlertReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 10),
            _buildConditionDetected(),
            const SizedBox(height: 10),
            _buildSeveritySection(),
            const SizedBox(height: 10),
            _buildSummary(),
            const SizedBox(height: 10),
            _buildECGInterpretation(),
            const SizedBox(height: 10),
            _buildRecommendation(),
          ],
        ),
      ),
    );
  }

  /// AppBar with Menu Actions
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: const Text(
        "Health Alert Report",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(value: "Download", child: Text("Download")),
              const PopupMenuItem(value: "Delete", child: Text("Delete")),
              const PopupMenuItem(value: "Share", child: Text("Share")),
            ];
          },
        ),
      ],
    );
  }

  /// Handles Menu Item Actions
  void _handleMenuAction(String action) {
    switch (action) {
      case "Download":
        _showToast("Downloading Report...");
        break;
      case "Delete":
        _showToast("Report Deleted");
        break;
      case "Share":
        _showToast("Sharing Report...");
        break;
    }
  }

  /// Displays a Toast Message
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color.fromARGB(255, 207, 212, 216), // Change this to any color you prefer
      textColor: Colors.white,      // Change text color if needed
      fontSize: 16.0,
    );
  }


  /// Patient Information Card
  Widget _buildHeaderCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("PATIENT ID", "#XX"),
          _infoRow("PATIENT NAME", "XYZ"),
          _infoRow("AGE", "##"),
          _infoRow("GENDER", "XXX"),
        ],
      ),
    );
  }

  /// Condition Detected Section
  Widget _buildConditionDetected() {
    return _buildCard(
      color: Colors.grey[400],
      child: const Center(
        child: Text(
          "(Condition) Detected",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  /// Severity Level Section
  Widget _buildSeveritySection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Date", "xx / xx / xx"),
          _infoRow("Time", "xx : xx : xx"),
          Row(
            children: const [
              Text("Severity level:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Text("Mild", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              SizedBox(width: 5),
              Text("/", style: TextStyle(color: Colors.black)),
              SizedBox(width: 5),
              Text("Moderate", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              SizedBox(width: 5),
              Text("/", style: TextStyle(color: Colors.black)),
              SizedBox(width: 5),
              Text("Severe", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  /// Summary Section
  Widget _buildSummary() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SUMMARY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Arrhythmia", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Normal", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("130 BPM", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  /// ECG Interpretation Section
  Widget _buildECGInterpretation() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ECG INTERPRETATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          _infoRow("Rate", ""),
          _infoRow("Rhythm", ""),
          _infoRow("Axis", ""),
          _infoRow("PR Interval", ""),
          _infoRow("QRS Complex", ""),
          _infoRow("QT Interval", ""),
        ],
      ),
    );
  }

  /// Recommendation Section
  Widget _buildRecommendation() {
    return _buildCard(
      color: Colors.red[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("RECOMMENDATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Divider(),
          Text("Consult your Doctor Immediately!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          SizedBox(height: 5),
          Text("Dear User, avoid any physical exertion and stay calm."),
        ],
      ),
    );
  }

  /// Reusable Information Row
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// Generic Card Widget
  Widget _buildCard({required Widget child, Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: color ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}