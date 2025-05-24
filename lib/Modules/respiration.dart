import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitalsense/controllers/sensor_controller.dart';
import '../services/api_client.dart';
import '../services/alert.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'respiration_trends.dart';

class RespirationPage extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const RespirationPage({
    super.key,
    this.gender,
    this.age,
    this.weight,
  });

  @override
  RespirationPageState createState() => RespirationPageState();
}

class RespirationPageState extends State<RespirationPage> {
  static RespirationPageState? instance;
  String respirationRate = "Loading...";
  String respirationStatus = "Loading...";
  bool isFetching = true;
  bool showError = false;
  String gender = "-";
  String age = "-";
  String weight = "-";
  String role = "-";
  DateTime? lastSuccessfulFetch;
  double? lastValidResp;
  bool hasShownAlert = false; 

  @override
  void initState() {
    super.initState();
    instance = this;

    _loadUserDetailsOrUseParams();
    _loadUserRole();

    // Check for connection timeout
    Future.delayed(Duration(seconds: 5), () {
      if (mounted && lastSuccessfulFetch == null) {
        setState(() {
          respirationRate = "-";
          respirationStatus = "Sensor Not Connected";
          isFetching = false;
          showError = true;
        });
      }
    });

    // Periodically refresh stabilization state from SensorController
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString("role") ?? "-";
    if (!mounted) return;
    setState(() {
      role = savedRole;
    });
  }

  Future<void> _loadUserDetailsOrUseParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      gender = widget.gender ?? prefs.getString("gender") ?? "-";
      age = widget.age ?? prefs.getString("age") ?? "-";
      weight = widget.weight ?? prefs.getString("weight") ?? "-";
    });
  }

  
  void updateFromRealtime(double respVal) async {
    final now = DateTime.now();

    if (respVal < 5.0) {
      setState(() {
        respirationRate = "-";
        respirationStatus = "Sensor Disconnected";
        showError = true;
        isFetching = false;
      });
      return;
    }

    final formatted = "${respVal.toStringAsFixed(1)} BPM";

    lastValidResp = respVal;
    lastSuccessfulFetch = now;

    setState(() {
      respirationRate = formatted;
      isFetching = false;
      showError = false;
    });

    if (SensorController().hasStabilized) {
      final classification = await ApiClient().classifyRespiration(respVal);
      final newStatus = classification['status'] ?? "Unknown";
      final newDisease = classification['disease'];

      print("Respiration Status: $newStatus");

      if (!mounted) return;

      if (newDisease != null && !hasShownAlert) {
        _showAlertNotification(context, newDisease);
        hasShownAlert = true;
      }

      setState(() {
        respirationStatus = newStatus;
      });
    } else {
      setState(() {
        respirationStatus = "Stabilizing...";
      });
    }
  }

  void _showAlertNotification(BuildContext context, String disease) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Health Alert"),
        content: Text(
            "Abnormal respiration detected: $disease.\nNotifying trusted contacts."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final contactsList = await ApiClient().getTrustedContacts();
                if (kDebugMode) {
                  print("✅ Contacts fetched: $contactsList");
                }

                await notifyContacts(disease, contactsList);
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
    instance = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool hasStartedStabilizing = SensorController().stabilizationStartTime != null;
    final bool isStabilizing = hasStartedStabilizing && !SensorController().hasStabilized;
    final int secondsLeft = isStabilizing ? SensorController().getSecondsRemaining() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button and Title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, size: screenWidth * 0.06, color: Colors.black),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    margin: EdgeInsets.only(left: screenWidth * 0.038),
                    child: Text(
                      "RESPIRATION",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // BPM Card with Gradient Border
              Container(
                width: screenWidth,
                height: screenHeight * 0.2,
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 150, 133, 115),
                      Color.fromARGB(255, 201, 192, 183)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.045),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      showError
                          ? Text(
                              respirationRate,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.08,
                                color: Colors.black,
                              ),
                            )
                          : isFetching
                              ? const CircularProgressIndicator()
                              : Text(
                                  respirationRate,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.1,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                      Icon(Icons.air, size: screenWidth * 0.15, color: const Color.fromARGB(136, 0, 0, 0)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenWidth * 0.05),

              // Gender, Age, Weight
              Container(
                width: screenWidth,
                height: screenWidth * 0.25,
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 219, 215, 208),
                      Color.fromARGB(255, 193, 177, 158),
                      Color.fromARGB(255, 156, 144, 123),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoCard(gender, "Gender"),
                    _infoCard(age, "Age"),
                    _infoCard(weight, "Weight"),
                  ],
                ),
              ),

              SizedBox(height: screenWidth * 0.05),

              // Status Card
              Container(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                decoration: BoxDecoration(
                  color: _statusColor(respirationStatus),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Center(
                  child: Text(
                    !hasStartedStabilizing
                    ? "Waiting for connection..."
                    : isStabilizing
                      ? "Sensor Stabilizing... ($secondsLeft s left)"
                      : "Status: $respirationStatus",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // BPM Range Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _statusText("Normal:", "12-20 BPM"),
                    _statusText("Slow:", "< 12 BPM"),
                    _statusText("Rapid:", "> 20 BPM"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Conditionally render View Trends button
              if (role != 'specialist')
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[300],
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RespChartScreen()),
                      );
                    },
                    child: Text(
                      "View Trends",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
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

  // Gender, Age, Weight Card
  Widget _infoCard(String value, String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.03,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Slow":         // < 12 BPM
        return Colors.orangeAccent;
      case "Normal":       // 12–20 BPM
        return Colors.green;
      case "Rapid":        // > 20 BPM
        return Colors.redAccent;
      case "Sensor Disconnected":
        return Colors.grey;
      case "Stabilizing...":
        return Colors.amber;
      default:
        return const Color.fromARGB(255, 189, 107, 77); // fallback
    }
  }

  Widget _statusText(String title, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
      child: RichText(
        text: TextSpan(
          text: "$title ",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
