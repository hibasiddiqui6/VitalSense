import 'package:flutter/material.dart';

void main() {
  runApp(TemperaturePage());
}

class TemperaturePage extends StatelessWidget {
  const TemperaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFE8E8E8), // Match background color
        body: Center(
          child: Container(
            width: 350, // Adjust width as needed
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(),
                SizedBox(height: 20),
                _buildTemperatureCard(),
                SizedBox(height: 10),
                _buildDetailsBoxes(),
                SizedBox(height: 10),
                _buildStatusCard(),
                SizedBox(height: 10),
                _buildTemperatureRanges(),
                SizedBox(height: 10),
                _buildTrendsButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
        SizedBox(width: 8),
        Text(
          'TEMPERATURE',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            '35°F',
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(width: 20),
          Icon(Icons.thermostat, size: 40, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildDetailsBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _buildDetailBox('Female', 'Gender'),
        _buildDetailBox('21', 'Age'),
        _buildDetailBox('54.4', 'Weight'),
      ],
    );
  }

  Widget _buildDetailBox(String value, String label) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE9DAC1), // Light brown background for boxes
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFE9DAC1), // Light brown background
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          'Status: Normal/ Slight fever',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTemperatureRanges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _buildRangeBox('36°', 'Date | Time', 'Normal'),
        _buildRangeBox('37°', 'Date | Time', 'Low-grade'),
        _buildRangeBox('39°', 'Date | Time', 'Critical'),
      ],
    );
  }

  Widget _buildRangeBox(String temperature, String dateTime, String status) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE9DAC1), // Light brown background for boxes
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            temperature,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(
            dateTime,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            status,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Color(0xFFE9DAC1), // Lighter brown for button
        borderRadius: BorderRadius.circular(20), // More rounded corners
      ),
      child: Center(
        child: Text(
          'View Trends',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}
