import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_client.dart';
import 'ecg.dart';
import 'temperature.dart';
import 'respiration.dart';
import '../widgets/patient_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientDashboard(),
    );
  }
}

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  String respiration = "-";
  String temperature = "-";
  String fullName = "...";
  String email = "...";
  String gender = "-";
  String age = "-";
  String weight = "-";
  bool isFetching = true;
  bool showNoReadings = false;
  bool showReconnecting = false;
  bool finalMessageShown = false;
  Timer? disconnectionTimer;
  Timer? dataFetchTimer;
  List<Offset> points = [];
  DateTime? lastSuccessfulFetch;
  int secondsRemaining = 30;
  bool hasStabilized = false;
  DateTime? stabilizationStartTime;
  bool isValidSensorConnected = false;

  double x = 0;
  Timer? timer;
  int time = 0;

  @override
  void initState() {
    super.initState();

    startECGStreaming();

    // **Start continuous data fetching**
    dataFetchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchSensorData();
    });

    // **Start the disconnection timeout**
    disconnectionTimer =
        Timer(const Duration(seconds: 20), _handleDataFetchFailure);

    // **Fetch user details**
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
                points.clear();// Or clear a few points, don't clear all!
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
    return 100 + 30 * sin(time / 10); // Simulated ECG signal
  }

  /// **Fetch sensor data from Flask server**
  Future<void> fetchSensorData() async {
  try {
    final data = await ApiClient().getSensorData();
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    if (data.containsKey("error")) {
      print("❌ Sensor error: ${data['error']}");
      isValidSensorConnected = false;

      final millis = prefs.getInt("stabilization_start_time");
      if (millis != null) {
        final lastStable = DateTime.fromMillisecondsSinceEpoch(millis);
        final gap = now.difference(lastStable).inSeconds;

        // Only reset stabilization if sensor stayed offline more than 30s
        if (gap > 30) {
          await prefs.remove("stabilization_start_time");
          hasStabilized = false;
          secondsRemaining = 30;
        } else {
          final diff = now.difference(lastStable).inSeconds;
          hasStabilized = diff >= 30;
          secondsRemaining = hasStabilized ? 0 : 30 - diff;
        }
      } else {
        hasStabilized = false;
        secondsRemaining = 30;
      }

      if (data['error'] == "Stale data" || lastSuccessfulFetch == null || now.difference(lastSuccessfulFetch!).inSeconds > 10) {
        setState(() {
          showNoReadings = true;
          showReconnecting = false;
        });
      } else {
        setState(() {
          showNoReadings = false;
          showReconnecting = true;
        });
      }

      return;
    }

    // ✅ Valid reading — reset watchdog
    lastSuccessfulFetch = now;
    isValidSensorConnected = true;

    if (!prefs.containsKey("stabilization_start_time")) {
      await prefs.setInt("stabilization_start_time", now.millisecondsSinceEpoch);
      hasStabilized = false;
      secondsRemaining = 30;
    } else {
      final millis = prefs.getInt("stabilization_start_time")!;
      final savedStart = DateTime.fromMillisecondsSinceEpoch(millis);
      final diff = now.difference(savedStart).inSeconds;
      hasStabilized = diff >= 30;
      secondsRemaining = hasStabilized ? 0 : 30 - diff;
    }

    setState(() {
      respiration = "${data['respiration_rate']} BPM";
      temperature = "${data['temperature']} °F";
      isFetching = false;
      showNoReadings = false;
      showReconnecting = false;
      finalMessageShown = false;
    });

    disconnectionTimer?.cancel();
    disconnectionTimer = Timer(const Duration(seconds: 10), _handleDataFetchFailure);

  } catch (e) {
    print("❌ Exception fetching data: $e");
    isValidSensorConnected = false;
    _handleDataFetchFailure();
  }
}

  /// **Fetch user profile data**
  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getPatientProfile();

      if (data.containsKey("error")) {
        print("⚠ Error fetching user profile: ${data['error']}");
        return;
      }

      if (mounted) {
        setState(() {
          fullName = data["fullname"] ?? "Unknown User";
          gender = data["gender"] ?? "-";
          age = data["age"]?.toString() ?? "-";
          weight = data["weight"]?.toString() ?? "-";
        });
        // **Save to SharedPreferences for Drawer Use**
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("full_name", fullName);
        await prefs.setString("gender", gender);
        await prefs.setString("age", age);
        await prefs.setString("weight", weight);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// **Load Details from SharedPreferences**
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
    });
    setState(() {
      gender = prefs.getString("gender") ?? "-";
    });
    setState(() {
      age = prefs.getString("age") ?? "-";
    });
    setState(() {
      weight = prefs.getString("weight") ?? "-";
    });
    setState(() {
      email = prefs.getString("email") ?? "-";
    });
  }

  /// **Handle data fetch failure with smooth transition**
  void _handleDataFetchFailure() {
    if (!mounted) return;
    final now = DateTime.now();

    if (lastSuccessfulFetch != null && now.difference(lastSuccessfulFetch!).inSeconds < 10) {
      setState(() {
        showNoReadings = false;
        showReconnecting = true;
      });
    } else {
      setState(() {
        showNoReadings = true;
        showReconnecting = false;
      });
    }
  }

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    disconnectionTimer?.cancel();
    timer?.cancel();
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: PatientDrawer(
          fullName: fullName, // fetched and stored in State
          email: email, // fetched and stored in State
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dynamic User Greeting
            Text(
              'Hi! $fullName',
              style: TextStyle(
                  fontSize: screenWidth * 0.05, // 5% of screen width
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% of screen height

            // Show persistent message if no valid readings are available
if (isValidSensorConnected && !hasStabilized && secondsRemaining > 0)
  Column(children: [
    CircularProgressIndicator(),
    SizedBox(height: screenHeight * 0.01),
    Text("Sensor Stabilizing... ($secondsRemaining s left)",
        style: TextStyle(
            fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold)),
              ])
            else if (isValidSensorConnected && hasStabilized)
              SizedBox.shrink() // readings will be shown below
            else if (showReconnecting)
              Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: screenHeight * 0.01),
                Text("Waiting for next reading...",
                    style: TextStyle(fontSize: 16)),
              ])
            else if (showNoReadings)
              Column(children: [
                Text("No readings to display!",
                    style: TextStyle(
                        fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold)),
                SizedBox(height: screenHeight * 0.01),
                Text("Check if your ESP32 is active.",
                    style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
              ]),
            SizedBox(height: screenHeight * 0.01), //15

            // Gender, Age, Weight Cards
            Container(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoCard(gender, 'Gender',
                      const Color.fromARGB(255, 218, 151, 167)),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.02), //7size
                  _buildInfoCard(
                      age, 'Age', const Color.fromARGB(255, 218, 189, 151)),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02), //7
                  _buildInfoCard(weight, 'Weight', const Color(0xFF9CCC65)),
                  SizedBox(
                      width: MediaQuery.of(context).size.width *
                          0.02), //7 // Keep weight static for now
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03), //height: 15

            // ECG Section
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
              child: _buildECGCard(context),
            ),
            SizedBox(height: screenHeight * 0.01), //height: 15

            // Respiration and Temperature Cards with Live Data
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard2(respiration, "Respiration", Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RespirationPage()),
                  );
                }),
                _buildInfoCard2(temperature, "Temperature", Colors.redAccent,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TemperaturePage()),
                  );
                }),
              ],
            ),

            // Health Performance (Static for now)
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.04,
                screenHeight * 0.05,
                screenWidth * 0.04,
                screenHeight * 0.05,
              ), // Responsive padding
              child: _buildHealthPerformanceCard(),
            )
          ],
        ),
      ),
    );
  }

  // Function to build small information cards
  Widget _buildInfoCard(String value, String label, Color color) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth * 0.3, //120
      height: screenHeight * 0.15, //120
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
              width: screenWidth * 0.05,
              height: screenHeight * 0.05,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Lightened version of the color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: screenWidth * 0.07,
                    spreadRadius: screenWidth * 0.06,
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
                    fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: screenWidth * 0.025, color: Colors.black54),
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
        width: screenWidth * 0.45,
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
              style: TextStyle(
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.w300,
                  color: Colors.black),
            ),
            SizedBox(height: screenHeight * 0.01),
            ElevatedButton(
              onPressed: onPressed, // Calls the provided callback function
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 176, 85, 85), // Matches your UI
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.2,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 154, 142, 142),
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
            '70%',
            style: TextStyle(
                fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Text(
              'Moderate',
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
