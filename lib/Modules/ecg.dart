// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart'; // API for fetching ECG data
import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:math';

class ECGScreen extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const ECGScreen({super.key, this.gender, this.age, this.weight});

  @override
  _ECGScreenState createState() => _ECGScreenState();
}

class ECGPainter extends CustomPainter {
  final List<Offset> points;

  ECGPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Define the bounding box (ensures ECG stays within this area)
    Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(bounds); // Clipping to prevent overflow
// Paint for grid lines
    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.6) // Light gray for grid
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

// Grid box size (adjust for ECG scaling)
    double smallBoxSize = 5; // Small squares

// Draw small grid (thin lines)
    for (double i = 0; i < size.width; i += smallBoxSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += smallBoxSize) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // line paint
    Paint paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Path path = Path();
    if (points.isNotEmpty) {
      double minValue = 1900; // ECG Min
      double maxValue = 2200; // ECG Max
      double canvasHeight = size.height * 0.8;
      double normalize(double value) {
        if (maxValue == minValue) {
          return size.height / 2; // Prevent division by zero
        }
        return size.height -
            ((value - minValue) / (maxValue - minValue)) * canvasHeight;
      }

      path.moveTo(points.first.dx, normalize(points.first.dy));
      for (var point in points) {
        path.lineTo(point.dx, normalize(point.dy));
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _ECGScreenState extends State<ECGScreen> {
  // List<FlSpot> ecgData = [];
  // double time = 0;
  List<Offset> points = [];
  double x = 0;
  Timer? ecgTimer;
  List<double> ecgBuffer = [];

  ApiClient apiClient = ApiClient();
  // Timer? ecgTimer;
  // double minY = 0, maxY = 4095; // Default range for 12-bit ADC
  // int baseTime = 0; // Base time for X-axis labels

  // Patient details
  String gender = "-";
  String age = "-";
  String weight = "-";

  @override
  void initState() {
    super.initState();
    startECGStreaming();
    _loadUserDetailsOrUseParams(); // Load dynamic patient details
  }

  /// Load gender, age, weight from params or SharedPreferences
  Future<void> _loadUserDetailsOrUseParams() async {
    if (widget.gender != null && widget.age != null && widget.weight != null) {
      setState(() {
        gender = widget.gender!;
        age = widget.age!;
        weight = widget.weight!;
      });
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        gender = prefs.getString("gender") ?? "-";
        age = prefs.getString("age") ?? "-";
        weight = prefs.getString("weight") ?? "-";
      });
    }
  }

  /// **Fetch real-time ECG data every 2ms**
  Future<void> startECGStreaming() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");

    if (patientId == null) {
      print("⚠️ Patient ID not found.");
      return;
    }

    // Listen to Firebase updates
    apiClient.getFirebaseECGStream(patientId).listen((String ecgValue) {
      if (ecgValue.isNotEmpty) {
        double? parsed = double.tryParse(ecgValue.trim());
        if (parsed != null) ecgBuffer.add(parsed);
      }
    }, onError: (error) {
      print("❌ ECG Stream Error: $error");
    });

    // Timer to consume buffer at fixed interval (e.g., 20ms = 50 FPS)
    ecgTimer?.cancel(); // avoid multiple timers
    ecgTimer = Timer.periodic(Duration(milliseconds: 0), (_) {
      if (!mounted || ecgBuffer.isEmpty) return;

      double ecg = ecgBuffer.removeAt(0);

      setState(() {
        points.add(Offset(x, ecg));
        x += 5;

        if (points.length > 100) points.removeAt(0);
        if (x >= 350) {
          x = 0;
          points.clear();
        }
        print("Updated Points: $points");
      });
    });
  }
    
//   // **Mock Function** to fetch ECG values from a cloud database
//   Future<double> fetchECGDataFromCloud() async {
//   return 50 + 30 * sin(x / 20); // Simulated ECG signal with smooth waves
// }

  /// Auto-Adjust Y-Axis based on incoming data
  // void _updateYAxisRange() {
  //   if (ecgData.isNotEmpty) {
  //     double minVal = ecgData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  //     double maxVal = ecgData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

  //     setState(() {
  //       minY = minVal - 100;
  //       maxY = maxVal + 100;
  //     });
  //   }
  // }

  @override
  void dispose() {
    ecgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2E6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04, // 4% of width
            vertical: MediaQuery.of(context).size.height * 0.02, // 2% of height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back,
                          size: MediaQuery.of(context).size.width * 0.06,
                          color: Colors.black),
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.02), // 2% of screen width
                    Container(
                      margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width *
                              0.04), // 4% of screen width
                      child: Text(
                        "ECG",
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).size.width *
                              0.05, // 5% of screen width
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ECG Graph Section
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 200, 215, 160),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                child: Column(
                  children: [
                    // Inner Box for ECG Graph
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.025),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: CustomPaint(
                          size: Size(MediaQuery.of(context).size.width * 0.9,
                              400), // ECG plot size
                          painter: ECGPainter(points),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Gender, Age, Weight Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard(gender, "Gender"),
                    _infoCard(age, "Age"),
                    _infoCard(weight, "Weight"),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // View Trends Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width *
                            0.12, // 12% of screen width
                        vertical: MediaQuery.of(context).size.height *
                            0.017), // 1.7% of screen height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "View Trends",
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: Colors.white,
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

  Widget _infoCard(String value, String label) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width * 0.01), // 1% of screen width
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height *
                0.015), // 1.5% of screen height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    fontWeight: FontWeight.bold)), // 4.5% of screen width
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width *
                        0.04, // 4% of screen width
                    color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
