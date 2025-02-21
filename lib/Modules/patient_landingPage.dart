import 'package:flutter/material.dart';
import 'wifi_screen.dart'; // Import the file containing WifiCredentialScreen
import 'welcome_page.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background for the outer scaffold
      body: Center(
        child: Container(
          width: 400, // Fixed width for the mobile frame (Pixel 9 width)
          height: 800, // Responsive height
          decoration: BoxDecoration(
            color: Colors.transparent, // Transparent background for the frame
            borderRadius: BorderRadius.circular(45), // Round corners for the mobile frame
            border: Border.all(
              color: Colors.black, // Border color for the mobile frame
              width: 5, // Border width for the mobile frame
            ),
          ),
          child: Builder(
            builder: (context) {
              return Scaffold(
                drawer: ClipRRect(
                  borderRadius: BorderRadius.circular(45), // Set the desired border radius
                  child: Drawer( // Add side menu (drawer) inside the frame
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        const DrawerHeader(
                          child: Text('Vital Sense'),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 206, 226, 206),
                          ),
                        ),
                        ListTile(
                          title: const Text('Logout'),
                          onTap: () {
                            // Use Builder to ensure that the context is under a Scaffold
                            Navigator.pop(context); // Close the drawer
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const WelcomePage()), // Navigate to WelcomePage
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                body: Container(
                  width: 400, // Fixed width for the content container inside the frame
                  height: 800, // Same height as the frame
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Padding inside the frame
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 206, 226, 206), // Background color of the frame content
                    borderRadius: BorderRadius.circular(45), // Rounded corners for the content
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                    children: [
                      // Custom AppBar inside the frame
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 20.0, 15, 0),
                        child: Row(
                          children: [
                            Builder(
                              builder: (BuildContext context) {
                                return IconButton(
                                  icon: const Icon(Icons.menu, color: Colors.black54),
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer(); // Open the side menu (drawer)
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // Space between AppBar and content
                      Padding(
                        padding: const EdgeInsets.only(top: 150), // Adjust top padding to move content lower
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the following content vertically
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
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ConnectWifiScreen()),
                                  );
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
