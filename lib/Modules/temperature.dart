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
  int secondsRemaining = 30;
  bool hasStabilized = false;
  bool hasShownAlert = false;
  DateTime? lastTempFetch;
  DateTime? lastSuccessfulFetch;
  double? lastValidTemp; 

  @override
  void initState() {
    super.initState();

    _loadStabilizationTime();
    _startTemperatureFetchingLoop();
    _loadUserDetailsOrUseParams();
  }

  Future<void> _loadStabilizationTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("stabilization_start_time")) {
      final millis = prefs.getInt("stabilization_start_time")!;
      final savedStartTime = DateTime.fromMillisecondsSinceEpoch(millis);
      final now = DateTime.now();
      final diff = now.difference(savedStartTime).inSeconds;

      if (diff >= 30) {
        if (!mounted) return;
        setState(() {
          hasStabilized = true;
          secondsRemaining = 0;
          startTime = savedStartTime;
        });
      } else {
        if (!mounted) return;
        setState(() {
          startTime = savedStartTime;
          hasStabilized = false;
          secondsRemaining = 30 - diff;
        });
      }
    }
  }

  void _startTemperatureFetchingLoop() {
    dataFetchTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await fetchTemperature();

      if (!hasStabilized && startTime != null) {
        final now = DateTime.now();
        final diff = now.difference(startTime!);
        final remaining = 30 - diff.inSeconds;

        if (remaining > 0) {
          if (!mounted) return;
          setState(() {
            secondsRemaining = remaining;
          });
        } else {
          if (!mounted) return;
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
      final now = DateTime.now();

      // Reset if no update for > 5 minutes
      if (lastTempFetch != null &&
          now.difference(lastTempFetch!).inSeconds > 300) {
        print("⚠️ Detected gap > 5 mins. Restarting stabilization.");
        if (!mounted) return;
        setState(() {
          hasStabilized = false;
          hasShownAlert = false;
          secondsRemaining = 30;
          startTime = now;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("stabilization_start_time", now.millisecondsSinceEpoch);
      }

      lastTempFetch = now;

      final data = await ApiClient().getSensorData();

      if (data.containsKey("error") || data['temperature'] == null) {
        // Use last successful value if it's within 30s
        if (lastSuccessfulFetch != null &&
            now.difference(lastSuccessfulFetch!).inSeconds <= 30 &&
            lastValidTemp != null) {
          final fallbackTemp = "${lastValidTemp!.toStringAsFixed(1)} °F";
          if (!mounted) return;
          setState(() {
            temperature = fallbackTemp;
            currentTempStatus = hasStabilized ? currentTempStatus : "Stabilizing...";
            isFetching = false;
            showError = false;
          });
          return;
        }

        if (!mounted) return;
        setState(() {
          showError = true;
          temperature = "-";
          currentTempStatus = "Sensor Error";
        });
        return;
      }

      final rawTemp = double.tryParse(data['temperature'].toString()) ?? -100;

      if (rawTemp == -100) {
        // Same fallback mechanism for rawTemp invalid case
        if (lastSuccessfulFetch != null &&
            now.difference(lastSuccessfulFetch!).inSeconds <= 30 &&
            lastValidTemp != null) {
          final fallbackTemp = "${lastValidTemp!.toStringAsFixed(1)} °F";
          if (!mounted) return;
          setState(() {
            temperature = fallbackTemp;
            currentTempStatus = hasStabilized ? currentTempStatus : "Stabilizing...";
            isFetching = false;
            showError = false;
          });
          return;
        }

        if (!mounted) return;
        setState(() {
          temperature = "Sensor Disconnected";
          currentTempStatus = "No Data";
          isFetching = false;
          showError = false;
        });
        return;
      }

      // Save valid data for fallback
      lastValidTemp = rawTemp;
      lastSuccessfulFetch = now;

      final formattedTemp = "${rawTemp.toStringAsFixed(1)} °F";

      if (hasStabilized) {
        final classification = await ApiClient().classifyTemperature(rawTemp);
        final newStatus = classification['status'] ?? "Unknown";
        final newDisease = classification['disease'];

        if (newDisease != null && !hasShownAlert) {
          _showAlertNotification(context, newDisease);
          hasShownAlert = true;
        }

        if (!mounted) return;
        setState(() {
          temperature = formattedTemp;
          currentTempStatus = newStatus;
          isFetching = false;
          showError = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          temperature = formattedTemp;
          currentTempStatus = "Stabilizing...";
          isFetching = false;
          showError = false;
        });
      }
    } catch (e) {
      print("❌ Failed to fetch temperature: $e");

      final now = DateTime.now();
      if (lastSuccessfulFetch != null &&
          now.difference(lastSuccessfulFetch!).inSeconds <= 30 &&
          lastValidTemp != null) {
        final fallbackTemp = "${lastValidTemp!.toStringAsFixed(1)} °F";
        if (!mounted) return;
        setState(() {
          temperature = fallbackTemp;
          currentTempStatus = hasStabilized ? currentTempStatus : "Stabilizing...";
          isFetching = false;
          showError = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        showError = true;
        temperature = "Error";
        currentTempStatus = "Unknown";
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
              print("✅ Contacts fetched: $contactsList");

              await notifyContacts(status, contactsList);
            } catch (e) {
              print("❌ Error fetching contacts or notifying: $e");
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
      case "Fever":
      case "Hyperthermia":
      case "Hyperpyrexia":
        return Colors.redAccent;
      case "Hypothermia":
        return Colors.blueAccent;
      case "Below Normal":
        return Colors.orangeAccent;
      case "Normal":
        return Colors.green;
      case "Elevated (Monitor)":
        return Colors.deepOrange;
      default:
        return const Color.fromARGB(255, 189, 107, 77); // default color
    }
  }

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: SingleChildScrollView(
          // 👈 Prevent overflow
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.032),
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.032),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back,
                                size: screenWidth * 0.048, color: Colors.black),
                          ),
                          SizedBox(width: screenWidth * 0.018),
                          Text(
                            "TEMPERATURE",
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.044,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.032),
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.032),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.04),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            showError
                                ? Text(
                                    temperature,
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.056,
                                      color: Colors.black,
                                    ),
                                  )
                                : isFetching
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        temperature,
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.056,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            Icon(Icons.thermostat,
                                size: screenWidth * 0.08, color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Gradient Box
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                  padding: EdgeInsets.all(screenWidth * 0.032),
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
                      SizedBox(height: screenHeight * 0.024),
                      _statusCard(
                        secondsRemaining > 0
                            ? "Sensor Stabilizing... ($secondsRemaining s left)"
                            : "Status: $currentTempStatus",
                      ),
                      SizedBox(height: screenHeight * 0.032),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _tempCard("< 95°F", "Too Low"),
                          _tempCard("96.8-98.6°F", "Normal"),
                          _tempCard("≥ 100.4°F", "Fever"),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.032),

                // View Trends Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TempChartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 222, 155, 131),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.048,
                        vertical: screenHeight * 0.02),
                    minimumSize: Size(screenWidth * 0.9, 50), // 👈 Responsive
                  ),
                  child: Text(
                    "View Trends",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.032,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final isStabilizing = text.toLowerCase().contains("stabilizing");
    final Color bgColor =
        isStabilizing ? Colors.brown : _statusColor(currentTempStatus);

    return Container(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.032),
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
            fontSize: screenWidth * 0.032,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Gender, Age, Weight Card
  Widget _infoCard(String value, String label) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Flexible(
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.018, vertical: screenHeight * 0.008),
        padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.024, vertical: screenHeight * 0.024),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 252, 208, 192),
          borderRadius: BorderRadius.circular(screenWidth * 0.032),
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
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            FittedBox(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.028,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Flexible(
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.018, vertical: screenHeight * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.018, vertical: screenHeight * 0.024),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 190, 130, 110),
          borderRadius: BorderRadius.circular(screenWidth * 0.032),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                temp,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            FittedBox(
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.028,
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
