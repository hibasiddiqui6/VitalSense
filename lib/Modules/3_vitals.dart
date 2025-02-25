import 'package:flutter/material.dart';
import 'ecg_graph.dart'; // Import the ECG graph screen
import 'temperature.dart'; // Import the Temperature page
import 'respiration.dart'; // Import the Temperature page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black), // Menu icon color
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hi! Username
            Text(
              'Hi! Username',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Gender, Age, Weight Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard('Female', 'Gender',
                    Color.fromARGB(255, 218, 151, 167)), // Orange Accent
                SizedBox(width: 7), // Add spacing between Gender and Age
                _buildInfoCard('21', 'Age',
                    Color.fromARGB(255, 218, 189, 151)), // Amber Accent
                SizedBox(width: 7), // Add spacing between Age and Weight
                _buildInfoCard(
                    '54.4', 'Weight', Color(0xFF9CCC65)), // Light Green Accent
              ],
            ),

            SizedBox(height: 15),

            // ECG Section
            _buildECGCard(context),
            SizedBox(height: 15),

            // Respiration and Temperature Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard2("13 BPM", "Respiration", Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RespirationPage()), // Navigate to the Respiration page
                  );
                }),
                _buildInfoCard2("99°F", "Temperature", Colors.redAccent, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TemperaturePage()), // Navigate to the Temperature page
                  );
                }),
              ],
            ),

            SizedBox(height: 15),

            // Current Health Performance
            _buildHealthPerformanceCard(),
          ],
        ),
      ),
    );
  }

  // Function to build small information cards
  Widget _buildInfoCard(String value, String label, Color color) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular background with blur effect
          Positioned(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Lightened version of the color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 28.0,
                    spreadRadius: 23.0,
                  ),
                ],
              ),
            ),
          ),
          // Text Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildECGCard(BuildContext context) {
    return Container(
      height: 160, // Increased height
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(4, 4),
          ),
        ],
        border: Border.all(width: 0, color: Colors.transparent),
        gradient: LinearGradient(
          colors: [Color(0xFF99B88D), Color.fromARGB(255, 193, 219, 188)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ECG',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 80, // Adjusted height
                        width: double.infinity,
                        child: CustomPaint(
                          painter: ECGLinePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ECGScreen()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Health Performance Card Widget
  Widget _buildHealthPerformanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 154, 142, 142),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Health Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '70%',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Moderate',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Drawer Widget
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF9CCC65), // Customize the header color
            ),
            child: Text(
              'Username', // Display the username here
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _buildDrawerItem(Icons.person, 'My Profile', context),
          _buildDrawerItem(Icons.contacts, 'Trusted Contacts', context),
          _buildDrawerItem(Icons.trending_up, 'Trends and History', context),
          _buildDrawerItem(Icons.file_present, 'Reports', context),
          _buildDrawerItem(Icons.settings, 'Settings', context),
          _buildDrawerItem(Icons.info, 'About', context),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        // Navigate to the respective screen
      },
    );
  }
}

// **Fixed ECGLinePainter**
class ECGLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // **Grid**
    double gridSize = 20;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // **ECG waveform with adjusted height**
    final path = Path();
    path.moveTo(0, size.height * 0.7); // Start from 70% height

    double x = 0;
    while (x < size.width) {
      path.relativeLineTo(4, -15); // Adjusted peak height
      path.relativeLineTo(4, 30);
      path.relativeLineTo(4, -15);
      path.relativeLineTo(4, 0);
      x += 16;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Function to build small information cards with gradient background and a Details button
// Widget _buildInfoCard2(String value, String label, Color color, VoidCallback onPressed) {
//   return Padding(
//     padding: const EdgeInsets.all(8.0), // Adds padding around each card
//     child: Container(
//       width: 172,
//       height: 180,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [color.withOpacity(0.5), color.withOpacity(0.0)], // Gradient effect
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8.0,
//             offset: Offset(3, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black87),
//           ),
//           SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.black),
//           ),
//           SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: onPressed,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color.fromARGB(255, 176, 85, 85), // Matches your UI
//               padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(50),
//               ),
//             ),
//             child: Text("Details", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     ),
//   );
// }

Widget _buildInfoCard2(
    String value, String label, Color color, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.all(8.0), // Adds padding around each card
    child: Container(
      width: 172,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.5),
            color.withOpacity(0.0)
          ], // Gradient effect
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w300, color: Colors.black),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: onPressed, // Calls the provided callback function
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color.fromARGB(255, 176, 85, 85), // Matches your UI
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text("Details", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
