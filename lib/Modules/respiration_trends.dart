import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../services/timezone_helper.dart';
import '../widgets/patient_drawer.dart';
import '../widgets/specialist_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RespChartScreen extends StatefulWidget {
  final bool showDrawer;
  final String? patientId;
  final String? patientName;

  const RespChartScreen({
    super.key,
    this.showDrawer = false,
    this.patientId,
    this.patientName,
  });

  @override
  _RespChartScreenState createState() => _RespChartScreenState();
}

class _RespChartScreenState extends State<RespChartScreen> {
  String selectedTime = "24h";
  List<Map<String, dynamic>> trendData = [];
  bool isLoading = true;
  String role = "-";
  String fullName = "User";
  String email = "example@example.com";

  bool isValidRespiration(double resp) => resp >= 5 && resp <= 40;

  @override
  void initState() {
    super.initState();
    initializeTimeZone().then((_) {
      _loadUserDetails();
      fetchTrends();
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "User";
      email = prefs.getString("email") ?? "email@example.com";
      role = prefs.getString("role") ?? "-";
    });
  }

  Future<void> fetchTrends() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final patientId = widget.patientId ?? prefs.getString("patient_id");

    if (patientId == null) {
      print("❌ Patient ID missing");
      setState(() => isLoading = false);
      return;
    }

    final data = await ApiClient().getRespirationTrends(selectedTime, patientId: patientId);

    print("Fetched ${data.length} respiration records for $selectedTime");

    final uniqueData = {
      for (var e in data) e['timestamp']: e
    }.values.toList();

    setState(() {
      trendData = uniqueData;
      trendData.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
      isLoading = false;
    });
    
  }

  List<Map<String, dynamic>> getFilteredData() {
    if (trendData.isEmpty) return [];

    final now = DateTime.parse(trendData.last['timestamp']).toLocal(); // Use last reading as now

    final cutoff = () {
      if (selectedTime.toLowerCase() == "week") {
        return now.subtract(Duration(days: 7));
      } else if (selectedTime.toLowerCase() == "month") {
        return now.subtract(Duration(days: 30));
      } else {
        return now.subtract(Duration(hours: 24));
      }
    }();

    return trendData.where((e) {
      final resp= double.tryParse(e['respiration']?.toString().trim() ?? '') ?? 0.0;
      final time = DateTime.tryParse(e['timestamp'] ?? '');
      return isValidRespiration(resp) && time != null && time.isAfter(cutoff);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2EE),
      drawer: widget.showDrawer
          ? SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: role == 'specialist'
                  ? SpecialistDrawer(fullName: fullName, email: email)
                  : PatientDrawer(fullName: fullName, email: email),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 45),
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Center(
                      child: Column(
                        children: const [
                          Text("Trends and History", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          Text("RESPIRATION", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timeFilterButton("24h"),
                        _timeFilterButton("Week"),
                        _timeFilterButton("Month"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGradientChart(),
                    _buildRangeSummary(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: trendData.isEmpty
                          ? [
                              _bpmIndicator("-", "MIN", [Color(0xFFFFCDB6), Color(0xFFFFE9DF)]),
                              _bpmIndicator("-", "AVG", [Color(0xFFA6C583), Color(0xFFF0FFD7)]),
                              _bpmIndicator("-", "MAX", [Color(0xFFFFE5B4), Color(0xFFFFEBD6)]),
                            ]
                          : _generateStats(),
                    ),
                    const SizedBox(height: 16),
                    _buildDataTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _timeFilterButton(String text) {
    bool isSelected = text == selectedTime;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() => selectedTime = text);
          fetchTrends();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.brown[300] : Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildGradientChart() {
    final filteredTrend = getFilteredData();
    if (filteredTrend.isEmpty) return const Center(child: Text("No respiration data."));

    final spots = <FlSpot>[];
    final dateTimes = <DateTime>[];

    for (int i = 0; i < filteredTrend.length; i++) {
      final resp= double.tryParse(filteredTrend[i]['respiration'])!;
      final time = DateTime.parse(filteredTrend[i]['timestamp']);
      spots.add(FlSpot(i.toDouble(), resp));
      dateTimes.add(time);
    }

    String formatLabel(DateTime dt) {
      final localDT = toPKT(dt);
      switch (selectedTime.toLowerCase()) {
        case "week": return DateFormat.E().format(localDT);
        case "month": return DateFormat.MMMd().format(localDT);
        default: return DateFormat.jm().format(localDT);
      }
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8C492), Color(0xFFC6D8C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, spreadRadius: 3)],
      ),
      child: LineChart(
        LineChartData(
          minY: 5,
          maxY: 40,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= dateTimes.length) return const SizedBox();
                  final label = formatLabel(dateTimes[index]);
                  final shouldShow = index == 0 || index == dateTimes.length - 1 || index % (dateTimes.length ~/ 4).clamp(1, 9999) == 0;
                  return shouldShow
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black), overflow: TextOverflow.ellipsis),
                        )
                      : const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text("${value.toInt()}°", style: const TextStyle(fontSize: 10, color: Colors.black)),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              curveSmoothness: 0.15,
              color: Colors.black,
              barWidth: 1.0,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [Color(0xFFE8C492).withOpacity(0.3), Color(0xFFC6D8C0).withOpacity(0.3)]),
              ),
              spots: spots,
              dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final status = (filteredTrend[index]['respirationstatus'] ?? "").toString().trim().toLowerCase();
                final isAbnormal = !["normal"].contains(status);
                return isAbnormal
                    ? FlDotCirclePainter(radius: 1.0, color: Colors.red, strokeWidth: 0)
                    : FlDotCirclePainter(radius: 0.0, color: Colors.transparent, strokeWidth: 0);
              },
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSummary() {
    final filtered = getFilteredData();
    if (filtered.isEmpty) return const SizedBox.shrink();
    final first = toPKT(DateTime.parse(filtered.first['timestamp']));
    final last = toPKT(DateTime.parse(filtered.last['timestamp']));
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Center(
        child: Text(
          "${DateFormat('MMM d, h:mm a').format(first)} → ${DateFormat('MMM d, h:mm a').format(last)}",
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    );
  }

  List<Widget> _generateStats() {
  final filtered = getFilteredData();

  final resps = filtered
      .map((e) => double.tryParse(e['respiration'] ?? '') ?? 0.0)
      .where((resp) => isValidRespiration(resp))
      .toList();

  if (resps.isEmpty) {
    return [
      _bpmIndicator("-", "MIN", [Color(0xFFFFCDB6), Color(0xFFFFE9DF)]),
      _bpmIndicator("-", "AVG", [Color(0xFFA6C583), Color(0xFFF0FFD7)]),
      _bpmIndicator("-", "MAX", [Color(0xFFFFE5B4), Color(0xFFFFEBD6)]),
    ];
  }

  final min = resps.reduce((a, b) => a < b ? a : b);
  final max = resps.reduce((a, b) => a > b ? a : b);
  final avg = resps.reduce((a, b) => a + b) / resps.length;

  return [
    _bpmIndicator("${min.toStringAsFixed(1)} F", "MIN", [Color(0xFFFFCDB6), Color(0xFFFFE9DF)]),
    _bpmIndicator("${avg.toStringAsFixed(1)} F", "AVG", [Color(0xFFA6C583), Color(0xFFF0FFD7)]),
    _bpmIndicator("${max.toStringAsFixed(1)} F", "MAX", [Color(0xFFFFE5B4), Color(0xFFFFEBD6)]),
  ];
}

  Widget _bpmIndicator(String value, String label, List<Color> colors) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
  final filtered = getFilteredData();

  if (filtered.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text("No respiration data available."),
      ),
    );
  }

  List<Map<String, String>> rows = [];

  if (selectedTime.toLowerCase() == "24h") {
    // Show individual rows
    final shownLabels = <String>{};
    for (final entry in filtered.reversed) {
      final label = _formatTimeLabel(entry['timestamp']);
      if (!shownLabels.contains(label)) {
        shownLabels.add(label);
        rows.add({
          "time": label,
          "resp": "${entry['respiration']} F",
          "status": entry['respirationstatus'] ?? "-",
        });
      }
    }
  } else {
    // Group by label (day/month), then average respand majority status
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final entry in filtered) {
      final label = _formatTimeLabel(entry['timestamp']);
      grouped.putIfAbsent(label, () => []).add(entry);
    }

    grouped.forEach((label, entries) {
      final resps = entries
          .map((e) => double.tryParse(e['respiration'] ?? '') ?? 0.0)
          .toList();

      final avgResp=
          resps.reduce((a, b) => a + b) / resps.length;

      final statusCounts = <String, int>{};
      for (final e in entries) {
        final status = e['respirationstatus'] ?? "-";
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      final topStatus = statusCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      rows.add({
        "time": label,
        "resp": "${avgResp.toStringAsFixed(1)} F",
        "status": topStatus,
        "rawTimestamp": entries.first['timestamp'], 
      });

    });

    rows.sort((a, b) {
      final aTime = DateTime.tryParse(a["rawTimestamp"] ?? "") ?? DateTime.now();
      final bTime = DateTime.tryParse(b["rawTimestamp"] ?? "") ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _tableHeaderText("Time")),
            Expanded(child: _tableHeaderText("Reading")),
            Expanded(child: _tableHeaderText("Status")),
          ],
        ),
        Divider(color: Colors.grey.shade300),
        ...rows.map((e) => Column(
              children: [
                _tableRow(e["time"]!, e["resp"]!, e["status"]!),
                Divider(color: Colors.grey.shade300),
              ],
            )),
      ],
    ),
  );
}

String _formatTimeLabel(String timestamp) {
  final dt = toPKT(DateTime.parse(timestamp));
  switch (selectedTime.toLowerCase()) {
    case "week":
      return DateFormat('EEE, MMM d').format(dt); // Thu, Apr 4
    case "month":
      return DateFormat('yyyy-MM-dd').format(dt); // 2025-04-04 (for sorting)
    default:
      return DateFormat('MMM d, hh:mm a').format(dt); // Apr 3, 01:55 AM
  }
}

Widget _tableRow(String time, String reading, String status) {
  final abnormalStatuses = ["slow", "rapid"];
  final isAbnormal = abnormalStatuses.contains(status.toLowerCase());

  return Row(
    children: [
      Expanded(child: Text(time, textAlign: TextAlign.center)),
      Expanded(child: Text(reading, textAlign: TextAlign.center)),
      Expanded(
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isAbnormal ? Colors.red : Colors.black,
            fontWeight: isAbnormal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ],
  );
}

  Widget _tableHeaderText(String text) => Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
}