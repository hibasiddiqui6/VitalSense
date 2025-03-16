import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'patient_dashboard.dart';
import '../services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Check if ESP32 is already connected to Home Wi-Fi**
Future<bool> checkESP32Connection(BuildContext context) async {
    print("Checking if ESP32 is already connected...");

    int attempts = 5; // Retry up to 5 times
    while (attempts-- > 0) {
        try {
            final response = await http.get(Uri.parse("${ApiClient.baseUrl}/get_sensor"))
                .timeout(const Duration(seconds: 3));

            if (response.statusCode == 200) {
                final Map<String, dynamic> sensorData = json.decode(response.body);

                if (sensorData.isNotEmpty) {
                    print("ESP32 is online and sending data!");

                    return true; // Successfully connected
                }
            }
        } catch (e) {
            print("Attempt ${5 - attempts}: ESP32 not responding. Retrying...");
        }

        await Future.delayed(const Duration(seconds: 2)); // Wait before retrying
    }

    print("ESP32 did not respond after multiple attempts. Checking if ESP32 SoftAP exists...");

    // **Check if ESP32 SoftAP is available**
    String? currentSSID = await WiFiForIoTPlugin.getSSID();
    if (currentSSID == "ESP32_Setup") {
        print("ESP32 SoftAP detected. Prompting user...");
        return false; // Not connected, but SoftAP exists
    } else {
        print("ESP32 SoftAP not found.");
        return false; // Neither connected nor SoftAP available
    }
}

/// **Connects to ESP32 SoftAP and handles Wi-Fi provisioning**
Future<void> connectToESP32WiFi(BuildContext context) async {
    print("Connecting to ESP32_Setup Wi-Fi...");

    // **Check if already connected**
    String? currentSSID = await WiFiForIoTPlugin.getSSID();
    if (currentSSID == "ESP32_Setup") {
        print("Already connected to ESP32_Setup. Proceeding...");
        proceedToProvisioning(context);
        return;
    }

    bool connected = await WiFiForIoTPlugin.connect(
        "ESP32_Setup",
        security: NetworkSecurity.WPA,
        password: "12345678",
        isHidden: false,
        withInternet: false,
        timeoutInSeconds: 15,
    );

    if (connected) {
        print("Successfully connected to ESP32 Wi-Fi!");

        // Force Wi-Fi usage to avoid switching back to mobile data
        await WiFiForIoTPlugin.forceWifiUsage(true);

        // Proceed to provisioning screen
        proceedToProvisioning(context);
    } else {
        print("Failed to connect to ESP32 Wi-Fi. Retrying...");
        await Future.delayed(const Duration(seconds: 5));  // Small delay before retrying
        connectToESP32WiFi(context);  // Recursive retry
    }
}

/// **Handles Provisioning Process and Monitors for Wi-Fi Switch**
void proceedToProvisioning(BuildContext context) async {
    Uri provisionerUri = Uri.parse("http://192.168.0.51");

    if (await canLaunchUrl(provisionerUri)) {
        await launchUrl(provisionerUri, mode: LaunchMode.externalApplication);
    } else {
        print("Could not open provisioning page");
    }

    // Monitor for reconnection to home Wi-Fi
    Timer.periodic(const Duration(seconds: 5), (timer) async {
        String? currentSSID = await WiFiForIoTPlugin.getSSID();
        print("Checking Wi-Fi: Currently connected to: $currentSSID");

        if (currentSSID != null && currentSSID != "ESP32_Setup") {
            timer.cancel();
            print("Switched back to home Wi-Fi: $currentSSID");

            // Resume normal internet usage
            await WiFiForIoTPlugin.forceWifiUsage(false);

            // Notify patient landing page
            if (context.mounted) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PatientDashboard()),
                );
            }
        }
    });
}
Future<String?> fetchESP32MacAddress() async {
    const String esp32Ip = "http://192.168.0.51/get_mac_address";
    int attempts = 5; // 🔼 Increased retry attempts from 3 to 5

    for (int i = 0; i < attempts; i++) {
        try {
            final response = await http.get(Uri.parse(esp32Ip)).timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
                return json.decode(response.body)["mac_address"];
            }
        } catch (e) {
            print("Failed to fetch ESP32 MAC Address. Retrying... (${i + 1}/5)");
            await Future.delayed(Duration(seconds: 3));
        }
    }

    print("Failed to retrieve MAC Address after multiple attempts.");
    return null;
}

/// **Check and Register ESP32 with Flask**
Future<void> registerSmartShirt(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");
    SharedPreferences eprefs = await SharedPreferences.getInstance();
    String? email = eprefs.getString("email");

    // 🔹 If patient ID is missing, try fetching it again
    if (patientId == null || patientId.isEmpty) {
        print("⚠ No patient ID found. Trying to fetch again...");

        if (email == null || email.isEmpty) {
            print("⚠ No email found in SharedPreferences. Cannot fetch patient ID.");
            return; // Exit function to prevent error
        }

        await ApiClient.fetchAndSavePatientId(email);
        patientId = prefs.getString("patient_id"); // Re-fetch after updating
    }

    // 🔹 If still null, stop execution
    if (patientId == null || patientId.isEmpty) {
        print("❌ No patient ID found even after fetching. Cannot register SmartShirt.");
        return;
    }

    print("Fetching ESP32 MAC Address...");
    String? macAddress = await fetchESP32MacAddress();

    if (macAddress == null) {
        print("❌ Could not retrieve MAC Address.");
        return;
    }

    // **Check if SmartShirt is already registered**
    final checkUrl = Uri.parse("${ApiClient.baseUrl}/check_smartshirt?mac_address=$macAddress");
    final checkResponse = await http.get(checkUrl).timeout(const Duration(seconds: 3));

    if (checkResponse.statusCode == 200 && json.decode(checkResponse.body)["exists"] == true) {
        print("✅ SmartShirt already registered! Navigating to Sensor Page.");

        if (context.mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PatientDashboard()),
            );
        }
        return;
    }

    // **Register SmartShirt**
    final registerUrl = Uri.parse("${ApiClient.baseUrl}/register_mac");
    final data = jsonEncode({"mac_address": macAddress, "patient_id": patientId});

    final registerResponse = await http.post(
        registerUrl,
        headers: {"Content-Type": "application/json"},
        body: data,
    ).timeout(const Duration(seconds: 5));

    if (registerResponse.statusCode == 201 || registerResponse.statusCode == 200) {
        print("✅ SmartShirt registered successfully! Navigating to Sensor Page.");
        
        if (context.mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PatientDashboard()),
            );
        }
    } else {
        print("❌ Failed to register SmartShirt: ${registerResponse.body}");
    }

}