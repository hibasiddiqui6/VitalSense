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
  String SfullName = "...";
  String PfullName = "...";
  String email = "...";
  String respiration = "-";
  String temperature = "-";
  String gender = "-";
  String age = "-";
  String weight = "-";
  String lastUpdated = "-";
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    fetchPatientInsights();
    fetchUserProfile();
    _loadUserDetails();
  }

  /// Fetch patient insights
  Future<void> fetchPatientInsights() async {
    try {
      final data = await ApiClient().getSpecificPatientInsights(widget.patientId);

      if (mounted) {
        DateTime? updatedAt;
        if (data['last_updated'] != null) {
          updatedAt = DateTime.parse(data['last_updated']);
          final now = DateTime.now();
          final diff = now.difference(updatedAt);
          lastUpdated = _formatTimeDifference(diff);
          isOnline = diff.inMinutes <= 10; // Online if updated within last 10 mins
        } else {
          lastUpdated = "No recent data";
          isOnline = false;
        }

        setState(() {
          PfullName = data['fullname'] ?? "Unknown";
          respiration = data['respiration_rate'] != null ? "${data['respiration_rate']} BPM" : "-";
          temperature = data['temperature'] != null ? "${data['temperature']} °F" : "-";
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
    return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now().subtract(diff));
  }

  /// Fetch Specialist Profile for Drawer
  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getSpecialistProfile();
      if (mounted) {
        setState(() {
          email = data["email"] ?? "-";
          SfullName = data["fullname"] ?? "-";
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email);
        await prefs.setString("full_name", SfullName);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// Load Specialist Details
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      SfullName = prefs.getString("full_name") ?? "-";
    });
    setState(() {
      email = prefs.getString("email") ?? "-";
    });
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
            Text('Patient Insights: $PfullName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 8),
                Text(
                  isOnline ? "Online" : "Offline (No data in last 10 mins)",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Last updated: $lastUpdated", style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 15),

            // Gender, Age, Weight
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard(gender, 'Gender', const Color.fromARGB(255, 218, 151, 167)),
                const SizedBox(width: 7),
                _buildInfoCard(age, 'Age', const Color.fromARGB(255, 218, 189, 151)),
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
                _buildInfoCard2(temperature, "Temperature", Colors.redAccent, () {
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
                fontSize: 28, fontWeight: FontWeight.w300, color: Colors.black),
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
    return Container(
      height: 160, // Increased height
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(width: 0, color: Colors.transparent),
        gradient: LinearGradient(
          colors: [Color(0xFF99B88D), Color.fromARGB(255, 193, 219, 188)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECG',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 80, // Adjusted height
                        width: double.infinity,
                        child: CustomPaint(
                          painter: ECGLinePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ECGScreen(
                        gender: gender,
                        age: age,
                        weight: weight,
                      ),
                    ),
                  );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                          fontSize: 14,
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

  /// Placeholder for offline
  Widget _buildPlaceholderCard(String message) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey))),
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


class ECGLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // **Grid**
    double gridSize = 20;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // **ECG waveform with adjusted height**
    final path = Path();
    path.moveTo(0, size.height * 0.7); // Start from 70% height

    double x = 0;
    while (x < size.width) {
      path.relativeLineTo(4, -15); // Adjusted peak height
      path.relativeLineTo(4, 30);
      path.relativeLineTo(4, -15);
      path.relativeLineTo(4, 0);
      x += 16;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
