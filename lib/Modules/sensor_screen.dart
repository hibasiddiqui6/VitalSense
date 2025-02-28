import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../services/api_client.dart';
import 'welcome_page.dart';

class SensorDataScreen extends StatefulWidget {
  const SensorDataScreen({super.key});

  @override
  _SensorDataScreenState createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  String ecg = "N/A";
  String respiration = "N/A";
  String temperature = "N/A";
  bool isFetching = true;
  bool showNoReadings = false;
  bool showReconnecting = false;
  bool finalMessageShown = false;
  Timer? disconnectionTimer;
  Timer? dataFetchTimer;

  /// **Fetch sensor data from Flask server**
  Future<void> fetchSensorData() async {
    final String flaskEndpoint = "${ApiClient.baseUrl}/get_sensor";

    try {
      final response = await http.get(Uri.parse(flaskEndpoint)).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey("error")) {
          print("⚠ No sensor data available.");
          setState(() {
            showNoReadings = true;
            showReconnecting = false;
            finalMessageShown = false;
          });
          return;
        }

        if (mounted) {
          setState(() {
            ecg = data['ecg'].toString();
            respiration = data['respiration'].toString();
            temperature = data['temperature'].toString();
            isFetching = false;
            showNoReadings = false;
            showReconnecting = false;
            finalMessageShown = false;
          });
        }

        // Reset the disconnection timer when new data is received
        disconnectionTimer?.cancel();
        disconnectionTimer = Timer(const Duration(seconds: 10), _handleDataFetchFailure);
      } else {
        _handleDataFetchFailure();
      }
    } catch (e) {
      print("❌ Failed to fetch sensor data: $e");
      _handleDataFetchFailure();
    }
  }

  /// **Handle data fetch failure with smooth transition**
  void _handleDataFetchFailure() {
    if (mounted && !finalMessageShown) {
      setState(() {
        isFetching = false;
        showNoReadings = true;
      });

      // **After 3 seconds, show "Reconnecting..."**
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !finalMessageShown) {
          setState(() {
            showReconnecting = true;
          });

          // **After another 5 seconds, show the final message**
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                showReconnecting = false;
                finalMessageShown = true;  // Prevent further updates
              });
            }
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // **Start continuous data fetching**
    dataFetchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchSensorData();
    });

    // **Start the disconnection timeout**
    disconnectionTimer = Timer(const Duration(seconds: 10), _handleDataFetchFailure);
  }

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    disconnectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ClipRRect(
        borderRadius: BorderRadius.circular(45),
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 206, 226, 206),
                ),
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
      appBar: AppBar(
        title: const Text("Sensor Readings"),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black54),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: Center(
        child: isFetching
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Fetching sensor data..."),
                ],
              )
            : showNoReadings
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "No readings to display!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (showReconnecting)
                        Column(
                          children: [
                            CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            const Text("Reconnecting...", style: TextStyle(fontSize: 16)),
                          ],
                        )
                      else if (finalMessageShown)
                        const Text(
                          "Check if your ESP32 is active.",
                          style: TextStyle(fontSize: 16),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("ECG: $ecg"),
                      Text("Respiration: $respiration BPM"),
                      Text("Temperature: $temperature °F"),
                    ],
                  ),
      ),
    );
  }
}
