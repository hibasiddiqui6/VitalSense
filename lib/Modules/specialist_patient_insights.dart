import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vitalsense/controllers/sensor_controller.dart';
import '../services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ecg.dart';
import 'respiration.dart';
import 'temperature.dart';

class PatientInsightsScreen extends StatefulWidget {
  final String patientId;

  const PatientInsightsScreen({super.key, required this.patientId});

  @override
  State<PatientInsightsScreen> createState() => PatientInsightsScreenState();
}

class PatientInsightsScreenState extends State<PatientInsightsScreen> {
  static PatientInsightsScreenState? instance;

  String specialistFullName = "...";
  String patientFullName = "...";
  String email = "...";
  String respiration = "-";
  String temperature = "-";
  String gender = "-";
  String age = "-";
  String weight = "-";
  String lastUpdated = "-";
  bool isOnline = false;
  List<Offset> points = [];

  double x = 0;
  Timer? timer;
  int time = 0;

  double healthPerformance = 0.0;
  String healthStatusLabel = "Unknown";
  Color statusColor = Colors.grey;
  Timer? healthPerformanceTimer;

  DateTime? lastSuccessfulFetch;
  bool wasDisconnected = false;
  Timer? disconnectionTimer;
  Timer? stabilizationRefreshTimer;

  @override
  void initState() {
    super.initState();
    instance = this;

    stabilizationRefreshTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted && !SensorController().hasStabilized) {
        setState(() {});
      }
    });

    _initWebSocket();  // now shared logic

    startECGStreaming();  // simulated or real

    disconnectionTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkIfSensorDisconnected();
    });

    fetchUserProfile();
    _loadUserDetails();
    fetchPatientInsights();
    _loadLastFetchTimestamp();

    Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted) {
        updateHealthPerformance();
      }
    });
  }

  Future<void> _loadLastFetchTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final tsString = prefs.getString("last_fetch_${widget.patientId}");

    if (tsString != null) {
      final parsed = DateTime.tryParse(tsString);
      if (parsed != null) {
        setState(() {
          lastSuccessfulFetch = parsed;
        });
      }
    }
  }

  String _formatTimeDifference(Duration diff) {
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now().subtract(diff));
  }

  void _checkIfSensorDisconnected() {
    final now = DateTime.now();

    if (SensorController().stabilizationStartTime != null && !SensorController().hasStabilized) {
      setState(() {
        isOnline = false;
        lastUpdated = "Sensor stabilizing...";
      });
      return;
    }

    final isNowDisconnected = lastSuccessfulFetch == null ||
        now.difference(lastSuccessfulFetch!).inSeconds > 10;

    if (isNowDisconnected != wasDisconnected) {
      setState(() {
        isOnline = !isNowDisconnected;
        lastUpdated = isNowDisconnected
            ? (lastSuccessfulFetch != null
                ? DateFormat('dd/MM/yyyy hh:mm a').format(lastSuccessfulFetch!)
                : "No recent data")
            : "Just now";
      });
      wasDisconnected = isNowDisconnected;
    } else if (!isNowDisconnected) {
      final diff = now.difference(lastSuccessfulFetch!);
      setState(() {
        lastUpdated = _formatTimeDifference(diff);
      });
    }
  }

  Future<void> _initWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final smartshirtId = prefs.getString("smartshirt_id");

    while (true) {
      final ipResult = await ApiClient().getLatestMacAndIP();
      final ip = ipResult['ip_address'];

      if (widget.patientId.isNotEmpty && smartshirtId != null && ip != null) {
        final success = await SensorController().initWebSocket(
          patientId: widget.patientId,
          smartshirtId: smartshirtId,
          ip: ip,
        );

        if (success) {
          print("✅ WebSocket initialized for Specialist View.");
          break;
        } else {
          print("❌ WebSocket failed. Retrying...");
        }
      } else {
        print("❌ Missing patientId/smartshirtId/ip. Retrying...");
      }

      await Future.delayed(Duration(seconds: 5));
    }
  }

  void _saveLastFetchTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("last_fetch_${widget.patientId}", DateTime.now().toIso8601String());
  }

  void updateTemperatureLive(double temp) {
    if (temp < 93 || temp > 110) {
      setState(() {
        temperature = "Sensor Disconnected";
      });
      return;
    }

    final formatted = "${temp.toStringAsFixed(1)} °F";
    if (mounted) {
      setState(() {
        temperature = formatted;
        lastSuccessfulFetch = DateTime.now();
      });
      _saveLastFetchTimestamp();
    }
  }

  void updateRespirationLive(double resp) {
    if (resp < 5.0) {
      setState(() {
        respiration = "Sensor Disconnected";
      });
      return;
    }

    final formatted = "${resp.toStringAsFixed(1)} BPM";
    if (mounted) {
      setState(() {
        respiration = formatted;
        lastSuccessfulFetch = DateTime.now();
      });
      _saveLastFetchTimestamp();
    }
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
    return 75 + 30 * sin(time / 10); // Simulated ECG signal
  }

  /// Fetch patient insights
  Future<void> fetchPatientInsights() async {
    try {
      final data = await ApiClient().getSpecificPatientInsights(widget.patientId);

      if (data.containsKey("error")) {
        print("⚠ Error: ${data['error']}");
        return;
      }

      setState(() {
        patientFullName = data['fullname'] ?? "Unknown";
        gender = data['gender'] ?? "-";
        age = data['age']?.toString() ?? "-";
        weight = data['weight']?.toString() ?? "-";
      });
    } catch (e) {
      print("Failed to fetch patient profile: $e");
    }
  }

  /// Fetch Specialist Profile for Drawer
  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getSpecialistProfile();
      if (mounted) {
        setState(() {
          email = data["email"] ?? "-";
          specialistFullName = data["fullname"] ?? "-";
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email);
        await prefs.setString("full_name", specialistFullName);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// Load Specialist Details
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      specialistFullName = prefs.getString("full_name") ?? "-";
    });
    setState(() {
      email = prefs.getString("email") ?? "-";
    });
  }

  void updateHealthPerformance() {
    double? tempVal = double.tryParse(temperature.replaceAll(RegExp(r'[^\d.]'), ''));
    double? respVal = double.tryParse(respiration.replaceAll(RegExp(r'[^\d.]'), ''));

    // ✅ No valid data yet? Show unknown
    if (tempVal == null || respVal == null || !SensorController().hasStabilized) {
      setState(() {
        healthPerformance = 0.0;
        healthStatusLabel = "Unknown";
        statusColor = Colors.grey;
      });
      return;
    }

    double score = 0;

    if (tempVal >= 97 && tempVal <= 99.5) {
      score += 0.4;
    }

    if (respVal >= 12 && respVal <= 20) {
      score += 0.4;
    }

    if (SensorController().hasStabilized) {
      score += 0.2;
    }

    String label;
    Color color;

    if (score >= 0.8) {
      label = "Good";
      color = const Color.fromARGB(255, 165, 209, 147);
    } else if (score >= 0.5) {
      label = "Moderate";
      color = const Color.fromARGB(255, 222, 184, 133);
    } else {
      label = "Poor";
      color = Colors.redAccent;
    }

    setState(() {
      healthPerformance = score * 100;
      healthStatusLabel = label;
      statusColor = color;
    });
  }


  @override
  void dispose() {
    timer?.cancel();
    disconnectionTimer?.cancel();
    healthPerformanceTimer?.cancel();
    stabilizationRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Go back to previous screen
          },
          child: Icon(Icons.arrow_back,
              size: screenWidth * 0.048, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.032),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title and Online status
            Text('Patient Insights: $patientFullName',
                style: TextStyle(
                    fontSize: screenWidth * 0.044,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle,
                    color: isOnline ? Colors.green : Colors.red,
                    size: screenWidth * 0.024),
                SizedBox(width: screenWidth * 0.016),
                Text(
                  SensorController().stabilizationStartTime != null && !SensorController().hasStabilized
                      ? "Stabilizing..."
                      : isOnline
                          ? "Online"
                          : "Offline",
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.w500,
                    color: SensorController().stabilizationStartTime != null && !SensorController().hasStabilized
                        ? Colors.orange
                        : isOnline
                            ? Colors.green
                            : Colors.red,
                  ),
                ),

              ],
            ),
            SizedBox(height: screenHeight * 0.008),
            Text("Last updated: $lastUpdated",
                style: TextStyle(
                    fontSize: screenWidth * 0.024, color: Colors.black54)),
            SizedBox(height: screenHeight * 0.030),

            // Gender, Age, Weight
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard(
                    gender, 'Gender', const Color.fromARGB(255, 218, 151, 167)),
                SizedBox(width: screenWidth * 0.014),
                _buildInfoCard(
                    age, 'Age', const Color.fromARGB(255, 218, 189, 151)),
                SizedBox(width: screenWidth * 0.014),
                _buildInfoCard(weight, 'Weight', const Color(0xFF9CCC65)),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),

            // ECG Section
            _buildECGCard(context),
            SizedBox(height: screenHeight * 0.03),

            // Respiration and Temperature Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard2(respiration, "Respiration", Color(0xFF99B88D), () {
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
                _buildInfoCard2(temperature, "Temperature", Color(0xFF99B88D),
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
            SizedBox(height: screenHeight * 0.03),

            // Health Performance
            _buildHealthPerformanceCard(),
          ],
        ),
      ),
    );
  }

  /// Info Card
  Widget _buildInfoCard(String value, String label, Color color) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth * 0.26,
      height: screenHeight * 0.12,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.024),
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
              width: screenWidth * 0.1,
              height: screenHeight * 0.1,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Lightened version of the color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: screenWidth * 0.056,
                    spreadRadius: screenWidth * 0.043,
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
                style: TextStyle(
                    fontSize: screenWidth * 0.038, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.008),
              Text(
                label,
                style: TextStyle(
                    fontSize: screenWidth * 0.028, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard2(
      String value, String label, Color color, VoidCallback onPressed) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding:
          EdgeInsets.all(screenWidth * 0.01), // Adds padding around each card
      child: Container(
        width: screenWidth * 0.4,
        height: screenHeight * 0.25,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.5),
              color.withOpacity(0.0)
            ], // Gradient effect
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.03), //12.0
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: screenWidth * 0.02,
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
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: screenHeight * 0.005),
            Text(
              value,
              textAlign: value == "Sensor Disconnected" ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontSize: value == "Sensor Disconnected" 
                    ? screenWidth * 0.030 
                    : screenWidth * 0.055,
                fontWeight: value == "Sensor Disconnected" 
                    ? FontWeight.bold 
                    : FontWeight.w300,
                color: value == "Sensor Disconnected" 
                    ? Colors.red 
                    : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            ElevatedButton(
              onPressed: onPressed, // Calls the provided callback function
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 90, 109, 83), // Matches your UI
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.5),
                ),
                minimumSize: Size(screenWidth * 0.1,
                    screenHeight * 0.045), // Set width and height
              ),
              child: Text("Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.035, // Responsive font size
                  )),
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
      height: screenHeight * 0.345, // Increased height
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
                    SizedBox(height: screenHeight*0.02),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                      child: SizedBox(
                        height: screenHeight * 0.25, // Adjusted height
                        width: screenWidth,
                        child: CustomPaint(
                          painter: ECGLinePainter(points),
                          size: Size(double.infinity, screenHeight*0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight * 0.0075,
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.2,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 191, 200, 193),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: screenWidth * 0.008,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Health Performance',
            style: TextStyle(
                fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
              healthStatusLabel == "Unknown" ? "-" : '${healthPerformance.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Text(
              healthStatusLabel,
              style: TextStyle(fontSize: screenWidth * 0.035),
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
    double gridSize = 10;
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
