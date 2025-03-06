import 'package:flutter/material.dart';
import 'wifi_functions.dart'; // Import Wi-Fi Functions
import 'sensor_screen.dart';
import 'welcome_page.dart';
import 'package:permission_handler/permission_handler.dart'; // Required for Wi-Fi Permissions
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SmartShirtScreen(),
    );
  }
}

class SmartShirtScreen extends StatefulWidget {
  const SmartShirtScreen({super.key});

  @override
  _SmartShirtScreenState createState() => _SmartShirtScreenState();
}

class _SmartShirtScreenState extends State<SmartShirtScreen> {
  @override
  void initState() {
    super.initState();
    requestPermissions(); // Request Wi-Fi permissions before scanning
    checkESP32Status();
  }

  /// **Request Location Permissions (Required for Wi-Fi Scanning on Android 10+)**
  Future<void> requestPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }
  
  bool isMonitoringESP = false;  // Ensure only one background check runs

  void checkESP32Status() async {
      if (isMonitoringESP) return;  // Prevent multiple loops
      isMonitoringESP = true;
      
      print("⏳ Monitoring ESP32 connection in the background...");

      Timer.periodic(Duration(seconds: 3), (timer) async { 
          try {
              bool espOnline = await checkESP32Connection(context);
              if (espOnline) { 
                  print("ESP32 is connected! Registering SmartShirt...");
                  await registerSmartShirt(context);

                  // Navigate to Sensor Page if SmartShirt is registered
                  if (context.mounted) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SensorDataScreen()),
                      );
                  }
                  timer.cancel();  // Stop background checking
                  isMonitoringESP = false;
              }
          } catch (e) {
              print("ESP32 not responding, will check again...");
          }
      });
  }
  /// **Open Wi-Fi Settings**
  void openWiFiSettings() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.example.vitalsense/settings');
        await platform.invokeMethod('openWiFiSettings');
      } else if (Platform.isIOS) {
        await launchUrl(Uri.parse('App-Prefs:root=WIFI'));
      } else {
        print("⚠ Wi-Fi settings cannot be opened on this platform.");
      }
    } catch (e) {
      print("Failed to open Wi-Fi settings: $e");
    }
  }

  /// **Show ESP32 Setup Instructions**
  void showSetupInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("ESP32 Connection Help"),
          content: const Text(
              "1️⃣ Open Wi-Fi settings.\n"
              "2️⃣ Connect to 'ESP32_Setup'.\n"
              "3️⃣ When redirected, select your home Wi-Fi and enter the password.\n"
              "4️⃣ After setup, return to the app."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            builder: (context) {
              return Scaffold(
                drawer: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        const DrawerHeader(
                          decoration: BoxDecoration(color: Color.fromARGB(255, 239, 238, 229)),
                          child: Text('Vital Sense'),
                        ),
                        ListTile(
                          title: const Text('Logout'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const WelcomePage()),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                body: Container(
                  width: 400,
                  height: 800,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 239, 238, 229),
                    borderRadius: BorderRadius.circular(45),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 20.0, 15, 0),
                        child: Row(
                          children: [
                            Builder(
                              builder: (BuildContext context) {
                                return IconButton(
                                  icon: const Icon(Icons.menu, color: Colors.black54),
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'ESP32 Not Connected',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '🔹 Go to Wi-Fi settings, connect to *ESP32_Setup*, and return to the app.',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // **Show "Open Wi-Fi Settings" & Help Button when ESP32 is not connected**
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: openWiFiSettings,  // Call the function directly
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Open Wi-Fi Settings'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade200,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
