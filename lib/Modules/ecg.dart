import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart'; // API for fetching ECG data
import 'package:shared_preferences/shared_preferences.dart';

class ECGScreen extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const ECGScreen({super.key, this.gender, this.age, this.weight});

  @override
  _ECGScreenState createState() => _ECGScreenState();
}

class _ECGScreenState extends State<ECGScreen> {
  List<FlSpot> ecgData = [];
  double time = 0;
  ApiClient apiClient = ApiClient();
  Timer? ecgTimer;
  double minY = 0, maxY = 4095; // Default range for 12-bit ADC
  int baseTime = 0; // Base time for X-axis labels

  // Patient details
  String gender = "-";
  String age = "-";
  String weight = "-";

  @override
  void initState() {
    super.initState();
    startECGStreaming();
    _loadUserDetailsOrUseParams(); // Load dynamic patient details
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

  void startECGStreaming() {
    ecgTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        final response = await apiClient.getECGStream(limit: 100);

        if (response.isNotEmpty) {
          print("🔁 Streaming ${response.length} points.");
          print("From: ${response.first["timestamp"]} to ${response.last["timestamp"]}");

          List<FlSpot> newSpots = List.generate(
              response.length,
              (i) => FlSpot(time + (i * 0.1), double.tryParse(response[i]["ecg"].toString()) ?? 0),
            );

            setState(() {
              ecgData.addAll(newSpots);
              if (ecgData.length > 100) {
                ecgData = ecgData.sublist(ecgData.length - 100); // Rolling window
              }
              time = ecgData.last.x + 0.1;
              _updateYAxisRange();
            });

        }
      } catch (e) {
        print("Stream error: $e");
      }
    });
  }

  /// Auto-Adjust Y-Axis based on incoming data
  void _updateYAxisRange() {
    if (ecgData.isNotEmpty) {
      double minVal = ecgData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      double maxVal = ecgData.map((e) => e.y).reduce((a, b) => a > b ? a : b);

      setState(() {
        minY = minVal - 100;
        maxY = maxVal + 100;
      });
    }
  }

  @override
  void dispose() {
    ecgTimer?.cancel(); // Stop timer on dispose
    super.dispose();
  }

  LineChartData _generateChartData() {
    if (ecgData.isEmpty) return LineChartData();

    return LineChartData(
      backgroundColor: Colors.white,
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) / 5,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      minX: ecgData.first.x,
      maxX: ecgData.last.x,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: ecgData,
          isCurved: false,
          color: Colors.green.shade700,
          barWidth: 1.5,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2E6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04, // 4% of width
            vertical: MediaQuery.of(context).size.height * 0.02, // 2% of height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back,
                          size: MediaQuery.of(context).size.width * 0.06,
                          color: Colors.black),
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.02), // 2% of screen width
                    Container(
                      margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width *
                              0.04), // 4% of screen width
                      child: Text(
                        "ECG",
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).size.width *
                              0.05, // 5% of screen width
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ECG Graph Section
              Container(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                child: Column(
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.001),
                    // Inner Box for ECG Graph
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(4, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(-4, -4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.025),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: LineChart(_generateChartData()),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Gender, Age, Weight Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard(gender, "Gender"),
                    _infoCard(age, "Age"),
                    _infoCard(weight, "Weight"),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // View Trends Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width *
                            0.12, // 12% of screen width
                        vertical: MediaQuery.of(context).size.height *
                            0.017), // 1.7% of screen height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "View Trends",
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
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
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width * 0.01), // 1% of screen width
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height *
                0.015), // 1.5% of screen height
        decoration: BoxDecoration(
          color: Colors.white,
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
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    fontWeight: FontWeight.bold)), // 4.5% of screen width
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width *
                        0.04, // 4% of screen width
                    color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
