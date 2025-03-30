// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../services/api_client.dart';
// import 'package:flutter/services.dart';

// class FullscreenECG extends StatefulWidget {
//   const FullscreenECG({super.key});

//   @override
//   State<FullscreenECG> createState() => _FullscreenECGState();
// }

// class _FullscreenECGState extends State<FullscreenECG> {
//   List<FlSpot> ecgData = [];
//   double time = 0;
//   ApiClient apiClient = ApiClient();

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
//     apiClient.getECGStream(
//       onNewECG: (double adc) {
//         if (mounted) {
//           setState(() {
//             ecgData.add(FlSpot(time, adc));
//             time += 0.05;
//             if (ecgData.length > 300) {
//               ecgData = ecgData.sublist(ecgData.length - 300);
//             }
//           });
//         }
//       },
//     );
//   }

//   @override
//   void dispose() {
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
//     apiClient.stopECGStreamSSE();
//     super.dispose();
//   }

//   LineChartData _chartData() {
//     return LineChartData(
//       backgroundColor: Colors.black,
//       gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: true),
//       titlesData: FlTitlesData(show: false),
//       borderData: FlBorderData(show: false),
//       lineBarsData: [
//         LineChartBarData(
//           spots: ecgData,
//           isCurved: true,
//           color: Colors.green.shade700,
//           barWidth: 2,
//           belowBarData: BarAreaData(show: false),
//           dotData: FlDotData(show: false),
//         ),
//       ],
//     );
//   }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: Colors.black,
//     body: SafeArea(
//       child: Stack(
//         children: [
//           Center(
//             child: ecgData.isEmpty
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : LineChart(_chartData()),
//           ),
//           Positioned(
//             top: 16,
//             left: 16,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }