import 'package:flutter/material.dart';
import 'package:vitalsense/Modules/respiration_trends.dart';
import 'package:vitalsense/Modules/temperature_trends.dart';

class SpecialistTrendsSelectorScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const SpecialistTrendsSelectorScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
    Widget build(BuildContext context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenHeight = MediaQuery.of(context).size.height;

      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F4),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 134, 170, 122),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "Trends for $patientName",
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(screenWidth * 0.032),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RespChartScreen(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
                style: CustomButtonStyle.elevatedButtonStyle(context),
                child: const Text("Respiration Trends / History"),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TempChartScreen(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
                style: CustomButtonStyle.elevatedButtonStyle(context),
                child: const Text("Temperature Trends / History"),
              ),
            ],
          ),
        ),
      );
    }
}

class CustomButtonStyle {
  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 90, 145, 85),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.024,
      ),
      textStyle: TextStyle(
        fontSize: screenWidth * 0.032,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.024),
      ),
      elevation: 4,
    );
  }
}
