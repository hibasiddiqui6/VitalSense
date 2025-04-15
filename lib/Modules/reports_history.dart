import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/widgets/patient_drawer.dart';
import 'package:vitalsense/widgets/specialist_drawer.dart';
import '../services/api_client.dart';
import 'report.dart'; // This must be the detailed report screen

class ReportHistoryScreen extends StatefulWidget {
  final String? patientId; // Making patientId optional
  final String? patientName;

  const ReportHistoryScreen({super.key, this.patientId, this.patientName,}); // Allow null patientId for patients

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  String _selectedRange = "24h"; // default
  final List<String> _rangeOptions = ["24h", "week", "month"];
  String fullName = "Loading..."; 
  String email = "example@example.com";
  String role = "-";
  String? patientId; // Optional patientId

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
      role = prefs.getString("role") ?? "-";
    });

    // If the specialist is navigating, they will provide patientId
    patientId = widget.patientId ?? prefs.getString("patient_id");
    if (patientId == null && role == 'specialist') {
      if (kDebugMode) {
        print("❌ Patient ID missing for specialist.");
      }
      // Handle the case where no patientId is provided for specialist
      setState(() => isLoading = false);
    } else {
      fetchReports();
    }
  }

  Future<void> fetchReports() async {
    if (patientId == null) {
      if (kDebugMode) {
        print("❌ Patient ID missing.");
      }
      return;
    }

    try {
      final fetchedReports = await ApiClient().getReports(patientId!, range: _selectedRange);
      setState(() {
        reports = fetchedReports;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching reports: $e");
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 239, 238, 229),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: role == 'specialist'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // Go back to previous screen
                },
              )
            : null, // No leading icon for patients
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: role == 'specialist'
            ? SpecialistDrawer(fullName: fullName, email: email)
            : PatientDrawer(fullName: fullName, email: email),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.032, vertical: screenHeight * 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      role == 'specialist' 
                        ? "Reports for ${widget.patientName}" 
                        : "My Reports",
                      style: TextStyle(
                        fontSize: role == 'specialist' ? screenWidth * 0.045 : screenWidth * 0.06, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("Range: "),
                      DropdownButton<String>(
                        value: _selectedRange,
                        items: _rangeOptions
                            .map((range) => DropdownMenuItem(
                                  value: range,
                                  child: Text(range.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRange = value;
                              isLoading = true;
                            });
                            fetchReports();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: reports.isEmpty
                        ? const Center(child: Text("No reports available"))
                        : ListView.builder(
                            itemCount: reports.length,
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              final sessionEnd = DateTime.parse(report["session_end"]).toLocal();
                              final formattedDate = DateFormat("yyyy-MM-dd").format(sessionEnd);
                              final formattedTime = DateFormat("HH:mm").format(sessionEnd);
                              final severity = report["severity"] ?? "Unknown";

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                color: role == 'specialist' 
                                    ? Color.fromARGB(255, 154, 180, 154) 
                                    : Color.fromARGB(255, 224, 233, 217),
                                elevation: 4, // Add elevation for shadow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12), // Rounded corners
                                ),
                                child: ListTile(
                                  dense: true, // Makes ListTile more compact
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  title: Text(
                                    "Session: $formattedDate  $formattedTime",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    "Severity: $severity",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PatientReport(reportData: report),
                                      ),
                                    );

                                    if (result == true) {
                                      fetchReports();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
