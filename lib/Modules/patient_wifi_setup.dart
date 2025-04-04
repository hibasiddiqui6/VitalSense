import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wifi_functions.dart'; // Import Wi-Fi Functions
import 'patient_dashboard.dart';
import '../widgets/patient_drawer.dart'; // Import Patient Drawer
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

class PatientWifiSetup extends StatefulWidget {
  const PatientWifiSetup({super.key});

  @override
  _PatientWifiSetupState createState() => _PatientWifiSetupState();
}

class _PatientWifiSetupState extends State<PatientWifiSetup> {
  bool isMonitoringESP = false;
  String fullName = "Loading...";
  String email = "Loading...";

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _loadUserDetails();
    checkESP32Status();
    fetchUserProfile();
  }

  /// Fetch user profile data
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
          email = data["email"] ?? "-";
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("full_name", fullName);
        await prefs.setString("email", email);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// Load user details for Drawer
  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
    });
  }

  /// Request Location Permissions (Required for Wi-Fi Scanning on Android 10+)
  Future<void> requestPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  /// Monitor ESP32 connection
  void checkESP32Status() async {
    if (isMonitoringESP) return;
    isMonitoringESP = true;

    final maxWait = Duration(minutes: 10);
    final startTime = DateTime.now();

    while (true) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > maxWait) {
        print("⏱ Timed out waiting for ESP32 connection after ${elapsed.inSeconds} seconds.");
        isMonitoringESP = false;
        return;
      }

      try {
        print("🔄 Checking if ESP32 is already connected...");
        final connected = await checkESP32Connection(context); 
        if (connected) {
          print("✅ ESP32 online! Registering SmartShirt...");
          await registerSmartShirt(context);

          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PatientDashboard()),
            );
          }
          isMonitoringESP = false;
          return;
        }
      } catch (e) {
        print("❌ ESP32 not responding: $e");
      }

      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Open Wi-Fi Settings
  void openWiFiSettings() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.example.vitalsense/settings');
        await platform.invokeMethod('openWiFiSettings');
      } else if (Platform.isIOS) {
        await launchUrl(Uri.parse('App-Prefs:root=WIFI'));
      }
    } catch (e) {
      print("Failed to open Wi-Fi settings: $e");
    }
  }

  /// Show Setup Help Dialog
  void showSetupInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ESP32 Connection Help"),
        content: const Text("1️⃣ Open Wi-Fi settings.\n"
            "2️⃣ Connect to 'ESP32_Setup'.\n"
            "3️⃣ Select your home Wi-Fi and enter the password.\n"
            "4️⃣ Return to the app after setup. You will be navigated to the dashboard shortly."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      drawer: PatientDrawer(
          fullName: fullName, email: email), // Correct drawer attached
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: screenWidth, // 90% of screen width
          height: screenHeight, // 90% of screen height
          padding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width * 0.05, // 5% of screen width
            vertical: MediaQuery.of(context).size.height *
                0.025, // 2.5% of screen height
          ),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 223, 231, 221),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Menu Button
              Row(
                children: [
                  Builder(
                    // Needed to get proper context to open Drawer
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu,
                          size: screenWidth * 0.08, color: Colors.black54),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05),

              /// Main Wi-Fi Setup Text & Buttons
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.12),
                child: Column(
                  children: [
                    Text(
                      'ESP32 Not Connected',
                      style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      '🔹 Go to Wi-Fi settings, connect to *ESP32_Setup*, and return.',
                      style: TextStyle(
                          fontSize: screenWidth * 0.04, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    /// Open Wi-Fi Button
                    ElevatedButton.icon(
                      onPressed: openWiFiSettings,
                      icon: Icon(Icons.settings, size: screenWidth * 0.08),
                      label: Text(
                        'Open Wi-Fi Settings',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width *
                              0.045, // 4.5% of screen width
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 241, 201, 141),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width *
                              0.05, // 5% of screen width
                          vertical: MediaQuery.of(context).size.height *
                              0.012, // 1.2% of screen height
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width *
                                0.05, // 5% of screen width
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.012, // 1.2% of screen height
                    ),

                    /// Need Help Button
                    ElevatedButton.icon(
                      onPressed: () => showSetupInstructions(context),
                      icon: Icon(Icons.help_outline, size: screenWidth * 0.08),
                      label: Text('Need Help?',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width *
                              0.045, // 4.5% of screen width
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade200,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width *
                              0.05, // 5% of screen width
                          vertical: MediaQuery.of(context).size.height *
                              0.015, // 1.5% of screen height
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width *
                                0.05, // 5% of screen width
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
