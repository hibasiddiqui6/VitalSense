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

  final fetchIpUrl = Uri.parse("${ApiClient.baseUrl}/get_latest_mac_ip");

  try {
    final latest = await http.get(fetchIpUrl).timeout(const Duration(seconds: 3));
    if (latest.statusCode == 200) {
      final data = json.decode(latest.body);
      final ip = data["ip_address"];
      final pingUrl = Uri.parse("http://$ip/ping");

      for (int i = 0; i < 5; i++) {
        try {
          final resp = await http.get(pingUrl).timeout(const Duration(seconds: 2));
          if (resp.statusCode == 200) {
            print("✅ ESP responded to /ping");
            return true;
          }
        } catch (e) {
          print("Attempt ${i + 1}: Ping failed. Retrying...");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    } else {
      print("Failed to fetch IP from backend. Status: ${latest.statusCode}");
    }
  } catch (e) {
    print("❌ Ping check failed: $e");
  }

  // Fallback: check if we're connected to ESP32_Setup
  final currentSSID = await WiFiForIoTPlugin.getSSID();
  if (currentSSID == "ESP32_Setup") {
    print("ESP32 SoftAP detected. Provisioning likely needed.");
    return false;
  }

  print("ESP32 is not connected and SoftAP not found.");
  return false;
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
  final Uri fetchIpUri = Uri.parse("${ApiClient.baseUrl}/get_latest_mac_ip");

  try {
    final response = await http.get(fetchIpUri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String ip = data["ip_address"];
      Uri provisionerUri = Uri.parse("http://$ip");

      if (await canLaunchUrl(provisionerUri)) {
        await launchUrl(provisionerUri, mode: LaunchMode.externalApplication);
      } else {
        print("Could not open provisioning page at $ip");
      }
    } else {
      print("Failed to get ESP32 IP from backend. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching dynamic IP from backend: $e");
    return;
  }

  // Monitor for reconnection to home Wi-Fi
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    String? currentSSID = await WiFiForIoTPlugin.getSSID();
    print("Checking Wi-Fi: Currently connected to: $currentSSID");

    if (currentSSID != null && currentSSID != "ESP32_Setup") {
      timer.cancel();
      print("Switched back to home Wi-Fi: $currentSSID");

      await WiFiForIoTPlugin.forceWifiUsage(false);

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
  final url = Uri.parse("${ApiClient.baseUrl}/get_latest_mac_ip");

  try {
    // Step 1: Ask backend for latest known ESP32 IP & MAC
    final response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String ip = data["ip_address"];

      // Step 2: Ask ESP32 directly for MAC to confirm it's alive
      final espResponse = await http
          .get(Uri.parse("http://$ip/get_mac_address"))
          .timeout(const Duration(seconds: 3));

      if (espResponse.statusCode == 200) {
        return json.decode(espResponse.body)["mac_address"];
      }
    }
  } catch (e) {
    print("Failed to fetch MAC via backend dynamic IP: $e");
  }

  print("Failed to retrieve MAC Address after trying backend + ESP32.");
  return null;
}


/// **Check and Register ESP32 with Flask**
Future<void> registerSmartShirt(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  String? patientId = prefs.getString("patient_id");
  String? email = prefs.getString("email");

  // 🔹 Fallback: fetch patient ID if missing
  if ((patientId == null || patientId.isEmpty) && email != null) {
    await ApiClient.fetchAndSavePatientId(email);
    patientId = prefs.getString("patient_id");
  }

  if (patientId == null || patientId.isEmpty) {
    print("❌ No patient ID available.");
    return;
  }

  print("Fetching ESP32 MAC Address...");
  final macAddress = await fetchESP32MacAddress();

  if (macAddress == null) {
    print("❌ Could not fetch MAC address.");
    return;
  }

  // 🔹 Check and register via ApiClient
  final check = await ApiClient().checkSmartShirt(macAddress);
  if (check["exists"] == true) {
    print("✅ SmartShirt already registered.");
  } else {
    final register = await ApiClient().registerSmartShirt(macAddress, patientId);
    print("Register API response: $register");
    if (register.containsKey("error")) {
      print("❌ Register failed: ${register['error']}");
      return;
    }
    print("✅ SmartShirt registered successfully.");
  }

  // ✅ Proceed to dashboard
  if (context.mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PatientDashboard()),
    );
  }
}
