import 'dart:async';
import 'package:vitalsense/Modules/patient_dashboard.dart';
import 'package:vitalsense/services/websocket_service.dart';
import 'dashboard_controller.dart';
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
        double? ecg = double.tryParse(data['ecg'].toString());

        if (temp != null) {
          print("👈 Adding temp: $temp");
          TemperatureController.instance?.updateFromRealtime(temp);
          DashboardController.instance?.updateTemperatureLive(temp);
        }

        if (resp != null) {
          print("👈 Adding resp: $resp");
          RespirationController.instance?.updateFromRealtime(resp);
          DashboardController.instance?.updateRespirationLive(resp);
        }

        if (ecg != null) {
          print("👈 Adding ECG point: $ecg");
          ECGController.instance?.addPoint(ecg);
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

  void dispose() {
    _stabilizationTimer?.cancel();
    webSocketService.disconnect();
  }
}
