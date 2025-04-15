import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/Modules/patient_dashboard.dart';
import 'package:vitalsense/Modules/report.dart';
import 'package:vitalsense/Modules/specialist_patient_insights.dart';
import 'package:vitalsense/services/api_client.dart';
import 'package:vitalsense/services/websocket_service.dart';
import 'patient_dashboard_controller.dart';
import 'specialist_patient_insights_controller.dart';
import 'temperature_controller.dart';
import 'respiration_controller.dart';
import 'ecg_controller.dart';

class SensorController {
  static final SensorController _instance = SensorController._internal();
  factory SensorController() => _instance;
  SensorController._internal();

  late ShirtWebSocketService webSocketService;

  String? _lastBootId;
  bool _hasStartedStabilization = false;
  bool hasStabilized = false;
  DateTime? stabilizationStartTime;
  Timer? _stabilizationTimer;

  Future<bool> initWebSocket({
    required String patientId,
    required String smartshirtId,
    required String ip,
  }) async {
    webSocketService = ShirtWebSocketService(
      ip: ip,
      patientId: patientId,
      smartshirtId: smartshirtId,
    );

    final success = await webSocketService.connect(
      onRealtimeUpdate: (data) {
        // print("📡 Real-time data received in SensorController: $data");

        PatientDashboardState.instance?.lastSuccessfulFetch = DateTime.now();
        PatientInsightsScreenState.instance?.lastSuccessfulFetch = DateTime.now();

        final String? currentBootId = data['boot_id'];
        if (currentBootId != null && currentBootId != _lastBootId) {
          print("⚠️ New boot session detected (boot_id: $currentBootId)");

          _lastBootId = currentBootId;
          _hasStartedStabilization = false;
          hasStabilized = false;
          stabilizationStartTime = null;
          _stabilizationTimer?.cancel();
        }

        if (!_hasStartedStabilization && stabilizationStartTime == null) {
          print("⏳ Starting stabilization timer...");
          _hasStartedStabilization = true;
          stabilizationStartTime = DateTime.now();

          _stabilizationTimer = Timer(const Duration(seconds: 30), () {
            hasStabilized = true;
            print("✅ Stabilization complete");
          });
        }

        if (!hasStabilized) {
          print("⛔ Not stabilized yet. Skipping update.");
          return;
        }

        double? temp = double.tryParse(data['temperature'].toString());
        double? resp = double.tryParse(data['respiration'].toString());
        double? ecgRaw = double.tryParse(data['ecg_raw'].toString());

        if (temp != null) {
          // print("👈 Adding temp: $temp");
          TemperatureController.instance?.updateFromRealtime(temp);
          DashboardController.instance?.updateTemperatureLive(temp);
          PatientInsightsController.instance?.updateTemperatureLive(temp);
        }

        if (resp != null) {
          // print("👈 Adding resp: $resp");
          RespirationController.instance?.updateFromRealtime(resp);
          DashboardController.instance?.updateRespirationLive(resp);
          PatientInsightsController.instance?.updateRespirationLive(resp);
        }

        if (ecgRaw != null) {
          print("👈 Adding ECG point: $ecgRaw");
          ECGController.instance?.addPoint(ecgRaw);
        }
      },
    );

    return success;
  }

  int getSecondsRemaining() {
    if (hasStabilized || stabilizationStartTime == null) return 0;

    final elapsed = DateTime.now().difference(stabilizationStartTime!).inSeconds;

    if (elapsed >= 30) {
      hasStabilized = true;
      print("✅ Auto-marking stabilized via getter");
      return 0;
    }

    return 30 - elapsed;
  }

  void dispose(BuildContext context) {
    _stabilizationTimer?.cancel();

    webSocketService.disconnect();
  }
  
  Future<void> endMonitoringSession(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString("patient_id");
    final smartshirtId = prefs.getString("smartshirt_id");

    if (patientId == null || smartshirtId == null) {
      print("❌ Missing patient or shirt ID");
      return;
    }

    final sessionStart = stabilizationStartTime ?? DateTime.now().subtract(const Duration(minutes: 1));

    try {
      await webSocketService.disconnect();
      await ApiClient().endMonitoringSession(
        patientId: patientId,
        smartshirtId: smartshirtId,
        sessionStart: sessionStart,
      );

      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Session Ended"),
          content: Text("Your report will be generated shortly."),
        ),
      );

      // 🕓 Now poll for the report
      await waitForReportAndNotify(context, patientId);

    } catch (e) {
      print("⚠️ Failed to finalize session: $e");
    }
  }

  Future<void> waitForReportAndNotify(BuildContext context, String patientId) async {
    int retries = 12; // wait up to 60 seconds
    while (retries-- > 0) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final reports = await ApiClient().getReports(patientId, range: "24h");
        if (reports.isNotEmpty) {
          final recentReport = reports.first;
          final sessionEnd = DateTime.parse(recentReport["session_end"]).toLocal(); 
          print("🕒 Raw session_end: ${recentReport["session_end"]}");

          final diff = DateTime.now().difference(sessionEnd).inMinutes;

          print("⌛ Diff: $diff mins");

          if (diff <= 5) {
            print("📥 Found report with session_end: $sessionEnd");

            // Show a success prompt
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Report Ready"),
                  content: const Text("Your monitoring report has been generated."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Dismiss the dialog first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientReport(reportData: recentReport),
                          ),
                        );
                      },
                      child: const Text("View Report"),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        print("⚠️ Failed to poll report: $e");
      }
    }

    // Optional: timeout notice
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Report Delayed"),
          content: Text("Report generation is taking longer than expected."),
        ),
      );
    }
  }

}