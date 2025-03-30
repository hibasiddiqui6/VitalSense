import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart'; // Import API client
import '../services/alert.dart'; // Import API client
import 'dart:async'; // Import Timer
import 'package:shared_preferences/shared_preferences.dart';
import 'temp_trends.dart';

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
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  String temperature = "Loading...";
  String currentTempStatus = "Loading...";
  bool isFetching = true;
  bool showError = false;
  Timer? dataFetchTimer;
  String gender = "-";
  String age = "-";
  String weight = "-";
  DateTime? startTime;
  int secondsRemaining = 60;
  bool hasStabilized = false;

  @override
    void initState() {
      super.initState();

      // Only set start time if it's not already stabilized
      if (!hasStabilized) {
        startTime = DateTime.now();
      }

      _startTemperatureFetchingLoop();
      _loadUserDetailsOrUseParams();
    }

  void _startTemperatureFetchingLoop() {
    dataFetchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchTemperature();

      if (!hasStabilized && startTime != null) {
        final now = DateTime.now();
        final diff = now.difference(startTime!);
        final remaining = 60 - diff.inSeconds;

        if (remaining > 0) {
          setState(() {
            secondsRemaining = remaining;
          });
        } else {
          setState(() {
            hasStabilized = true;
            secondsRemaining = 0;
          });
        }
      }
    });
  }

  /// Fetch latest temperature
    Future<void> fetchTemperature() async {
      try {
        final data = await ApiClient().getSensorData();

        if (data.containsKey("error") || data['temperature'] == null) {
          setState(() {
            showError = true;
            temperature = "-";
            currentTempStatus = "Sensor Error";
          });
          return;
        }

        final rawTemp = double.tryParse(data['temperature'].toString()) ?? -100;

        if (rawTemp == -100) {
          setState(() {
            temperature = "Sensor Disconnected";
            currentTempStatus = "No Data";
            isFetching = false;
            showError = false;
          });
          return;
        }

        final formattedTemp = "${rawTemp.toStringAsFixed(1)} °F";

        if (hasStabilized) {
            String newStatus = _classifyTemperature(rawTemp);

            // Trigger alert if status is critical
            if (newStatus.contains("Fever") || newStatus.contains("Hyperthermia") || newStatus.contains("Hyperpyrexia")) {
              _showAlertNotification(newStatus);
            }

            setState(() {
              temperature = formattedTemp;
              currentTempStatus = newStatus;
              isFetching = false;
              showError = false;
            });
          } else {
            setState(() {
              temperature = formattedTemp;
              currentTempStatus = "Stabilizing...";
              isFetching = false;
              showError = false;
            });
          }
      } catch (e) {
        print("❌ Failed to fetch temperature: $e");
        setState(() {
          showError = true;
          temperature = "Error";
          currentTempStatus = "Unknown";
        });
      }
    }


  String _classifyTemperature(double tempF) {
    if (tempF == -100.0) return "Sensor Disconnected";

    // Based on typical axillary ranges + research context
    if (tempF < 95.0) return "Hypothermia";
    if (tempF >= 95.0 && tempF < 96.8) return "Below Normal";
    if (tempF >= 96.8 && tempF <= 98.6) return "Normal";
    if (tempF > 98.6 && tempF < 100.4) return "Elevated (Monitor)";
    if (tempF >= 100.4 && tempF < 104.0) return "Fever";
    if (tempF >= 104.0 && tempF < 107.0) return "Hyperthermia";
    if (tempF >= 107.0) return "Hyperpyrexia";

    return "Unknown";
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

  void _showAlertNotification(String status) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Health Alert"),
        content: Text("Abnormal temperature detected: $status.\nNotifying trusted contacts."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _notifyContacts(status); // 👈 call it here
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _notifyContacts(String status) async {
    try {
      final contactsList = await ApiClient().getTrustedContacts(); // already used in your screen
      await notifyTrustedContacts(status, contactsList);
      print("✅ Contacts fetched: $contactsList");
    } catch (e) {
      print("❌ Error sending alert: $e");
    }
  }


  @override
  void dispose() {
    dataFetchTimer?.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    backgroundColor: const Color(0xFFF6F2E9),
    body: SafeArea(
      child: SingleChildScrollView( // 👈 Prevent overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "TEMPERATURE",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          showError
                              ? Text(
                                  temperature,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    color: Colors.black,
                                  ),
                                )
                              : isFetching
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      temperature,
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          const Icon(Icons.thermostat, size: 40, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Gradient Box
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const RadialGradient(
                    colors: [
                      Color.fromARGB(0, 237, 200, 172),
                      Color.fromRGBO(235, 196, 176, 1),
                      Color.fromARGB(255, 220, 200, 190),
                    ],
                    radius: 1.5,
                    center: Alignment(0.7, -0.6),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoCard(gender, "Gender"),
                        _infoCard(age, "Age"),
                        _infoCard(weight, "Weight"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _statusCard(
                      secondsRemaining > 0
                          ? "Sensor Stabilizing... ($secondsRemaining s left)"
                          : "Status: $currentTempStatus",
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _tempCard("< 95°F", "Too Low"),
                        _tempCard("96.8–98.6°F", "Normal"),
                        _tempCard("≥ 100.4°F", "Fever"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // View Trends Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TempChartScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 222, 155, 131),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  minimumSize: Size(screenWidth * 0.9, 50), // 👈 Responsive
                ),
                child: const Text(
                  "View Trends",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Test Alert Button
              ElevatedButton(
                onPressed: () async {
                  await _notifyContacts("🔥 Manual Test - Hyperpyrexia");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  minimumSize: Size(screenWidth * 0.9, 50), // 👈 Responsive
                ),
                child: const Text(
                  "⚠️ Send Test Alert",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // Status Card Widget
  Widget _statusCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 189, 107, 77),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Gender, Age, Weight Card
  Widget _infoCard(String value, String label) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 252, 208, 192),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Temperature Card
  Widget _tempCard(String temp, String status) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 190, 130, 110),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                temp,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
