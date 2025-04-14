import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}
final GlobalKey reportKey = GlobalKey();

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

/// Health Report Screen
class PatientReport extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const PatientReport({super.key, this.reportData});

  @override
  PatientReportState createState() => PatientReportState();
}

class PatientReportState extends State<PatientReport> {

  String patientId = "-";
  String fullName = "...";
  String age = "...";
  String gender = "-";
  String weight = "...";
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
  Map<String, dynamic> tempRecommendation = {};
  Map<String, dynamic> respRecommendation = {};
  Map<String, dynamic> ecgRecommendation = {};

  void _handleMenuAction(String action) async {
    switch (action) {
      case "Download":
        try {
          RenderRepaintBoundary boundary = reportKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          ui.Image image = await boundary.toImage(pixelRatio: 3.5);
          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          Uint8List pngBytes = byteData!.buffer.asUint8List();

          final pdf = pw.Document();
          final imageProvider = pw.MemoryImage(pngBytes);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(
                    imageProvider,
                    fit: pw.BoxFit.contain,
                    width: PdfPageFormat.a4.width,
                  ),
                );
              },
            ),
          );

          // Save PDF to device
          final directory = await getTemporaryDirectory(); // or getApplicationDocumentsDirectory()
          final filePath = '${directory.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final file = File(filePath);
          await file.writeAsBytes(await pdf.save());

          Fluttertoast.showToast(msg: "📄 PDF saved to: $filePath");

          // Share the file
          await Share.shareXFiles([XFile(file.path)], text: "📄 Here's my health report");

        } catch (e) {
          print("❌ Error generating PDF: $e");
          Fluttertoast.showToast(msg: "❌ Failed to export PDF");
        }
        break;
      case "Delete":
      final id = widget.reportData?["id"];
      if (id != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text("Are you sure you want to delete this report?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
            ],
          ),
        );

        if (confirmed == true) {
          final success = await ApiClient().deleteReport(id);
          if (success && mounted) {
            Fluttertoast.showToast(msg: "🗑️ Report deleted successfully");
            Navigator.pop(context, true); // return true to indicate deletion
          } else {
            Fluttertoast.showToast(msg: "❌ Failed to delete report");
          }
        }
      } else {
        Fluttertoast.showToast(msg: "❌ Report ID not found");
      }
      break;

    }
  }

  @override
    void initState() {
      super.initState();

      if (widget.reportData != null) {
        final r = widget.reportData!;
        final sessionEndRaw = r["session_end"];

        String formattedDate = "-";
        String formattedTime = "-";

        if (sessionEndRaw != null) {
          try {
            final sessionEnd = DateTime.parse(sessionEndRaw).toLocal(); // Ensure local time
            formattedDate = DateFormat("yyyy-MM-dd").format(sessionEnd);
            formattedTime = DateFormat("HH:mm").format(sessionEnd);
          } catch (e) {
            print("❌ Failed to parse session_end: $e");
          }
        }

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
          date = formattedDate;   // ✅ use formatted
          time = formattedTime;   // ✅ use formatted
          final recs = r["recommendations_by_vital"] ?? {};
          tempRecommendation = recs["temperature"] ?? {};
          respRecommendation = recs["respiration"] ?? {};
          ecgRecommendation = recs["ecg"] ?? {};

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
      child: RepaintBoundary(
        key: reportKey,
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.032),
          color: const Color(0xFFF5F5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Health Report",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PatientInfoCard(
                fullName: fullName,
                age: age,
                gender: gender,
                weight: weight,
              ),
              SizedBox(height: screenHeight * 0.02),
              SessionTimestampCard(date: date, time: time),
              SizedBox(height: screenHeight * 0.02),
              SeveritySection(severity: severity),
              SizedBox(height: screenHeight * 0.02),
              ECGInterpretation(
                arrhythmiaStatus: arrhythmiaStatus,
                bpm: bpm,
                recommendation: ecgRecommendation,
                metrics: widget.reportData?["ecg_metrics"] ?? {},
              ),
              SizedBox(height: screenHeight * 0.02),
              Respiration(
                respirationRate: respirationRate,
                respirationCondition: respirationCondition,
                recommendation: respRecommendation,
              ),
              SizedBox(height: screenHeight * 0.02),
              Temperature(
                temperature: temperature,
                temperatureCondition: temperatureCondition,
                recommendation: tempRecommendation,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class PatientInfoCard extends StatelessWidget {
  final String fullName;
  final String age;
  final String gender;
  final String weight;

  const PatientInfoCard({
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

class SessionTimestampCard extends StatelessWidget {
  final String date;
  final String time;

  const SessionTimestampCard({
    super.key,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      child: Row(
        children: [
          Text("Date: $date", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 20),
          Text("Time: $time", style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class SeveritySection extends StatelessWidget {
  final String severity;

  const SeveritySection({
    required this.severity,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color severityColor = {
      "High": Colors.red,
      "Very High": Colors.deepOrange,
      "Critical": Colors.deepPurple,
      "Normal": Colors.green,
      "Low": Colors.orange,
    }[severity] ?? Colors.grey;

    Icon severityIcon = {
      "High": Icon(Icons.warning, color: Colors.red),
      "Very High": Icon(Icons.warning_amber, color: Colors.deepOrange),
      "Critical": Icon(Icons.dangerous, color: Colors.deepPurple),
      "Normal": Icon(Icons.check_circle, color: Colors.green),
      "Low": Icon(Icons.info, color: Colors.orange),
    }[severity] ?? Icon(Icons.info_outline, color: Colors.grey);

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(context, "Severity Level:", severity),
          const SizedBox(height: 8),
          Row(
            children: [
              severityIcon,
              const SizedBox(width: 6),
              Text(
                severity,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
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
  final Map<String, dynamic> recommendation;
  final Map<String, dynamic> metrics;

  const ECGInterpretation({
    required this.arrhythmiaStatus,
    required this.bpm,
    required this.recommendation,
    required this.metrics,
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
          _infoRow(context, "Rate", bpm),
          _infoRow(context, "Rhythm", arrhythmiaStatus),
          ...metrics.entries.map((e) => _infoRow(context, e.key, e.value ?? "-")),
          const SizedBox(height: 10),
          VitalRecommendation(title: "ECG", data: recommendation),
        ],
      ),
    );
  }
}

class Respiration extends StatelessWidget {
  final String respirationRate;
  final String respirationCondition;
  final Map<String, dynamic> recommendation;

  const Respiration({
    required this.respirationRate,
    required this.respirationCondition,
    required this.recommendation,
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
          _infoRow(context, "Respiration Rate", "$respirationRate breaths/min"),
          _infoRow(context, "Condition", respirationCondition),
          const SizedBox(height: 10),
          VitalRecommendation(title: "Respiration", data: recommendation),
        ],
      ),
    );
  }

}

class Temperature extends StatelessWidget {
  final String temperature;
  final String temperatureCondition;
  final Map<String, dynamic> recommendation;

  const Temperature({
    required this.temperature,
    required this.temperatureCondition,
    required this.recommendation,
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TEMPERATURE",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: screenWidth * 0.032)),
          const Divider(),
          _infoRow(context, "Temperature", temperature),
          _infoRow(context, "Condition", temperatureCondition),
          const SizedBox(height: 10),
          VitalRecommendation(title: "Temperature", data: recommendation),
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
class VitalRecommendation extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const VitalRecommendation({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final String recTitle = data["title"] ?? "No Recommendation";
    final String recMessage = data["message"] ?? "No details available.";

    return _buildCard(
      context,
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title Recommendation",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.034)),
          const Divider(),
          Text(recTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 5),
          Text(recMessage),
        ],
      ),
    );
  }
}
