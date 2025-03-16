import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart'; // Import API client
import 'dart:async'; // Import Timer
import 'package:shared_preferences/shared_preferences.dart';

class TemperaturePage extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const TemperaturePage({
    Key? key,
    this.gender,
    this.age,
    this.weight,
  }) : super(key: key);

  @override
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  String temperature = "Loading...";
  bool isFetching = true;
  bool showError = false;
  Timer? dataFetchTimer;
  String gender = "-";
  String age = "-";
  String weight = "-";

  @override
  void initState() {
    super.initState();
    fetchTemperature();

    // Start periodic fetching every second
    dataFetchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchTemperature();
    });

    // Load gender, age, weight (sharedPrefs or passed params)
    _loadUserDetailsOrUseParams();
  }

  /// Fetch latest temperature
  Future<void> fetchTemperature() async {
    try {
      final data = await ApiClient().getSensorData();

      if (data.containsKey("error")) {
        setState(() {
          showError = true;
          temperature = "-";
        });
        return;
      }

      setState(() {
        temperature = "${data['temperature']} °F";
        isFetching = false;
        showError = false;
      });
    } catch (e) {
      print("❌ Failed to fetch temperature: $e");
      setState(() {
        showError = true;
        temperature = "Error";
      });
    }
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

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Section (Title & Back Button)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
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

                    // Temperature Display Box
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
                                  ? const CircularProgressIndicator() // Show loading while fetching
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
              // START OF GRADIENT BOX
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const RadialGradient(
                    colors: [
                      Color.fromARGB(0, 237, 200, 172), // Transparent Brown
                      Color.fromRGBO(235, 196, 176, 1), // Light Brown
                      Color.fromARGB(255, 220, 200, 190), // Dark Brown
                    ],
                    radius: 1.5,
                    center: Alignment(0.7, -0.6),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Gender, Age, Weight Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoCard(gender, "Gender"),
                        _infoCard(age, "Age"),
                        _infoCard(weight, "Weight"),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Bar
                    _statusCard("Status: Normal / Slight Fever"),
                    const SizedBox(height: 16),

                    // Temperature Ranges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _tempCard("36°", "Normal"),
                        _tempCard("37°", "Low-grade"),
                        _tempCard("39°", "Critical"),
                      ],
                    ),
                  ],
                ),
              ),
              // END OF GRADIENT BOX

              const SizedBox(height: 16),

              // View Trends Button (OUTSIDE THE GRADIENT)
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 222, 155, 131),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), // Adjust padding
                  minimumSize: const Size(800, 50), // Adjust width & height
                ),
                child: Text(
                  "View Trends",
                  style: TextStyle(
                    color: Colors.white, // Change this to your desired color
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Temperature Card
  Widget _tempCard(String temp, String status) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 190, 130, 110),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              temp,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
