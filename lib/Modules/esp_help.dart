import 'package:flutter/material.dart';
import '../widgets/patient_drawer.dart';
import '../widgets/specialist_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EspHelp extends StatefulWidget {
  const EspHelp({super.key});

  @override
  _EspHelpState createState() => _EspHelpState();
}

class _EspHelpState extends State<EspHelp> {
  String fullName = "Loading...";
  String email = "example@example.com";
  String role = "-";

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
      role = prefs.getString("role") ?? "-";
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 239, 238, 229),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: role == 'specialist'
            ? SpecialistDrawer(fullName: fullName, email: email)
            : PatientDrawer(fullName: fullName, email: email),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.032, vertical: screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "ESP32 Connection Help",
              style: TextStyle(
                  fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.04),
            Text(
              "Follow these steps if Wi-Fi connection is lost or Wi-Fi is no longer available:",
              style: TextStyle(
                  fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
                "1️⃣ Activate the ESP device.\n"
                "2️⃣ Open Wi-Fi settings on your phone.\n"
                "3️⃣ Look for the network named 'ESP32_Setup' and connect to it.\n"
                "4️⃣ Once connected, select your home Wi-Fi and enter its password.\n\n"
                "🔄 Finally, disconnect and reconnect the ESP device and relaunch the app.",
                style: TextStyle(fontSize: screenWidth * 0.032),
              ),
          ],
        ),
      ),
    );
  }
}
