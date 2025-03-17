import 'package:flutter/material.dart';
import 'patient_wifi_setup.dart'; // Import the file containing WifiCredentialScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SmartShirtScreen(),
    );
  }
}

class SmartShirtScreen extends StatelessWidget {
  const SmartShirtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.of(context).size.height - 60; // Get screen height

    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 0, 0, 0), // Set background color of entire screen to white
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 412, // Fixed width
            maxHeight: maxHeight, // Responsive height
          ),
          child: Stack(
            children: [
              // Main content inside the frame
              Container(
                width: double.infinity, // Full width of the container
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 206, 226, 206), // SkyBlue color for the frame
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // Space for back button
                    const Text(
                      'Smart Shirt not Connected',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No readings to Display!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientWifiSetup(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Connect Shirt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green.shade200, // Light green button
                        foregroundColor: Colors.black, // Text color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Back button positioned at the top left inside the frame
              Positioned(
                top: 60,
                left: 40,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () {
                    Navigator.pop(context); // Go back to the previous screen
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
