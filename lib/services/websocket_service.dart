import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/controllers/sensor_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ShirtWebSocketService {
  late WebSocketChannel _channel;
  late StreamSubscription _streamSub;
  late Timer _pingTimer;
  Timer? _flushTimer;

  final List<Map<String, dynamic>> _sensorBuffer = [];

  final String patientId;
  final String smartshirtId;
  String ip;
  late Function(Map<String, dynamic>) _onRealtimeUpdate;

  ShirtWebSocketService({
    required this.patientId,
    required this.smartshirtId,
    required this.ip,
  });

 Future<bool> connect({
    required Function(Map<String, dynamic>) onRealtimeUpdate,
  }) async {
    _onRealtimeUpdate = onRealtimeUpdate;

    print("🌐 Attempting connection to ws://$ip/ws");

    try {
      _channel = WebSocketChannel.connect(Uri.parse("ws://$ip/ws"));
      print("✅ Connected to WebSocket");
    } catch (e) {
      print("❌ Connection failed: $e");
      return false;
    }

    // Send auth payload
    _channel.sink.add(jsonEncode({
      "patient_id": patientId,
      "smartshirt_id": smartshirtId,
    }));

    _streamSub = _channel.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data);
          _sensorBuffer.add(decoded);
          _onRealtimeUpdate(decoded);
        } catch (e) {
          print("❌ JSON Decode Error: $e");
        }
      },
      onDone: () {
        print("📴 WebSocket closed. Triggering reconnect...");
        reconnect();
      },
      onError: (e) {
        print("❌ WebSocket error: $e");
        reconnect();
      },
      cancelOnError: true,
    );

    _pingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      try {
        _channel.sink.add("ping");
      } catch (e) {
        print("❌ Ping failed: $e");
      }
    });

    return true;
  }

  void reconnect() async {
    print("🔌 Reconnecting...");
    await disconnect();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    while (true) {
      await Future.delayed(Duration(seconds: 5));

      String? cachedIp = prefs.getString("latest_ip");

      if (cachedIp != null) {
        ip = cachedIp;
        print("📦 Using cached IP: $ip");
      } else {
        final newIpResult = await ApiClient().getLatestMacAndIP();
        if (newIpResult.containsKey("ip_address")) {
          ip = newIpResult["ip_address"];
          print("🔁 Fetched new IP: $ip");
          await prefs.setString("latest_ip", ip);
        } else {
          print("❌ No IP available. Retrying...");
          continue;
        }
      }

      final success = await connect(onRealtimeUpdate: _onRealtimeUpdate);
      if (success) break; // Exit retry loop on success
    }
  }

  Future<void> disconnect() async {
    _pingTimer.cancel();
    _flushTimer?.cancel();
    await _streamSub.cancel();
    await _channel.sink.close();

    // 💡 Only flush if stabilized
    if (SensorController().hasStabilized) {
      flushToBackend();
    } else {
      print("⏳ Not stabilized — skipping flush.");
    }
  }

  void flushToBackend() async {
  final url = Uri.parse("https://vitalsense-flask-backend.fly.dev/sensor");

  // Create a copy to safely iterate
  final batchesToFlush = List<Map<String, dynamic>>.from(_sensorBuffer);
  final List<Map<String, dynamic>> failedBatches = [];

  for (final batch in batchesToFlush) {
    final payload = {
      ...batch,
      "patient_id": patientId,
      "smartshirt_id": smartshirtId,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        print("❌ Flush failed (${response.statusCode}): ${response.body}");
        failedBatches.add(payload);
      } else {
        print("✅ Flushed batch.");
      }
    } catch (e) {
      print("⚠️ Flush error: $e");
      failedBatches.add(payload);
    }
  }

  // Only after loop, update original buffer
  _sensorBuffer
    ..clear()
    ..addAll(failedBatches);
}

}
