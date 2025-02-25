import 'package:flutter/material.dart';

void main() {
  runApp(RespirationPage());
}

class RespirationPage extends StatelessWidget {
  const RespirationPage({super.key});

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
                _buildRespirationCard(),
                SizedBox(height: 10),
                _buildDetailsBoxes(), // Use separate boxes
                SizedBox(height: 10),
                _buildStatusCard(),
                SizedBox(height: 10),
                _buildRangeCard(),
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
          'RESPIRATION',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildRespirationCard() {
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
            '13 BPM',
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(width: 20),
          Icon(Icons.directions_run,
              size: 40, color: Colors.black), // Placeholder for lungs icon
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
          'Status: Normal/Rapid',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildRangeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Normal: 12-20 BPM',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          Divider(color: Colors.grey[300]), // Thin line
          Text(
            'Slow: < 12 BPM',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          Divider(color: Colors.grey[300]), // Thin line
          Text(
            'Rapid: > 20 BPM',
            style: TextStyle(fontSize: 16, color: Colors.black),
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
