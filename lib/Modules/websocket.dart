import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class ECGWebSocketPage extends StatefulWidget {
  const ECGWebSocketPage({super.key});

  @override
  _ECGWebSocketPageState createState() => _ECGWebSocketPageState();
}

class _ECGWebSocketPageState extends State<ECGWebSocketPage> {
  late WebSocketChannel channel;
  late StreamSubscription streamSub;
  late Timer pingTimer;

  List<FlSpot> ecgSpots = [];
  double time = 0;
  final int maxSpots = 250;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.0.51/ecg'),
    );

    streamSub = channel.stream.listen(
      (data) {
        print('Received: $data');

        final value = double.tryParse(data.toString().trim());
        if (value != null) {
          setState(() {
            ecgSpots.add(FlSpot(time, value));
            time += 1;

            if (ecgSpots.length > maxSpots) {
              ecgSpots.removeAt(0);
              for (int i = 0; i < ecgSpots.length; i++) {
                ecgSpots[i] = FlSpot(ecgSpots[i].x - 1, ecgSpots[i].y);
              }
              time -= 1;
            }
          });
        }
      },
      onDone: () {
        print("WebSocket stream closed. Attempting reconnect...");
        reconnectWebSocket();
      },
      onError: (e) {
        print("WebSocket error: $e");
        reconnectWebSocket();
      },
      cancelOnError: true,
    );

    pingTimer = Timer.periodic(Duration(seconds: 10), (_) {
      try {
        channel.sink.add("ping");
      } catch (e) {
        print("Ping failed: $e");
      }
    });
  }

  void reconnectWebSocket() {
    streamSub.cancel();
    pingTimer.cancel();
    channel.sink.close();
    Future.delayed(Duration(seconds: 1), () {
      connectWebSocket();
    });
  }

  @override
  void dispose() {
    streamSub.cancel();
    pingTimer.cancel();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? latestValue = ecgSpots.isNotEmpty ? ecgSpots.last.y : null;

    return Scaffold(
      appBar: AppBar(title: Text('Live ECG')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              latestValue != null
                  ? 'Latest ECG value: ${latestValue.toInt()}'
                  : 'Waiting for data...',
              style: TextStyle(fontSize: 22),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ecgSpots.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 4095,
                        minX: 0,
                        maxX: maxSpots.toDouble(),
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: ecgSpots,
                            isCurved: false,
                            color: Colors.red,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                          )
                        ],
                      ),
                    )
                  : Center(
                      child: Text(
                        "Waiting for ECG data...",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
