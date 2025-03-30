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

  @override
  void initState() {
    super.initState();

    // **Start continuous data fetching**
    dataFetchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchSensorData();
    });

    // **Start the disconnection timeout**
    disconnectionTimer = Timer(const Duration(seconds: 10), _handleDataFetchFailure);

    // **Fetch user details**
    fetchUserProfile();
    _loadUserDetails();
  }

  /// **Fetch sensor data from Flask server**
  Future<void> fetchSensorData() async {
    try {
      final data = await ApiClient().getSensorData();

      if (data.containsKey("error")) {
        print("⚠ No sensor data available.");
        setState(() {
          showNoReadings = true;
          showReconnecting = false;
          finalMessageShown = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          respiration = "${data['respiration_rate']} BPM";
          temperature = "${data['temperature']} °F";
          isFetching = false;
          showNoReadings = false;
          showReconnecting = false;
          finalMessageShown = false;
        });
      }

      // Reset the disconnection timer when new data is received
      disconnectionTimer?.cancel();
      disconnectionTimer = Timer(const Duration(seconds: 10), _handleDataFetchFailure);
    } catch (e) {
      print("Failed to fetch sensor data: $e");
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
    if (mounted && !finalMessageShown) {
      setState(() {
        isFetching = false;
        showNoReadings = true;
        showReconnecting = false; // Ensure 'Reconnecting' does not replace the message
        finalMessageShown = true;
      });

      // **After 3 seconds, show "Reconnecting..."**
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !finalMessageShown) {
          setState(() {
            showReconnecting = true;
          });

          // **After another 5 seconds, show the final message**
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                showReconnecting = false;
                finalMessageShown = true; // Prevent further updates
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    disconnectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: PatientDrawer(
          fullName: fullName, // fetched and stored in State
          email: email,       // fetched and stored in State
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dynamic User Greeting
            Text(
              'Hi! $fullName',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Show persistent message if no valid readings are available
            if (showNoReadings || finalMessageShown) 
              Column(
                children: [
                  const Text(
                    "No readings to display!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (showReconnecting)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Reconnecting...", style: TextStyle(fontSize: 16)),
                      ],
                    )
                  else
                    const Text(
                      "Check if your ESP32 is active.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                ],
              ),
            const SizedBox(height: 15),

            // Gender, Age, Weight Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard(gender, 'Gender', const Color.fromARGB(255, 218, 151, 167)),
                const SizedBox(width: 7),
                _buildInfoCard(age, 'Age', const Color.fromARGB(255, 218, 189, 151)),
                const SizedBox(width: 7),
                _buildInfoCard(weight, 'Weight', const Color(0xFF9CCC65)), // Keep weight static for now
              ],
            ),

            const SizedBox(height: 15),

            // ECG Section
            _buildECGCard(context),
            const SizedBox(height: 15),

            // Respiration and Temperature Cards with Live Data
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard2(respiration, "Respiration", Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RespirationPage()),
                  );
                }),
                _buildInfoCard2(temperature, "Temperature", Colors.redAccent, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TemperaturePage()),
                  );
                }),
              ],
            ),

            const SizedBox(height: 15),

            // Health Performance (Static for now)
            _buildHealthPerformanceCard(),
          ],
        ),
      ),
    );
  }
  // Function to build small information cards
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
                      MaterialPageRoute(builder: (context) => ECGScreen()),
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
