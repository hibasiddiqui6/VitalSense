import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RespirationPage extends StatefulWidget {
  final String? gender;
  final String? age;
  final String? weight;

  const RespirationPage({
    super.key,
    this.gender, // optional param
    this.age,    // optional param
    this.weight, // optional param
  });

  @override
  _RespirationPageState createState() => _RespirationPageState();
}

class _RespirationPageState extends State<RespirationPage> {
  String respirationRate = "Loading...";
  bool isFetching = true;
  bool showError = false;
  String gender = "-";
  String age = "-";
  String weight = "-";

  @override
  void initState() {
    super.initState();
    fetchRespirationRate();
    _loadUserDetailsOrUseParams(); // Load from shared preferences or use passed params
  }

  /// **Fetch latest respiration rate**
  Future<void> fetchRespirationRate() async {
    try {
      final data = await ApiClient().getSensorData();

      if (data.containsKey("error")) {
        setState(() {
          showError = true;
          respirationRate = "-";
        });
        return;
      }

      setState(() {
        respirationRate = "${data['respiration_rate']} BPM";
        isFetching = false;
        showError = false;
      });
    } catch (e) {
      print("❌ Failed to fetch respiration rate: $e");
      setState(() {
        showError = true;
        respirationRate = "Error";
      });
    }
  }

  /// Load gender, age, weight
  Future<void> _loadUserDetailsOrUseParams() async {
    if (widget.gender != null && widget.age != null && widget.weight != null) {
      // ✅ Case: Viewing from Specialist Insights - use passed parameters
      setState(() {
        gender = widget.gender!;
        age = widget.age!;
        weight = widget.weight!;
      });
    } else {
      // ✅ Case: Patient Dashboard - load from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        gender = prefs.getString("gender") ?? "-";
        age = prefs.getString("age") ?? "-";
        weight = prefs.getString("weight") ?? "-";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button and Title
              Row(
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    child: Text(
                      "RESPIRATION",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // BPM Card with Gradient Border
              Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 150, 133, 115),
                      Color.fromARGB(255, 201, 192, 183)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      showError
                          ? Text(
                              respirationRate,
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                color: Colors.black,
                              ),
                            )
                          : isFetching
                              ? const CircularProgressIndicator() // Show loading while fetching
                              : Text(
                                  respirationRate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 55,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                      const Icon(Icons.air, size: 60, color: Color.fromARGB(136, 0, 0, 0)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20), // Increased spacing below

              // Gender, Age, Weight Section
              Container(
                width: double.infinity, // Full width
                height: 120, // Increased height
                padding: const EdgeInsets.all(12), // Padding inside the main box
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 219, 215, 208), // Soft greenish-white
                      Color.fromARGB(255, 193, 177, 158), // Light beige
                      Color.fromARGB(255, 156, 144, 123), // Muted brown for depth
                    ], // Mesh gradient effect
                  ),
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space between info cards
                  children: [
                    _infoCard(gender, "Gender"),
                    _infoCard(age, "Age"),
                    _infoCard(weight, "Weight"),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Increased spacing below


              // Status Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "Status: Normal/Rapid",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // BPM Range Info (Fixed Size)
              Container(
                width: double.infinity, // Ensure full width
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _statusText("Normal:", "12-20 BPM"),
                    _statusText("Slow:", "< 12 BPM"),
                    _statusText("Rapid:", "> 20 BPM"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // View Trends Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[300],
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "View Trends",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
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

  // Widget for Gender, Age, Weight Cards
  Widget _infoCard(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for BPM status info
  Widget _statusText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: "$title ",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
