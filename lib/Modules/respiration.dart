import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alert.dart';
import 'respiration_trends.dart';
import 'dart:async';

class RespirationPage extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const RespirationPage({
    super.key,
    this.gender,
    this.age,
    this.weight,
  });

  @override
  _RespirationPageState createState() => _RespirationPageState();
}

class _RespirationPageState extends State<RespirationPage> {
  String respirationRate = "Loading...";
  String currentStatus = "Loading...";
  bool isFetching = true;
  bool showError = false;
  String gender = "-";
  String age = "-";
  String weight = "-";
  Timer? dataFetchTimer;
  DateTime? lastRespFetch;
  bool hasShownAlert = false;

  @override
  void initState() {
    super.initState();
    _startRespirationFetchingLoop();
    _loadUserDetailsOrUseParams();
  }

  void _startRespirationFetchingLoop() {
    dataFetchTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await fetchRespirationRate();
    });
  }

  Future<void> fetchRespirationRate() async {
    try {
      final now = DateTime.now();
      final data = await ApiClient().getSensorData();

      if (data.containsKey("error") || data['respiration'] == null) {
        setState(() {
          showError = true;
          respirationRate = "-";
          currentStatus = "Sensor Error";
        });
        return;
      }

      lastRespFetch = now;
      final rawRate = double.tryParse(data['respiration'].toString()) ?? 0.0;
      final formatted = "${rawRate.toStringAsFixed(0)} BPM";

      final classification = await ApiClient().classifyRespiration(rawRate);
      final newStatus = classification['status'] ?? "Unknown";
      final disease = classification['disease'];

      if (disease != null && !hasShownAlert) {
        _showAlertNotification(disease);
        hasShownAlert = true;
      }

      setState(() {
        respirationRate = formatted;
        currentStatus = newStatus;
        isFetching = false;
        showError = false;
      });
    } catch (e) {
      setState(() {
        showError = true;
        respirationRate = "Error";
        currentStatus = "Unknown";
      });
    }
  }

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

  void _showAlertNotification(String disease) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Health Alert"),
        content: Text("Abnormal respiration detected: $disease.\nNotifying trusted contacts."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final contacts = await ApiClient().getTrustedContacts();
              await notifyContacts(disease, contacts);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    dataFetchTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Rapid": return Colors.redAccent;
      case "Slow": return Colors.orangeAccent;
      case "Normal": return Colors.green;
      default: return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, size: screenWidth * 0.06, color: Colors.black)),
                    const SizedBox(width: 8),
                    Text("RESPIRATION", style: GoogleFonts.poppins(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF968573), Color(0xFFC9C0B7)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: screenHeight * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        showError
                            ? Text(respirationRate, style: GoogleFonts.poppins(fontSize: 28, color: Colors.black))
                            : isFetching
                                ? const CircularProgressIndicator()
                                : Text(respirationRate, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold)),
                        Icon(Icons.air, size: 48, color: Colors.grey[700]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _statusCard(currentStatus),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoCard(gender, "Gender"),
                    _infoCard(age, "Age"),
                    _infoCard(weight, "Weight"),
                  ],
                ),
                const SizedBox(height: 20),
                _statusText("Normal:", "12-20 BPM"),
                _statusText("Slow:", "< 12 BPM"),
                _statusText("Rapid:", "> 20 BPM"),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const RespirationChartScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    ),
                    child: const Text("View Trends", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _statusColor(text),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Text("Status: $text", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _infoCard(String value, String label) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            FittedBox(child: Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            FittedBox(child: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]))),
          ],
        ),
      ),
    );
  }

  Widget _statusText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: RichText(
        text: TextSpan(
          text: "$title ",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
