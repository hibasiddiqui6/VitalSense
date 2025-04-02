import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ecg.dart';
import 'respiration.dart';
import 'temperature.dart';
import 'package:intl/intl.dart';

class PatientInsightsScreen extends StatefulWidget {
  final String patientId;

  const PatientInsightsScreen({super.key, required this.patientId});

  @override
  State<PatientInsightsScreen> createState() => _PatientInsightsScreenState();
}

class _PatientInsightsScreenState extends State<PatientInsightsScreen> {
  String sFullName = "...";
  String pFullName = "...";
  String email = "...";
  String respiration = "-";
  String temperature = "-";
  String gender = "-";
  String age = "-";
  String weight = "-";
  String lastUpdated = "-";
  bool isOnline = false;
  Timer? disconnectionTimer;
  Timer? dataFetchTimer;
  List<Offset> points = [];

  double x = 0;
  Timer? timer;
  int time = 0;
  @override
  void initState() {
    super.initState();
    startECGStreaming();
    fetchPatientInsights();
    fetchUserProfile();
    _loadUserDetails();
  }

  void startECGStreaming() {
    timer = Timer.periodic(Duration(milliseconds: 20), (Timer t) async {
      double newY = fetchECGData(); // Simulated ECG data

      if (mounted) {
        setState(() {
          // Add new point based on the current x position and new y value
          points.add(Offset(x.toDouble(), newY));
          x += 1; // Move x-axis to simulate real-time scrolling

          // Once x reaches the end, wait for a brief delay and reset x to 0
          if (x >= 380) {
            Future.delayed(Duration(milliseconds: 5), () {
              setState(() {
                x = 0; // Start from the origin again after delay
                points.clear(); // Or clear a few points, don't clear all!
              });
            });
          }

          // Limit the number of points for the graph (for smooth scrolling)
          if (points.length > 380) {
            points.removeAt(
                0); // Remove the oldest point to keep the graph manageable
          }
        });
      }
    });
  }

  double fetchECGData() {
    time++;
    return 150 + 30 * sin(time / 10); // Simulated ECG signal
  }

  /// Fetch patient insights
  Future<void> fetchPatientInsights() async {
    try {
      final data =
          await ApiClient().getSpecificPatientInsights(widget.patientId);

      if (mounted) {
        DateTime? updatedAt;
        if (data['last_updated'] != null) {
          updatedAt = DateTime.parse(data['last_updated']);
          final now = DateTime.now();
          final diff = now.difference(updatedAt);
          lastUpdated = _formatTimeDifference(diff);
          isOnline =
              diff.inMinutes <= 10; // Online if updated within last 10 mins
        } else {
          lastUpdated = "No recent data";
          isOnline = false;
        }

        setState(() {
          pFullName = data['fullname'] ?? "Unknown";
          respiration = data['respiration_rate'] != null
              ? "${data['respiration_rate']} BPM"
              : "-";
          temperature =
              data['temperature'] != null ? "${data['temperature']} °F" : "-";
          gender = data['gender'] ?? "-";
          age = data['age']?.toString() ?? "-";
          weight = data['weight']?.toString() ?? "-";
        });
      }
    } catch (e) {
      print("Failed to fetch patient insights: $e");
    }
  }

  /// Format time difference like "5 mins ago"
  String _formatTimeDifference(Duration diff) {
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return DateFormat('dd/MM/yyyy hh:mm a')
        .format(DateTime.now().subtract(diff));
  }

  /// Fetch Specialist Profile for Drawer
  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getSpecialistProfile();
      if (mounted) {
        setState(() {
          email = data["email"] ?? "-";
          sFullName = data["fullname"] ?? "-";
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email);
        await prefs.setString("full_name", sFullName);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// Load Specialist Details
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      sFullName = prefs.getString("full_name") ?? "-";
    });
    setState(() {
      email = prefs.getString("email") ?? "-";
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Go back to previous screen
          },
          child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title and Online status
            Text('Patient Insights: $pFullName',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle,
                    color: isOnline ? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 8),
                Text(
                  isOnline ? "Online" : "Offline (No data in last 10 mins)",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Last updated: $lastUpdated",
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 15),

            // Gender, Age, Weight
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard(
                    gender, 'Gender', const Color.fromARGB(255, 218, 151, 167)),
                const SizedBox(width: 7),
                _buildInfoCard(
                    age, 'Age', const Color.fromARGB(255, 218, 189, 151)),
                const SizedBox(width: 7),
                _buildInfoCard(weight, 'Weight', const Color(0xFF9CCC65)),
              ],
            ),
            const SizedBox(height: 15),

            // ECG Section
            _buildECGCard(context),
            const SizedBox(height: 15),

            // Respiration and Temperature Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard2(respiration, "Respiration", Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RespirationPage(
                        gender: gender,
                        age: age,
                        weight: weight,
                      ),
                    ),
                  );
                }),
                _buildInfoCard2(temperature, "Temperature", Colors.redAccent,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemperaturePage(
                        gender: gender,
                        age: age,
                        weight: weight,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 15),

            // Health Performance
            _buildHealthPerformanceCard(),
          ],
        ),
      ),
    );
  }

  /// Info Card
  Widget _buildInfoCard(String value, String label, Color color) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular background with blur effect
          Positioned(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Lightened version of the color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 28.0,
                    spreadRadius: 23.0,
                  ),
                ],
              ),
            ),
          ),
          // Text Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard2(
      String value, String label, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Adds padding around each card
      child: Container(
        width: 172,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.5),
              color.withOpacity(0.0)
            ], // Gradient effect
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.0,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.black),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed, // Calls the provided callback function
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 176, 85, 85), // Matches your UI
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text("Details", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// ECG Card Widget
  Widget _buildECGCard(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth,
      height: screenHeight * 0.455, // Increased height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.002,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(color: Colors.transparent),
        gradient: LinearGradient(
          colors: [Color(0xFF99B88D), Color.fromARGB(255, 193, 219, 188)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.015),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.01),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECG',
                      style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                      child: SizedBox(
                        height: screenHeight * 0.375, // Adjusted height
                        width: screenWidth,
                        child: CustomPaint(
                          painter: ECGLinePainter(points),
                          size: Size(double.infinity, 200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight * 0.0035,
                right: screenWidth * 0.02,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ECGScreen()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.014,
                        vertical: screenHeight * 0.004),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Health Performance Card Widget
  Widget _buildHealthPerformanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 154, 142, 142),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Health Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '70%',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Moderate',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// **Fixed ECGLinePainter**
class ECGLinePainter extends CustomPainter {
  final List<Offset> points;

  ECGLinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 91, 139, 36)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // **Grid**
    double gridSize = 15;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // **Draw ECG waveform from data points**
    if (points.isNotEmpty) {
      Path path = Path();
      path.moveTo(points[0].dx, points[0].dy); // Start path at first point

      // Draw smooth lines between points, connecting the dots smoothly
      for (int i = 1; i < points.length; i++) {
        path.quadraticBezierTo(
          points[i - 1].dx,
          points[i - 1].dy,
          points[i].dx,
          points[i].dy,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint to refresh the canvas
  }
}
