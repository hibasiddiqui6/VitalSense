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

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        bool espOnline = await checkESP32Connection(context);
        if (espOnline) {
          await registerSmartShirt(context);
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PatientDashboard()),
            );
          }
          timer.cancel();
          isMonitoringESP = false;
        }
      } catch (e) {
        print("ESP32 not responding, will retry...");
      }
    });
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
        content: const Text(
            "1️⃣ Open Wi-Fi settings.\n"
            "2️⃣ Connect to 'ESP32_Setup'.\n"
            "3️⃣ Select your home Wi-Fi and enter the password.\n"
            "4️⃣ Return to the app after setup."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: PatientDrawer(fullName: fullName, email: email), // ✅ Integrating Drawer
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 400,
          height: 800,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(45),
            border: Border.all(color: Colors.black, width: 5),
          ),
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                width: 400,
                height: 800,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 193, 219, 188),
                  borderRadius: BorderRadius.circular(45),
                  boxShadow: [BoxShadow(blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Menu Button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black54),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    /// Main Wi-Fi Setup Text & Buttons
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        children: [
                          const Text(
                            'ESP32 Not Connected',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '🔹 Go to Wi-Fi settings, connect to *ESP32_Setup*, and return.',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          /// Open Wi-Fi Button
                          ElevatedButton.icon(
                            onPressed: openWiFiSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Wi-Fi Settings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 241, 201, 141),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          /// Need Help Button
                          ElevatedButton.icon(
                            onPressed: () => showSetupInstructions(context),
                            icon: const Icon(Icons.help_outline),
                            label: const Text('Need Help?'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade200,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
