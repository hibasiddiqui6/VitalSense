import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(ECGChartApp());
}

class ECGChartApp extends StatelessWidget {
  const ECGChartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Arial', // Use a clean font
      ),
      home: ECGChartScreen(),
    );
  }
}

class ECGChartScreen extends StatefulWidget {
  const ECGChartScreen({super.key});

  @override
  _ECGChartScreenState createState() => _ECGChartScreenState();
}

class _ECGChartScreenState extends State<ECGChartScreen> {
  String selectedTime = "24h"; // Default selected button

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F2EE), // Soft background

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button at Top-Left with Margin
            Positioned(
              top: 10, // Adjust for positioning
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Center(
              child: Text(
                "Trends and History",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 8),
            // ECG TITLE
            Center(
              child: Text(
                "ECG",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(height: 8),

            // TIME FILTER BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeFilterButton("24h"),
                _timeFilterButton("Week"),
                _timeFilterButton("Month"),
              ],
            ),
            SizedBox(height: 16),

            // LINE CHART
            _buildGradientChart(),
            SizedBox(height: 16),

            // BPM CARDS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bpmIndicator(
                    "10 BPM", "MIN", [Color(0xFFFFCDB6), Color(0xFFFFE9DF)]),
                _bpmIndicator(
                    "25 BPM", "MAX", [Color(0xFFFFE5B4), Color(0xFFFFEBD6)]),
                _bpmIndicator(
                    "16 BPM", "AVG", [Color(0xFFA6C583), Color(0xFFF0FFD7)]),
              ],
            ),
            SizedBox(height: 16),

            // DATA TABLE
            _buildDataTable(),
          ],
        ),
      ),
    );
  }

  // TIME FILTER BUTTONS
  Widget _timeFilterButton(String text) {
    bool isSelected = text == selectedTime; // Check if this button is selected

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTime = text; // Update selected button
          });
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [Color(0xFFE8C492), Color(0xFFD9C2BA)])
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.3), blurRadius: 5)
                  ]
                : [],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSelected ? Colors.transparent : Colors.grey[300],
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              setState(() {
                selectedTime = text; // Update selected button
              });
            },
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // GRADIENT LINE CHART
  Widget _buildGradientChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8C492), Color(0xFFC6D8C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${value.toInt()}h',
                        style: TextStyle(fontSize: 12, color: Colors.black)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.black,
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE8C492).withOpacity(0.5),
                    Color(0xFFC6D8C0).withOpacity(0.5)
                  ],
                ),
              ),
              spots: [
                FlSpot(1, 12),
                FlSpot(2, 14),
                FlSpot(3, 16),
                FlSpot(4, 15),
                FlSpot(5, 17),
                FlSpot(6, 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // BPM CARDS
  Widget _bpmIndicator(String value, String label, List<Color> gradientColors) {
    return Container(
      width: 80,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            offset: Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // DATA TABLE
  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _tableHeaderText("Time"),
            _tableHeaderText("Reading"),
            _tableHeaderText("Status"),
          ]),
          Divider(color: Colors.grey.shade300, thickness: 1),
          _tableRow("5 PM", "24 BPM", "RAPID BREATHING"),
          Divider(color: Colors.grey.shade300, thickness: 1),
          _tableRow("2 BPM", "16 BPM", "NORMAL BREATHING"),
        ],
      ),
    );
  }

  Widget _tableHeaderText(String text) =>
      Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));

  Widget _tableRow(String time, String reading, String status) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Text(time),
      Text(reading),
      Text(status),
    ]);
  }
}
