import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart'; // Import API client
import '../services/alert.dart'; // Import API client
import 'dart:async'; // Import Timer
import 'package:shared_preferences/shared_preferences.dart';
import 'temperature_trends.dart';
import '../controllers/sensor_controller.dart';

class TemperaturePage extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const TemperaturePage({
    super.key,
    this.gender,
    this.age,
    this.weight,
  });

  @override
  TemperaturePageState createState() => TemperaturePageState();
}

class TemperaturePageState extends State<TemperaturePage> {
  static TemperaturePageState? instance;
  String temperature = "Loading...";
  String currentTempStatus = "Loading...";
  bool isFetching = true;
  bool showError = false;
  String gender = "-";
  String age = "-";
  String weight = "-";
  String role = "-";
  bool hasShownAlert = false;
  double? lastValidTemp;
  DateTime? lastSuccessfulFetch;

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
          temperature = "-";
          currentTempStatus = "Sensor Not Connected";
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


  void updateFromRealtime(double tempVal) async {
    final now = DateTime.now();

    if (tempVal < 93 || tempVal > 110) {
      setState(() {
        temperature = "-";
        currentTempStatus = "Sensor Disconnected";
        showError = true;
        isFetching = false;
      });
      return;
    }

    final formatted = "${tempVal.toStringAsFixed(1)} °F";

    lastValidTemp = tempVal;
    lastSuccessfulFetch = now;

    setState(() {
      temperature = formatted;
      isFetching = false;
      showError = false;
    });

    if (SensorController().hasStabilized) {
      final classification = await ApiClient().classifyTemperature(tempVal);
      final newStatus = classification['status'] ?? "Unknown";
      final newDisease = classification['disease'];

      if (!mounted) return;

      if (newDisease != null && !hasShownAlert) {
        _showAlertNotification(context, newDisease);
        hasShownAlert = true;
      }

      setState(() {
        currentTempStatus = newStatus;
      });
    } else {
      setState(() {
        currentTempStatus = "Stabilizing...";
      });
    }
  }

  /// Load gender, age, weight from params or SharedPreferences
  Future<void> _loadUserDetailsOrUseParams() async {
    if (widget.gender != null && widget.age != null && widget.weight != null) {
      if (!mounted) return;
      setState(() {
        gender = widget.gender!;
        age = widget.age!;
        weight = widget.weight!;
      });
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        gender = prefs.getString("gender") ?? "-";
        age = prefs.getString("age") ?? "-";
        weight = prefs.getString("weight") ?? "-";
      });
    }
  }

  void _showAlertNotification(BuildContext context, String status) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("⚠️ Health Alert"),
      content: Text(
        "Abnormal temperature detected: $status.\nNotifying trusted contacts."
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

              await notifyContacts(status, contactsList);
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

  Color _statusColor(String status) {
    switch (status) {
      case "Low": // < 95°F
        return Colors.blueAccent;
      case "Below Normal": // 95.0 - 96.8°F
        return Colors.orangeAccent;
      case "Normal": // 96.8 - 99°F
        return Colors.green;
      case "Elevated": // >99 - <100.4°F
        return Colors.deepOrange;
      case "High": // 100.4 - <104°F
        return Colors.redAccent;
      case "Very High": // 104 - <107°F
        return const Color.fromARGB(255, 175, 33, 33); // intense red
      case "Critical": // ≥107°F
        return Colors.purple;
      case "Sensor Disconnected":
        return Colors.grey;
      case "Stabilizing...":
        return Colors.amber;
      default:
        return const Color.fromARGB(255, 189, 107, 77); // fallback
    }
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
              // 🔙 Back Button and Title
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
                      "TEMPERATURE",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),

              // 🌡 Temperature Card with Gradient
              Container(
                width: screenWidth,
                height: screenHeight * 0.2,
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 150, 133, 115),
                      Color.fromARGB(255, 201, 192, 183),
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
                              temperature,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.08,
                                color: Colors.black,
                              ),
                            )
                          : isFetching
                              ? const CircularProgressIndicator()
                              : Text(
                                  temperature,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.1,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                      Icon(Icons.thermostat, size: screenWidth * 0.15, color: const Color.fromARGB(136, 0, 0, 0)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenWidth * 0.05),

              // 👤 Gender, Age, Weight
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

              // ℹ️ Status Card
             Container(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                decoration: BoxDecoration(
                  color: _statusColor(currentTempStatus),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Center(
                  child: Text(
                    !hasStartedStabilizing
                    ? "Waiting for connection..."
                    : isStabilizing
                      ? "Sensor Stabilizing... ($secondsLeft s left)"
                      : "Status: $currentTempStatus",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🌡️ Temperature Classification
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
                    _statusText("Too Low:", "< 95°F"),
                    _statusText("Normal:", "96.8–98.6°F"),
                    _statusText("Fever:", "≥ 100.4°F"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 📈 View Trends
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
                        MaterialPageRoute(builder: (context) => const TempChartScreen()),
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
