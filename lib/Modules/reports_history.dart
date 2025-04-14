import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'report.dart'; // This must be the detailed report screen

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  String _selectedRange = "24h"; // default
  final List<String> _rangeOptions = ["24h", "week", "month"];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString("patient_id");
    if (patientId == null) {
      print("❌ Patient ID missing.");
      return;
    }

    try {
      final fetchedReports = await ApiClient().getReports(patientId, range: _selectedRange);
      setState(() {
        reports = fetchedReports;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching reports: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
      ? const Center(child: CircularProgressIndicator())
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
            ),
            Expanded(
              child: reports.isEmpty
                  ? const Center(child: Text("No reports available"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                      final report = reports[index];
                      final sessionEnd = DateTime.parse(report["session_end"]).toLocal();
                      final formattedDate = DateFormat("yyyy-MM-dd").format(sessionEnd);
                      final formattedTime = DateFormat("HH:mm").format(sessionEnd);
                      final severity = report["severity"] ?? "Unknown";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text("Session: $formattedDate  $formattedTime"),
                          subtitle: Text("Severity: $severity"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PatientReport(reportData: report),
                              ),
                            );

                            if (result == true) {
                              // User deleted the report, so refresh the list
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

    );
  }
}
