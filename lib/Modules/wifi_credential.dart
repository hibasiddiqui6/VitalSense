import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ConnectWifiScreen(),
    );
  }
}

class ConnectWifiScreen extends StatelessWidget {
  const ConnectWifiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - 60; // Calculate height for responsiveness

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 8, 8), // Dark background for the overall screen
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 412, // Fixed width for the content frame
            constraints: BoxConstraints(
              maxHeight: maxHeight, // Responsive height based on screen size
            ),
            padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 70.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255), // Light background for the frame
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Stack(
              children: [
                // Back button inside the frame, position adjustable
                Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 30, 10),
                   // Adjust this to change the horizontal position
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      Navigator.of(context).pop(); // Go back to the previous screen
                    },
                  ),
                ),
                // Main content within the frame
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, // Center the content
                  children: [
                    const SizedBox(height: 50), // Adjust space below back icon
                    const Text(
                      'Connect Wifi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '#Instructions for Wifi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Wifi SSID TextField with fixed width
                    Container(
                      width: 350, // Adjust the width for the input box
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter Wifi SSID',
                          fillColor: Colors.green.shade200,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password TextField with fixed width
                    Container(
                      width: 350, // Adjust the width for the input box
                      child: TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          fillColor: Colors.green.shade200,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Connect Button
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              backgroundColor: Colors.green.shade100,
                              content: SizedBox(
                                width: 300,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'ID: ######',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Smart Shirt Connected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade300,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 10),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'OK',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Connect',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
