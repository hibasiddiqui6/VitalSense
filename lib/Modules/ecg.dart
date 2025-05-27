import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitalsense/controllers/sensor_controller.dart';
import 'package:vitalsense/services/alert.dart';
import '../services/api_client.dart'; // API for fetching ECG data
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/ecg_controller.dart';
// import 'ecg_trends.dart';

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
  final double graphWidth; // New parameter for width

  ECGPainter(this.points, this.graphWidth);

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
      double minValue = 1000; // ECG Min
      double maxValue = 3000; // ECG Max
      double canvasHeight = size.height * 1;
      double normalize(double value) {
        if (maxValue == minValue) {
          return size.height / 4; // Prevent division by zero
        }
        return size.height -
            ((value - minValue) / (maxValue - minValue)) * canvasHeight;
      }

      path.moveTo(points.first.dx, normalize(points.first.dy));
      for (var point in points) {
        if (point.dx <= graphWidth) { // Use graphWidth instead of size.width
          path.lineTo(point.dx, normalize(point.dy));
        } else {
          break; // Stop drawing if point exceeds the canvas width
        }
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
  List<Offset> points = [];
  double x = 0;
  Timer? ecgTimer;
  List<double> ecgBuffer = [];
  Timer? stabilizationRefreshTimer;
  ApiClient apiClient = ApiClient();
  // Patient details
  String gender = "-";
  String age = "-";
  String weight = "-";
  String role = "-";
  String latestBPM = "-";
  String ecgStatus = "-";
  Color statusColor = Colors.grey;
  bool hasShownECGAlert = false;
  bool showFindings = false;

  bool showFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetailsOrUseParams();
    _loadUserRole();
    _startECGStream();
    _startStabilizationCountdown();
    loadLatestECGStatus();
    // loadLatestECGSegments();
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

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString("role") ?? "-";
    if (!mounted) return;
    setState(() {
      role = savedRole;
    });
  }

  void _startECGStream() {
    ecgTimer = Timer.periodic(Duration(milliseconds: 20), (_) {
      if (!mounted) return;

      double? ecgVal = ECGController.instance?.popNextPoint();
      // print("📦 ECG Buffer Length: ${ECGController.instance?.buffer.length}");
      if (ecgVal == null) return;

      // if (kDebugMode) {
      //   print("📊 ECG value popped: $ecgVal");
      // }

      setState(() {
        points.add(Offset(x, ecgVal));
        x += 5;
        if (points.length > 100) points.removeAt(0);
        if (x >= 350) {
          x = 0;
          points.clear();
        }
      });
    });
  }

  void _startStabilizationCountdown() {
    stabilizationRefreshTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted && !SensorController().hasStabilized) {
        setState(() {}); // UI refresh
      }
    });
  }

  Future<void> loadLatestECGStatus() async {
    if (!SensorController().hasStabilized ||
        SensorController().stabilizationStartTime == null) {
      setState(() {
        latestBPM = "-";
        ecgStatus = "Sensor Not Connected";
        statusColor = Colors.grey;
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");

    if (patientId == null) return;

    final result = await apiClient.getLatestECGStatus(patientId);

    if (result != null) {
      setState(() {
        String rawBpm = result["bpm"].toString();
        print("👀 ECG API Response: $result");
        bool isValidBPM = double.tryParse(rawBpm) != null &&
                          double.parse(rawBpm) >= 40 &&
                          double.parse(rawBpm) <= 180;

        latestBPM = isValidBPM ? rawBpm : "-";
        ecgStatus = result["ecgstatus"];

        // ❗ Override ecgStatus if BPM is invalid
        if (!isValidBPM) {
          ecgStatus = "Unknown";
          statusColor = Colors.grey;
        } else {
          // Set status color only if BPM is valid
          switch (ecgStatus) {
            case "Normal":
              statusColor = Colors.green;
              break;
            case "Low":
              statusColor = Colors.orange;
              break;
            case "High":
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.grey;
          }
        }

        // 🔔 Only alert if BPM is valid AND status is Low or High
        if (isValidBPM &&
            (ecgStatus == "Low" || ecgStatus == "High") &&
            !hasShownECGAlert &&
            SensorController().hasStabilized) {
          hasShownECGAlert = true;
          _showECGAlertDialog(ecgStatus);
        }
      });

    }
  }

  void _showECGAlertDialog(String condition) async {
    const String alertText = "Abnormal heart rate detected";

    // Define reason based on condition (only High or Low)
    String reason;
    if (condition == "Low") {
      reason = "Heart rate is slower than normal.";
    } else {
      // Must be High
      reason = "Heart rate is faster than normal.";
    }

    final String reasonText = "\nReason: $reason";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Health Alert"),
        content: Text(
          "$alertText. $reasonText\nNotifying trusted contacts."
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final contactsList = await ApiClient().getTrustedContacts();
                if (kDebugMode) {
                  print("✅ Contacts fetched: $contactsList");
                }
                await notifyContacts(condition, contactsList, alertText, reason);
              } catch (e) {
                if (kDebugMode) {
                  print("❌ Error fetching contacts or notifying: $e");
                }
              }
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    stabilizationRefreshTimer?.cancel();
    ecgTimer?.cancel();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  return Scaffold(
    backgroundColor: const Color(0xFFEFF2E6),
    body: Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: MediaQuery.of(context).size.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.05,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back,
                          size: MediaQuery.of(context).size.width * 0.06,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.02,
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.04,
                        ),
                        child: Text(
                          "ECG",
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!SensorController().hasStabilized &&
                    SensorController().stabilizationStartTime != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          "Sensor Stabilizing... (${SensorController().getSecondsRemaining()}s left)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (SensorController().stabilizationStartTime == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Text(
                          "No ECG readings available!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Check if your ESP32 is connected.",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize:
                                MediaQuery.of(context).size.width * 0.035,
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
                        child: Stack(
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.25,
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: CustomPaint(
                                size: Size(
                                  MediaQuery.of(context).size.width * 0.9,
                                  400,
                                ),
                                painter: ECGPainter(
                                  points,
                                  MediaQuery.of(context).size.width * 0.9,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Colors.grey[800],
                                ),
                                onPressed: () {
                                  setState(() {
                                    showFullScreen = true;
                                  });
                                },
                              ),
                            ),
                          ],
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

                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _infoCard(
                                (latestBPM == '-' ||
                                        latestBPM == 'null' ||
                                        latestBPM.isEmpty)
                                    ? '—'
                                    : latestBPM,
                                "BPM",
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _statusCard(ecgStatus, statusColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ Fullscreen ECG Overlay
        if (showFullScreen)
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(171, 0, 0, 0),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.01,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: screenWidth * 0.056,
                            ),
                            onPressed: () {
                              setState(() {
                                showFullScreen = false;
                              });
                            },
                          ),
                          Text(
                            "Live ECG (Fullscreen)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.055,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.04),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: FullScreenECGWidget(points: points),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _statusCard(String status, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          status == "Sensor Not Connected" ? "No Signal" : "Status: $status",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
 
// Make sure to import ECGScreen

class FullScreenECGWidget extends StatelessWidget {
  final List<Offset> points;
  const FullScreenECGWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double graphHeight = screenHeight * 0.5;
    double minValue = 1700;
    double maxValue = 2300;

    // Determine how many steps for Y labels (you can change this)
    int divisions = 4;
    double step = (maxValue - minValue) / divisions;

    // Generate labels from maxValue to minValue
    List<double> yLabels =
        List.generate(divisions + 1, (index) => maxValue - index * step);

    // Limit X-axis points to 700 max
    

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(242, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.016,
        screenHeight * 0.02,
        screenWidth * 0.016,
        screenHeight * 0.015,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: yLabels
                .map((label) => Text(
                      label.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),

          // ECG Graph
          // ECG Graph with rounded border
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  size: Size(screenWidth * 0.9, graphHeight),
                  painter: ECGPainter(points, screenWidth * 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
