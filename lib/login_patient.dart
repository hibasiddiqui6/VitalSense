import 'package:flutter/material.dart';
import 'register_patient.dart'; // Import the login page for user

class PatientLogin extends StatelessWidget {
  const PatientLogin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF4), // Set background color
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(33, 79, 33, 297),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the previous screen
                  },
                ),
                const SizedBox(height: 36),
                const Center(
                  child: Text(
                    'VitalSense',
                    style: TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 65),
                const Padding(
                  padding: EdgeInsets.only(left: 19),
                  child: Text(
                    'Login as a Patient',
                    style: TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Form(
                  child: Column(
                    children: [
                      Container(
                        width: 312,
                        padding: const EdgeInsets.fromLTRB(34, 14, 34, 25),
                        color: const Color(0xFFABBEA7),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: InputBorder.none,
                            labelStyle: TextStyle(
                              color: Color(0xFF3E3838),
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        width: 312,
                        padding: const EdgeInsets.fromLTRB(34, 14, 34, 26),
                        color: const Color(0xFFABBEA7),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: InputBorder.none,
                            labelStyle: TextStyle(
                              color: Color(0xFF3E3838),
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(height: 35),
                      Padding(
                        padding: const EdgeInsets.only(left: 11),
                        child: Container(
                          width: 312,
                          height: 70, // Adjust height as needed
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFBFBF4), // Gradient start color
                                Color(0xFF5C714C), // Gradient end color
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, // Make button transparent
                              elevation: 0, // Remove default elevation
                              shadowColor: Colors.transparent, // Remove default shadow
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                color: Color(0xFF434242),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 57),
                const Center(
                  child: Text(
                    'Don\'t have an account?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to the PatientRegister page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PatientRegister()),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color(0xFF3E3838),
                        fontSize: 18,
                        fontFamily: 'Inter',
                      ),
                    ),
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

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFFABBEA7),
  scaffoldBackgroundColor: const Color(0xFFFBFBF4), // Background color
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFF3E3838),
      fontSize: 18,
    ),
    headlineLarge: TextStyle(
      color: Color(0xFF373737),
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      color: Color(0xFF373737),
      fontSize: 24,
      fontWeight: FontWeight.w500,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF434242),
      elevation: 20,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 70,
        vertical: 18,
      ),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: InputBorder.none,
    labelStyle: TextStyle(
      color: Color(0xFF3E3838),
      fontSize: 18,
    ),
  ),
);
