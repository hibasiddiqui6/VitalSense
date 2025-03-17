import 'package:flutter/material.dart';
import 'login_patient.dart'; // Import the login page for user
import 'login_specialist.dart'; // Import the login page for specialist
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.08,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double screenWidth = MediaQuery.of(context).size.width;
                      bool isLargeScreen = screenWidth > 700;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Welcome to VitalSense',
                                  style: GoogleFonts.lato(
                                    fontSize: screenWidth * 0.07,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Your personal health companion for a healthier you!',
                                  style: TextStyle(
                                    color: const Color(0xFF343434),
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 50),
                                Row(
                                  mainAxisAlignment: isLargeScreen
                                      ? MainAxisAlignment.spaceBetween
                                      : MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: _roleSelectionBox(
                                        context,
                                        'Patient',
                                        const PatientLogin(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _roleSelectionBox(
                                        context,
                                        'Health Specialist',
                                        const SpecialistLogin(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelectionBox(BuildContext context, String role, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
        width: double.infinity, // Makes sure it takes full available space
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.width * 0.09,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Continue as',
              style: TextStyle(
                color: const Color(0xFF343434),
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              role,
              style: TextStyle(
                color: Colors.black,
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
