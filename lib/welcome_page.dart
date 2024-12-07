import 'package:flutter/material.dart';
import 'login_patient.dart'; // Import the login page for user
import 'login_specialist.dart'; // Import the login page for user


class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/background.png', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(), // Space for alignment

                // Welcome Text
                Column(
                  children: [
                    Text(
                      'Welcome to VitalSense',
                      style: TextStyle(
                        color: Color(0xFF373737),
                        fontSize: 32,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your personal health companion for a healthier you!',
                      style: TextStyle(
                        color: Color(0xFF343434),
                        fontSize: 19,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),

                // Role Selection
                Container(
                  constraints: const BoxConstraints(maxWidth: 336),
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
                                color: Color(0xFF343434),
                                fontSize: 28,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 21),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 42,
                                vertical: 63,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                            horizontal: 30,
                            vertical: 51,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
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

                const SizedBox(), // Space for alignment
              ],
            ),
          ),
        ],
      ),
    );
  }
}
