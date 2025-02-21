// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart'; // Import network info package
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';  

class ConnectWifiScreen extends StatefulWidget {
  const ConnectWifiScreen({Key? key}) : super(key: key);

  @override
  _ConnectWifiScreenState createState() => _ConnectWifiScreenState();
}

class _ConnectWifiScreenState extends State<ConnectWifiScreen> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false; 
  String esp32Ip = "192.168.4.1"; // ESP32 default SoftAP IP

  @override
  void initState() {
    super.initState();
    _getConnectedWifi(); // Auto-detect Wi-Fi
  }

  // Get the currently connected Wi-Fi SSID
  Future<void> _getConnectedWifi() async {
  final info = NetworkInfo();
  String? ssid;

  // Request location permission (needed for Wi-Fi access on Android 10+)
  var status = await Permission.location.request();
  
  if (status.isGranted) {
    if (Platform.isAndroid) {  // Ensure platform check is defined
      ssid = await info.getWifiName();
      ssid = ssid?.replaceAll('"', ''); // Remove unwanted quotes
    } else {
      ssid = "Unsupported Platform";
    }
  } else {
    ssid = "Permission Denied";
  }

  // Detect if running on an emulator
  if (await _isEmulator()) {
    ssid = "Emulator (No Wi-Fi)";
  }

  setState(() {
    ssidController.text = ssid ?? "Unknown";
  });
}

// Helper function to check if running on an emulator
Future<bool> _isEmulator() async {
  final String model = await NetworkInfo().getWifiName() ?? "Unknown";
  return model.contains("generic") || model.contains("sdk_gphone");
}

  // Send Wi-Fi credentials to ESP32
  Future<void> sendWiFiCredentials() async {
    final url = "http://$esp32Ip/configure";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "ssid": ssidController.text, // Auto-detected Wi-Fi
          "password": passwordController.text, // User enters password
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Wi-Fi Credentials Sent! Restart ESP32.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send Wi-Fi credentials.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Unable to reach ESP32. Check connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - 60;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 8, 8),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 412,
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 70.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 30, 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      'Connect WiFi',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Enter password for the detected Wi-Fi",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    // Auto-detected Wi-Fi SSID
                    Container(
                      width: 350,
                      child: TextField(
                        controller: ssidController,
                        enabled: false, // Disable editing (auto-filled)
                        decoration: InputDecoration(
                          hintText: 'Wi-Fi SSID',
                          fillColor: Colors.green.shade200,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wi-Fi Password Input
                    Container(
                      width: 350,
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter Wi-Fi Password',
                          fillColor: Colors.green.shade200,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Connect Button
                    ElevatedButton(
                      onPressed: isLoading ? null : sendWiFiCredentials,
                      child: const Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade200, // Light green button
                        foregroundColor: Colors.black, // Text color
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}