import 'package:flutter/material.dart';
import 'login_patient.dart'; // Import the login page for user
import 'login_specialist.dart'; // Import the login page for user
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400, // Frame width resembling the Google Pixel 9 screen size
            height: 800, // Fixed height for Google Pixel 9
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(45),
              border: Border.all(
                color: Colors.black, // Black border for the mobile frame
                width: 5, // Width of the border to make it look realistic
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 10),
                  blurRadius: 15,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/background.png', // Replace with your image path
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Content inside the frame
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Welcome Text
                        Column(
                          children: [
                            Text(
                              'Welcome to VitalSense',
                              style: GoogleFonts.lato(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Add margin to the SizedBox widget containing the text
                            Container(
                              margin: const EdgeInsets.fromLTRB(18, 0, 0, 0), // Margin added here
                              child: Text(
                                'Your personal health companion for a healthier you!',
                                style: TextStyle(
                                  color: const Color(0xFF343434),
                                  fontSize: 19,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),

                        // Role Selection
                        Container(
                          constraints: const BoxConstraints(maxWidth: 336),
                          margin: const EdgeInsets.symmetric(vertical: 70),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Patient Role Box
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          const PatientLogin(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      
                                      },
                                      transitionDuration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Continue as',
                                      style: TextStyle(
                                        color: const Color(0xFF343434),
                                        fontSize: 28,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 39,
                                        vertical: 63,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.30),
                                            offset: const Offset(20, 10),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Patient',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Health Specialist Role Box
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          const SpecialistLogin(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 55),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 48.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        offset: const Offset(20, 10),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Health\nSpecialist',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
