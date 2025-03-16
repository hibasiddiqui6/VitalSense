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

  /// **Fetch real-time ECG data every 2ms**
  void startECGStreaming() {
    ecgTimer = Timer.periodic(const Duration(milliseconds: 2), (timer) async {
      try {
        var response = await apiClient.getSensorData(); // Fetch ECG data

        if (response != null && response.containsKey("ecg")) {
          double rawADC = double.tryParse(response["ecg"].toString()) ?? 0;

          setState(() {
            if (ecgData.length > 100) ecgData.removeAt(0); // Keep last 100 points
            ecgData.add(FlSpot(time, rawADC));
            time += 0.1; // Increment time
            baseTime = time.toInt() - (time.toInt() % 12); // Dynamic X-axis base
            _updateYAxisRange(); // Auto-scale Y-axis
          });
        }
      } catch (e) {
        print("Error fetching ECG data: $e");
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

    /// **Generate ECG Chart Data (Fix X-axis Overlapping)**
  LineChartData _generateChartData() {
    if (ecgData.isEmpty) return LineChartData();

    // Get the base time for dynamic updating
    int dynamicBaseTime = baseTime;

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY - minY) / 5, // Auto-scale Y-axis
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 12, // Keep labels at fixed positions
            reservedSize: 20,
            getTitlesWidget: (value, meta) {
              int updatedValue = dynamicBaseTime + (value.toInt()); // Update dynamically
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  updatedValue.toString(), 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black, width: 1), // Y-axis
          bottom: BorderSide(color: Colors.black, width: 1), // X-axis
        ),
      ),
      minX: ecgData.first.x, // Keep graph aligned with incoming data
      maxX: ecgData.last.x, // Show only relevant data in real-time
      minY: minY,
      maxY: maxY, // Auto-scaled Y-axis
      lineBarsData: [
        LineChartBarData(
          spots: ecgData.map((point) => FlSpot(point.x, point.y)).toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 2,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: Text(
                        "ECG",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ECG Graph Section
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 200, 215, 160),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const SizedBox(height: 1),
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
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        height: 200,
                        width: 350,
                        child: LineChart(_generateChartData()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              // View Trends Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "View Trends",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
