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
      double minValue = 1700; // ECG Min
      double maxValue = 2300; // ECG Max
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
  ECGSegment? segmentData;

  @override
  void initState() {
    super.initState();
    _loadUserDetailsOrUseParams();
    _loadUserRole();
    _startECGStream();
    _startStabilizationCountdown();
    loadLatestECGStatus();
    loadLatestECGSegments();
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

      print("📊 ECG value popped: $ecgVal");

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
    if (!SensorController().hasStabilized || SensorController().stabilizationStartTime == null) {
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
      if (double.tryParse(rawBpm) != null &&
          double.parse(rawBpm) >= 40 &&
          double.parse(rawBpm) <= 180) {
        latestBPM = rawBpm;
      } else {
        latestBPM = "-";
      }

      ecgStatus = result["ecgstatus"];

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

      // 🔔 Trigger alert if needed
      if ((ecgStatus == "Low" || ecgStatus == "High") && 
        !hasShownECGAlert &&
        SensorController().hasStabilized) {
      hasShownECGAlert = true;
      _showECGAlertDialog(ecgStatus);
    }

    });

    }
  }

  Future<void> loadLatestECGSegments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");
    if (patientId == null) return;

    final result = await apiClient.getLatestECGSegments(patientId); 

    if (result != null && result['bpm'] != null && double.tryParse(result['bpm'].toString()) != null) {
      setState(() {
        segmentData = ECGSegment.fromJson(result);
      });
    } else {
      setState(() {
        segmentData = null;
      });
    }
  }

  void _showECGAlertDialog(String condition) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ ECG Alert"),
        content: Text(
          "Detected condition: $condition\nWould you like to notify trusted contacts?",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final contacts = await ApiClient().getTrustedContacts();
                await notifyContacts(condition, contacts); // Assume this exists
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contacts notified")),
                );
              } catch (e) {
                print("Error sending alert: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to send alert")),
                );
              }
            },
            child: const Text("Notify"),
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
                            fontSize: MediaQuery.of(context).size.width * 0.04),
                      ),
                    ],
                  ),
                )
              else if (SensorController().stabilizationStartTime == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      Text("No ECG readings available!",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery.of(context).size.width * 0.04)),
                      SizedBox(height: 4),
                      Text("Check if your ESP32 is connected.",
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: MediaQuery.of(context).size.width * 0.035)),
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
                
                child: 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard(gender, "Gender"),
                    _infoCard(age, "Age"),
                    _infoCard(weight, "Weight"),
                  ],
                ),
              ),

              // SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    // Toggle Buttons
                    _toggleTabBar(),
                    SizedBox(height: 16),

                    // View: either Rhythm or Findings
                    if (!showFindings)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _infoCard(
                                (latestBPM == '-' || latestBPM == 'null' || latestBPM.isEmpty) ? '—' : latestBPM,
                                "BPM"
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                          children: [
                            Expanded(child: _statusCard(ecgStatus, statusColor)),
                          ],
                        ),
                        ],
                      )
                    else if (segmentData != null)
                      _segmentCard(segmentData!),
                  ],
                ),
              ),


              // SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              // // View Trends Button
              // if (role != 'specialist')
              //   Center(
              //     child: ElevatedButton(
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.brown[300],
              //         padding: EdgeInsets.symmetric(
              //           horizontal: MediaQuery.of(context).size.width * 0.12,
              //           vertical: MediaQuery.of(context).size.height * 0.017),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(13),
              //         ),
              //       ),
              //       onPressed: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => ECGChartScreen(
              //               patientId: null, // Uses current logged-in patient from prefs
              //               showDrawer: false,
              //             ),
              //           ),
              //         );
              //       },
              //       child: Text(
              //         "View Trends",
              //         style: GoogleFonts.poppins(
              //           fontSize: MediaQuery.of(context).size.width * 0.04,
              //           color: Colors.white,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
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

Widget _toggleTabBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pillButton("Rhythm", !showFindings),
        _pillButton("Findings", showFindings),
      ],
    ),
  );
}

Widget _pillButton(String label, bool isActive) {
  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          showFindings = label == "Findings";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

Widget _segmentCard(ECGSegment data) {
  final segments = [
    ["HR", "${data.hr} BPM"],
    ["HRV", "${data.hrv} ms"],
    ["RR", "${data.rr} ms"],
    ["P", "${data.p} ms"],
    ["PR", "${data.pr} ms"],
    ["QRS", "${data.qrs} ms"],
    ["QT", "${data.qt} ms"],
    ["QTc", "${data.qtc} ms"],
  ];

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: List.generate(segments.length ~/ 2, (i) {
        final left = segments[i * 2];
        final right = segments[i * 2 + 1];
        return TableRow(
          children: [
            _segmentTableCell(left[0], left[1]),
            _segmentTableCell(right[0], right[1]),
          ],
        );
      }),
    ),
  );
}

Widget _segmentTableCell(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Flexible(child: Text(value)),
      ],
    ),
  );
}

}

class ECGSegment {
  final String hr, hrv, rr, pr, p, qrs, qt, qtc;

  ECGSegment({
    required this.hr,
    required this.hrv,
    required this.rr,
    required this.pr,
    required this.p,
    required this.qrs,
    required this.qt,
    required this.qtc,
  });

  factory ECGSegment.fromJson(Map<String, dynamic> json) {
    String rawBpm = json['bpm']?.toString() ?? '-';
    String finalBpm = '-';

    if (double.tryParse(rawBpm) != null &&
        double.parse(rawBpm) >= 40 &&
        double.parse(rawBpm) <= 180) {
      finalBpm = rawBpm;
    }

    return ECGSegment(
      hr: finalBpm,
      hrv: json['hrv'] ?? '-',
      rr: json['rr'] != null && double.tryParse(json['rr'].toString()) != null
        ? double.parse(json['rr'].toString()).round().toString()
        : '-',
      pr: json['pr'] ?? '-',
      p: json['p'] ?? '-',
      qrs: json['qrs'] ?? '-',
      qt: json['qt'] ?? '-',
      qtc: json['qtc'] ?? '-',
    );
  }

}

