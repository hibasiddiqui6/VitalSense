import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/patient_drawer.dart';
import '../widgets/specialist_drawer.dart'; // Importing specialist drawer
import 'package:shared_preferences/shared_preferences.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  _AboutUsState createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  String fullName = "Loading...";
  String email = "example@example.com";
  String role = "-"; // Default to patient, will be loaded

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  /// Load user details for drawer and role
  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
      role = prefs.getString("role") ?? "-"; // Load role
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Hamburger color
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: role == 'specialist'
            ? SpecialistDrawer(
                fullName: fullName,
                email: email,
              )
            : PatientDrawer(
                fullName: fullName,
                email: email,
              ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.032, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "About Us",
              style: TextStyle(
                  fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.01),

            // University Logos Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Image.asset(
                      "assets/engineering.png",
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.2,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Image not found",
                            style: TextStyle(color: Colors.red));
                      },
                    ),
                    const Text(
                      "Fabricated By",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(width: screenWidth * 0.08),
                Column(
                  children: [
                    Image.asset(
                      "assets/uit.png",
                      width: screenWidth * 0.3,
                      height: screenHeight * 0.2,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Image not found",
                            style: TextStyle(color: Colors.red));
                      },
                    ),
                    const Text(
                      "Developed By",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.04),

            // Description
            Text(
              "Welcome to VitalSense",
              style: TextStyle(
                  fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Your go-to app for real-time health monitoring. Developed by UIT University's Software Engineering students, VitaSense connects with a smart shirt to track ECG, respiration, and temperature, delivering continuous health insights. "
              "Our app offers secure data storage, AI-driven alerts, and dual access for healthcare providers, making proactive health management easy and accessible.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: screenWidth * 0.028),
            ),

            SizedBox(height: screenWidth * 0.04),

            // Contact and Follow Us section in a Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Contact Details (Left)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "+92-033000332",
                      style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "vitalsense@gmail.com",
                      style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Karachi, Pakistan",
                      style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Follow Us (Right)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Follow us:",
                      style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: screenHeight * 0.016),
                    Row(
                      children: [
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.facebook,
                              color: Colors.black54, size: screenWidth * 0.056),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.twitter,
                              color: Colors.black54, size: screenWidth * 0.056),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.instagram,
                              color: Colors.black54, size: screenWidth * 0.056),
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
