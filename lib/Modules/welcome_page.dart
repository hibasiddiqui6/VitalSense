import 'package:flutter/material.dart';
import 'login_patient.dart'; // Import the login page for user
import 'login_specialist.dart'; // Import the login page for user

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 412, // Fixed width for the app
            constraints: BoxConstraints(
              maxHeight: screenHeight - 60 , // Use full screen height responsively
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black), // Optional: border for visibility
              color: Colors.white, // Background color
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/background.png', // Replace with your image path
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical:90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Welcome Text
                      Column(
                        children: [
                          Text(
                            'Welcome to VitalSense',
                            style: TextStyle(
                              color: const Color(0xFF373737),
                              fontSize: 32,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your personal health companion for a healthier you!',
                            style: TextStyle(
                              color: const Color(0xFF343434),
                              fontSize: 19,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),

                      // Role Selection
                      Container(
                        constraints: const BoxConstraints(maxWidth: 336),
                        margin: const EdgeInsets.symmetric(vertical: 150),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Patient Role Box
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PatientLogin(),
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
                                  MaterialPageRoute(
                                    builder: (context) => const SpecialistLogin(),
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
    );
  }
}
