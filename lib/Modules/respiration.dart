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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
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
                      child: Icon(Icons.arrow_back, size: screenWidth * 0.06, color: Colors.black),
                    ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    margin: EdgeInsets.only(left: screenWidth * 0.038),
                    child: Text(
                      "RESPIRATION",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
             SizedBox(height: screenHeight * 0.02),

              // BPM Card with Gradient Border
              Container(
                width: screenWidth,
                height: screenHeight*0.2,
                padding: EdgeInsets.all(screenWidth*0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 150, 133, 115),
                      Color.fromARGB(255, 201, 192, 183)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth*0.05),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth*0.1, vertical: screenHeight*0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth*0.045),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      showError
                          ? Text(
                              respirationRate,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth*0.08,
                                color: Colors.black,
                              ),
                            )
                          : isFetching
                              ? const CircularProgressIndicator() // Show loading while fetching
                              : Text(
                                  respirationRate,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth*0.1,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                      Icon(Icons.air, size: screenWidth*0.15, color: Color.fromARGB(136, 0, 0, 0)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenWidth * 0.05), // Increased spacing below

              // Gender, Age, Weight Section
              Container(
                width: screenWidth, // Full width
                height: screenWidth*0.25, // Increased height
                padding: EdgeInsets.all(screenWidth* 0.03), // Padding inside the main box
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
                  borderRadius: BorderRadius.circular(screenWidth*0.05), // Rounded corners
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

              SizedBox(height: screenWidth * 0.05), // Increased spacing below


              // Status Card
              Container(
                padding:EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                  borderRadius: BorderRadius.circular(screenWidth*0.04),
                ),
                child: Center(
                  child: Text(
                    "Status: Normal/Rapid",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth*0.04,
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
                  borderRadius: BorderRadius.circular(screenWidth*0.04),
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
                      borderRadius: BorderRadius.circular(screenWidth*0.04),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "View Trends",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth*0.04,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Expanded(
      child: Container(
        margin:  EdgeInsets.symmetric(horizontal: screenWidth*0.01),
        padding: EdgeInsets.symmetric(vertical: screenHeight*0.015),
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(screenWidth*0.04),
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
                fontSize: screenWidth*0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: screenWidth*0.03,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight*0.015),
      child: RichText(
        text: TextSpan(
          text: "$title ",
          style: GoogleFonts.poppins(
            fontSize: screenWidth*0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(
                fontSize: screenWidth*0.04,
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
