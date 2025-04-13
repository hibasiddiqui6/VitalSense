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
        print("📡 Real-time data received in SensorController: $data");

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
          print("👈 Adding temp: $temp");
          TemperatureController.instance?.updateFromRealtime(temp);
          DashboardController.instance?.updateTemperatureLive(temp);
          PatientInsightsController.instance?.updateTemperatureLive(temp);
        }

        if (resp != null) {
          print("👈 Adding resp: $resp");
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

    if (hasStabilized) {
      generateReportOnDisconnect(context);
    }

    webSocketService.disconnect();
  }

  void generateReportOnDisconnect(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString("patient_id");
    final smartshirtId = prefs.getString("smartshirt_id");
    final sessionStart = stabilizationStartTime ?? DateTime.now().subtract(Duration(minutes: 1));
    final sessionEnd = DateTime.now();

    try {
      final response = await ApiClient().generateReport(
        patientId: patientId!,
        smartshirtId: smartshirtId!,
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
      );

      if (response["status"] == "success") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Monitoring Ended"),
            content: const Text("Report generated successfully."),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientReport(reportData: response),
                  ),
                ),
                child: const Text("View Report"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("⚠️ Error generating report: $e");
    }
  }

}