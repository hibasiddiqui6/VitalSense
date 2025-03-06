import 'package:flutter/material.dart';
import 'all_vitals.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AboutUsPage(),
  ));
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "About Us",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // University Logos Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Image.asset(
                      "assets/engineering.png",
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Image not found", style: TextStyle(color: Colors.red));
                      },
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Fabricated By",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  children: [
                    Image.asset(
                      "assets/uit.png",
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Image not found", style: TextStyle(color: Colors.red));
                      },
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Developed By",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            const Text(
              "Welcome to VitalSense",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your go-to app for real-time health monitoring. Developed by UIT University's Software Engineering students, VitaSense connects with a smart shirt to track ECG, respiration, and temperature, delivering continuous health insights. "
              "Our app offers secure data storage, AI-driven alerts, and dual access for healthcare providers, making proactive health management easy and accessible.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            // Contact and Follow Us section in a Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Contact Details (Left)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("+92-033000332"),
                    Text("vitalsense@gmail.com"),
                    Text("Karachi, Pakistan"),
                  ],
                ),

                // Follow Us (Right)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Follow us:",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.black54, size: 28),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.twitter, color: Colors.black54, size: 28),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.black54, size: 28),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
