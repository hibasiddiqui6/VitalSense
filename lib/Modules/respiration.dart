import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Timer? dataFetchTimer;
  DateTime? startTime;
  DateTime? lastSuccessfulFetch;
  DateTime? lastRespFetch;
  double? lastValidResp;
  int secondsRemaining = 30;
  bool hasStabilized = false;
  bool hasShownAlert = false; 

  @override
  void initState() {
    super.initState();
    instance = this;
    _loadUserDetailsOrUseParams();
    _loadStabilizationTime();
    _startRespirationFetchingLoop();
    _loadUserRole();
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

  Future<void> _loadStabilizationTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("resp_stabilization_start_time")) {
      final millis = prefs.getInt("resp_stabilization_start_time")!;
      final savedTime = DateTime.fromMillisecondsSinceEpoch(millis);
      final diff = DateTime.now().difference(savedTime).inSeconds;

      if (diff >= 30) {
        setState(() {
          hasStabilized = true;
          startTime = savedTime;
          secondsRemaining = 0;
        });
      } else {
        setState(() {
          hasStabilized = false;
          startTime = savedTime;
          secondsRemaining = 30 - diff;
        });
      }
    } else {
      final now = DateTime.now();
      await prefs.setInt("resp_stabilization_start_time", now.millisecondsSinceEpoch);
      setState(() {
        startTime = now;
      });
    }
  }

  void _startRespirationFetchingLoop() {
    dataFetchTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      await fetchRespirationRate();

      // ⏱ Inactivity check (5 min gap)
      if (lastRespFetch != null &&
          DateTime.now().difference(lastRespFetch!).inSeconds > 300) {
        setState(() {
          hasStabilized = false;
          hasShownAlert = false;
          secondsRemaining = 30;
          startTime = DateTime.now();
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("resp_stabilization_start_time", DateTime.now().millisecondsSinceEpoch);
      }

      if (!hasStabilized && startTime != null) {
        final diff = DateTime.now().difference(startTime!).inSeconds;
        if (diff >= 30) {
          setState(() {
            hasStabilized = true;
            secondsRemaining = 0;
          });
        } else {
          setState(() {
            secondsRemaining = 30 - diff;
          });
        }
      }
    });
  }

  void updateFromRealtime(double tempVal) {
    final formatted = "${tempVal.toStringAsFixed(1)} °F";
    final now = DateTime.now();

    lastValidResp = tempVal;
    lastSuccessfulFetch = now;
    lastRespFetch = now;

    setState(() {
      respirationRate = formatted;
      respirationStatus = hasStabilized ? "Stable" : "Stabilizing...";
      isFetching = false;
      showError = false;
    });
  }

  Future<void> fetchRespirationRate() async {
    try {
      final now = DateTime.now();
      lastRespFetch = now;

      final data = await ApiClient().getSensorData();
      final rawResp = double.tryParse(data['respiration_rate'].toString()) ?? 0.0;

      if (rawResp == 0.0) {
        if (lastSuccessfulFetch != null &&
            now.difference(lastSuccessfulFetch!).inSeconds <= 60 &&
            lastValidResp != null) {
          setState(() {
            respirationRate = "${lastValidResp!.toStringAsFixed(1)} BPM";
            respirationStatus = hasStabilized ? respirationStatus : "Stabilizing...";
            isFetching = false;
            showError = false;
          });
          return;
        } else {
          setState(() {
            showError = true;
            respirationRate = "-";
            respirationStatus = "Sensor Error";
          });
          return;
        }
      }

      lastSuccessfulFetch = now;
      lastValidResp = rawResp;
      final classification = await ApiClient().classifyRespiration(rawResp);
      final status = classification['status'] ?? "Unknown";
      final disease = classification['disease'];

      // 🚨 Trigger alert if needed
      if (disease != null && !hasShownAlert && hasStabilized) {
        _showAlertNotification(context, disease);
        hasShownAlert = true;
      }

      setState(() {
        respirationRate = "${rawResp.toStringAsFixed(1)} BPM";
        respirationStatus = hasStabilized ? status : "Stabilizing...";
        isFetching = false;
        showError = false;
      });
    } catch (e) {
      print("❌ Failed to fetch respiration rate: $e");

      final now = DateTime.now();
      if (lastSuccessfulFetch != null &&
          now.difference(lastSuccessfulFetch!).inSeconds <= 60 &&
          lastValidResp != null) {
        setState(() {
          respirationRate = "${lastValidResp!.toStringAsFixed(1)} BPM";
          respirationStatus = hasStabilized ? respirationStatus : "Stabilizing...";
          isFetching = false;
          showError = false;
        });
        return;
      }

      setState(() {
        showError = true;
        respirationRate = "Error";
        respirationStatus = "Unknown";
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
                print("✅ Contacts fetched: $contactsList");

                await notifyContacts(disease, contactsList);
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

  @override
  void dispose() {
    instance = null;
    dataFetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                  color: Colors.brown[300],
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Center(
                  child: Text(
                    secondsRemaining > 0
                        ? "Sensor Stabilizing... ($secondsRemaining s left)"
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
