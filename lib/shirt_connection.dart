import 'package:flutter/material.dart';

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
    final maxHeight = MediaQuery.of(context).size.height; // Get screen height

    return Scaffold(
      backgroundColor: Colors.white, // Set background color of entire screen to white
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 412, // Fixed width
            maxHeight: maxHeight, // Responsive height
          ),
          child: Container(
            width: double.infinity, // Full width of the container
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 206, 226, 206), // SkyBlue color for the frame
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    // Add your connection logic here
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Connect Shirt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade200, // Light green button
                    foregroundColor: Colors.black, // Text color
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
