import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

void main() {
  runApp(const MyApp());
}

/// Main Application Entry Point
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const PatientReport(),
    );
  }
}

/// Health Alert Report Screen
class PatientReport extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const PatientReport({super.key, this.reportData});

  @override
  PatientReportState createState() => PatientReportState();
}


class PatientReportState extends State<PatientReport> {
  static PatientReportState? instance;

  String patientId = "-";
  String fullName = "...";
  String age = "...";
  String gender = "-";
  String weight = "...";
  String condition = "-";
  String date = "-";
  String time = "-";
  String severity = "-";
  String arrhythmiaStatus = "-";
  String bpm = "-";
  String respirationRate = "-";
  String respirationCondition = "-";
  String temperature = "-";
  String temperatureCondition = "-";
  String recommendation = "-";

  void _handleMenuAction(String action) async {
    switch (action) {
      case "Download":
        final id = widget.reportData?["report_id"];
        if (id != null) {
          final url = "https://vitalsense-flask-backend.fly.dev/download_report/$id";
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            Fluttertoast.showToast(msg: "❌ Could not generate PDF. Try again later.");
          }
        } else {
          _showToast("❌ Report ID not found");
        }
        break;
      case "Delete":
        _showToast("Report Deleted");
        break;
      case "Share":
        _showToast("Sharing Report...");
        break;
    }
  }

  @override
    void initState() {
      super.initState();
      instance = this;

      if (widget.reportData != null) {
        final r = widget.reportData!;
        setState(() {
          fullName = r["full_name"] ?? "...";
          gender = r["gender"] ?? "-";
          age = r["age"]?.toString() ?? "-";
          weight = r["weight"]?.toString() ?? "-";
          bpm = r["avg_bpm"]?.toString() ?? "-";
          temperature = r["avg_temp"]?.toString() ?? "-";
          respirationRate = r["avg_resp"]?.toString() ?? "-";
          temperatureCondition = r["temp_status"] ?? "-";
          respirationCondition = r["resp_status"] ?? "-";
          arrhythmiaStatus = r["ecg_status"] ?? "-";
          severity = r["severity"] ?? "-";
          recommendation = r["recommendation"] ?? "-";
          date = r["date"] ?? "-";
          time = r["time"] ?? "-";
        });
      } else {
        fetchUserProfile(); // fallback for older flow
        _loadUserDetails();
      }
    }


  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color.fromARGB(255, 207, 212, 216),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getPatientProfile();

      if (data.containsKey("error")) {
        print("⚠ Error fetching user profile: ${data['error']}");
        return;
      }

      if (mounted) {
        setState(() {
          fullName = data["fullname"] ?? "Unknown User";
          gender = data["gender"] ?? "-";
          age = data["age"]?.toString() ?? "-";
          weight = data["weight"]?.toString() ?? "-";
        });
        // **Save to SharedPreferences for Drawer Use**
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("full_name", fullName);
        await prefs.setString("gender", gender);
        await prefs.setString("age", age);
        await prefs.setString("weight", weight);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// **Load Details from SharedPreferences**
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
    });
    setState(() {
      gender = prefs.getString("gender") ?? "-";
    });
    setState(() {
      age = prefs.getString("age") ?? "-";
    });
    setState(() {
      weight = prefs.getString("weight") ?? "-";
    });
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: _handleMenuAction,
          itemBuilder: (BuildContext context) {
            return const [
              PopupMenuItem(value: "Download", child: Text("Download")),
              PopupMenuItem(value: "Delete", child: Text("Delete")),
              PopupMenuItem(value: "Share", child: Text("Share")),
            ];
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.032),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Health Alert Report",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            HeaderCard(
              fullName: fullName,
              age: age,
              gender: gender,
              weight: weight,
            ),
            SizedBox(height: screenHeight * 0.02),
            ConditionDetected(condition: condition),
            SizedBox(height: screenHeight * 0.02),
            SeveritySection(date: date, time: time, severity: severity),
            SizedBox(height: screenHeight * 0.02),
            Summary(arrhythmiaStatus: arrhythmiaStatus, bpm: bpm),
            SizedBox(height: screenHeight * 0.02),
            ECGInterpretation(
              arrhythmiaStatus: arrhythmiaStatus,
              bpm: bpm,
            ),
            SizedBox(height: screenHeight * 0.02),
            Respiration(
              respirationRate: respirationRate,
              respirationCondition: respirationCondition,
            ),
            SizedBox(height: screenHeight * 0.02),
            Temperature(
              temperature: temperature,
              temperatureCondition: temperatureCondition,
            ),
            SizedBox(height: screenHeight * 0.02),
            Recommendation(recommendation: recommendation),
          ],
        ),
      ),
    );
  }
}

class HeaderCard extends StatelessWidget {
  final String fullName;
  final String age;
  final String gender;
  final String weight;

  const HeaderCard({
    super.key,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, "PATIENT NAME", fullName),
          _infoRow(context, "AGE", age),
          _infoRow(context, "GENDER", gender),
          _infoRow(context, "Weight", weight),
        ],
      ),
    );
  }
}

class ConditionDetected extends StatelessWidget {
  final String condition;

  const ConditionDetected({required this.condition, super.key});

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detected Condition"),
          Text(condition),
        ],
      ),
    );
  }
}

class SeveritySection extends StatelessWidget {
  final String severity;
  final String date;
  final String time;

  const SeveritySection({
    required this.severity,
    required this.date,
    required this.time,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Severity", style: TextStyle(fontWeight: FontWeight.bold)),
          _infoRow(
            context,
            "Severity Level: $severity",
            "\nDate: $date\nTime: $time",
          ),
        ],
      ),
    );
  }
}

class Summary extends StatelessWidget {
  final String arrhythmiaStatus;
  final String bpm;

  const Summary({
    required this.arrhythmiaStatus,
    required this.bpm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Arrhythmia", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Normal", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("130 BPM", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class ECGInterpretation extends StatelessWidget {
  final String arrhythmiaStatus;
  final String bpm;

  const ECGInterpretation({
    required this.arrhythmiaStatus,
    required this.bpm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ECG Interpretation",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          _infoRow(context, "Rate", ""),
          _infoRow(context, "Rhythm", ""),
          _infoRow(context, "Axis", ""),
          _infoRow(context, "PR Interval", ""),
          _infoRow(context, "QRS Complex", ""),
          _infoRow(context, "QT Interval", ""),
        ],
      ),
    );
  }
}

class Respiration extends StatelessWidget {
  final String respirationRate;
  final String respirationCondition;

  const Respiration({
    required this.respirationRate,
    required this.respirationCondition,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Respiration",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          _infoRow(context, "$respirationRate breaths/min\n",
              respirationCondition),
        ],
      ),
    );
  }
}

class Temperature extends StatelessWidget {
  final String temperature;
  final String temperatureCondition;

  const Temperature({
    required this.temperature,
    required this.temperatureCondition,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    //final double screenHeight = MediaQuery.of(context).size.height;
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TEMPERATURE",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: screenWidth * 0.032)),
          const Divider(),
          _infoRow(context, temperature, temperatureCondition),
          _infoRow(context, "Condition", "Normal"),
        ],
      ),
    );
  }
}

class Recommendation extends StatelessWidget {
  final String recommendation;

  const Recommendation({required this.recommendation, super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return _buildCard(
      context,
      color: Colors.red[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("RECOMMENDATION",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: screenWidth * 0.032)),
          Divider(),
          Text("Consult your Doctor Immediately!",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          SizedBox(height: 5),
          Text("Dear User, avoid any physical exertion and stay calm."),
        ],
      ),
    );
  }
}

Widget _infoRow(BuildContext context, String title, String value) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  return Padding(
    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(value, style: TextStyle(fontSize: screenWidth * 0.028)),
      ],
    ),
  );
}

Widget _buildCard(BuildContext context, {required Widget child, Color? color}) {
  double screenWidth = MediaQuery.of(context).size.width;
  double padding = screenWidth * 0.04; // Adjust padding for responsiveness

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.02)),
    color: color ?? Colors.white,
    child: Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    ),
  );
}
