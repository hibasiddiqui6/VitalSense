import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ShirtWebSocketService {
  late WebSocketChannel _channel;
  late StreamSubscription _streamSub;
  late Timer _pingTimer;
  Timer? _flushTimer;

  final List<Map<String, dynamic>> _sensorBuffer = [];
  final List<Map<String, dynamic>> _ecgBuffer = [];
  final String patientId;
  final String smartshirtId;
  String ip;
  late Function(Map<String, dynamic>) _onRealtimeUpdate;

  ShirtWebSocketService({
    required this.patientId,
    required this.smartshirtId,
    required this.ip,
  });

  Future<bool> connect({required Function(Map<String, dynamic>) onRealtimeUpdate}) async {
    _onRealtimeUpdate = onRealtimeUpdate;
    final completer = Completer<bool>();

    try {
      _channel = WebSocketChannel.connect(Uri.parse("ws://$ip/ws"));
    } catch (e) {
      print("❌ Connection failed: $e");
      return false;
    }

    _streamSub = _channel.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data);
          final timestamp = decoded['timestamp'];
          final ecg = decoded['ecg_raw'].toString();

          final isDuplicate = _sensorBuffer.any((entry) =>
              entry['timestamp'] == timestamp && entry['ecg_raw'].toString() == ecg);

          if (!isDuplicate) {
            _sensorBuffer.add(decoded);
            _onRealtimeUpdate(decoded);
          }
          if (!_ecgBuffer.any((e) => e['timestamp'] == timestamp)) {
            _ecgBuffer.add(decoded);
          }

          if (!completer.isCompleted) {
            completer.complete(true);
            print("✅ WebSocket handshake confirmed");
            // flushToBackend();
          }

          if (_sensorBuffer.length >= 50) {
            print("🚿 Auto-flushing large batch");
            // flushToBackend();
          }
          if (_ecgBuffer.length == 1000) {
            print("📡 ECG Buffer full — sending for classification");
            flushEcgBuffer();
          }
        } catch (e) {
          print("❌ JSON Decode Error: $e");
        }
      },
      onDone: () {
        print("📴 WebSocket closed unexpectedly.");
        if (!completer.isCompleted) completer.complete(false);
        reconnect();
      },
      onError: (e) {
        print("❌ WebSocket error: $e");
        if (!completer.isCompleted) completer.complete(false);
        reconnect();
      },
      cancelOnError: true,
    );

    _channel.sink.add(jsonEncode({
      "patient_id": patientId,
      "smartshirt_id": smartshirtId,
    }));

    _pingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      try {
        _channel.sink.add("ping");
      } catch (e) {
        print("❌ Ping failed: $e");
      }
    });

    // ⏰ Start auto-flush every 5 seconds
    // _flushTimer = Timer.periodic(Duration(seconds: 5), (_) => flushToBackend());

    return completer.future.timeout(Duration(seconds: 5), onTimeout: () {
      print("⌛ WebSocket handshake timed out.");
      return false;
    });
  }

  Future<void> disconnect() async {
    _pingTimer.cancel();
    _flushTimer?.cancel();
    // await flushToBackend(); // final flush on exit
    await _streamSub.cancel();
    await _channel.sink.close();
  }

  void reconnect() async {
    print("🔌 Reconnecting...");
    await disconnect();

    final prefs = await SharedPreferences.getInstance();
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      final cachedIp = prefs.getString("latest_ip");
      if (cachedIp != null) {
        ip = cachedIp;
      } else {
        final result = await ApiClient().getLatestMacAndIP();
        if (result.containsKey("ip_address")) {
          ip = result["ip_address"];
          await prefs.setString("latest_ip", ip);
        } else {
          print("❌ No IP found. Retrying...");
          continue;
        }
      }

      final success = await connect(onRealtimeUpdate: _onRealtimeUpdate);
      if (success) break;
    }
  }

  // Future<void> flushToBackend() async {
  //   if (_sensorBuffer.isEmpty) return;

  //   _sensorBuffer.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

  //   print("🚀 [Batch Flush] Sending ${_sensorBuffer.length} readings...");

  //   final url = Uri.parse("https://vitalsense-flask-backend.fly.dev/sensor");
  //   final prefs = await SharedPreferences.getInstance();
  //   final gender = prefs.getString("gender") ?? "Male";
  //   final age = int.tryParse(prefs.getString("age") ?? "0") ?? 0;

  //   final batchPayload = _sensorBuffer.map((reading) {
  //     return {
  //       ...reading,
  //       "patient_id": patientId,
  //       "smartshirt_id": smartshirtId,
  //       "age": age,
  //       "gender": gender
  //     };
  //   }).toList();

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(batchPayload),
  //     );

  //     if (response.statusCode == 200) {
  //       print("✅ [Batch Flush] Success (${batchPayload.length} entries)");
  //       _sensorBuffer.clear();
  //     } else {
  //       print("❌ [Batch Flush] Failed: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("⚠️ [Batch Flush] Network error: $e");
  //   }
  // }

  Future<void> flushEcgBuffer() async {
    if (_ecgBuffer.isEmpty) return;

    print("🚀 [ECG Flush] Sending ${_ecgBuffer.length} ECG readings...");

    final url = Uri.parse("https://vitalsense-flask-backend.fly.dev/ecg_batch");
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString("gender") ?? "Male";
    final age = int.tryParse(prefs.getString("age") ?? "0") ?? 0;

    final ecgPayload = [
      {
        "smartshirt_id": smartshirtId,
        "age": age,
        "gender": gender,
        "ecg_values": _ecgBuffer.map((reading) => reading["ecg_raw"]).toList(),
      }
    ];

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(ecgPayload),
      );

      if (response.statusCode == 200) {
        print("✅ [ECG Flush] Success (${ecgPayload.length} entries)");
        _ecgBuffer.clear();
      } else {
        print("❌ [ECG Flush] Failed: ${response.body}");
      }
    } catch (e) {
      print("⚠️ [ECG Flush] Network error: $e");
    }
  }

}