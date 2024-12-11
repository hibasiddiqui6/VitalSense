import 'package:flutter/material.dart';

class PatientRegister extends StatefulWidget {
  const PatientRegister({Key? key}) : super(key: key);

  @override
  _PatientRegisterState createState() => _PatientRegisterState();
}

class _PatientRegisterState extends State<PatientRegister> {
  // Define variables for each input
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String gender = '';
  String age = '';

  bool obscureText = true; // To manage password visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF4), // Set background color
      body: Center(
        child: Container(
          width: 412,
          height: 850,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 206, 226, 206), // Sky green background color for the fixed frame size
            borderRadius: BorderRadius.circular(20), // Optional: curve the corners of the container
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(33, 0, 33, 50),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Container(
                      margin: const EdgeInsets.fromLTRB(4, 85, 0, 0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to the previous screen
                        },
                      ),
                    ),
                    const SizedBox(),
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
                    const SizedBox(),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 20, 0, 0),
                      child: Text(
                        'Register as a Patient',
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
                          // Name Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              textAlign: TextAlign.start, // Align text to the left
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 7,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 17, // Adjust font size for input text
                                fontFamily: 'Inter',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  fullName = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Gender Dropdown Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: InputBorder.none,
                                
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 9,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              padding: EdgeInsets.only(bottom: 10),
                              items: ['Male', 'Female']
                                  .map((gender) => DropdownMenuItem<String>(
                                        value: gender,
                                        child: Text(gender),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  gender = value ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Age Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              textAlign: TextAlign.start, // Align text to the left
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                border: InputBorder.none,
                                
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 9,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 10, // Adjust font size for input text
                                fontFamily: 'Inter',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  age = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Email Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              textAlign: TextAlign.start, // Align text to the left
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 9,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 11, // Adjust font size for input text
                                fontFamily: 'Inter',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                setState(() {
                                  email = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Password Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              textAlign: TextAlign.start, // Align text to the left
                              decoration: InputDecoration(
                                labelText: 'Password',
                               
                                border: InputBorder.none,
                                labelStyle: const TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 9,
                                  fontFamily: 'Inter',
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      obscureText = !obscureText;
                                    });
                                  },
                                ),
                              ),
                              obscureText: obscureText,
                              style: const TextStyle(
                                fontSize: 11, // Adjust font size for input text
                                fontFamily: 'Inter',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  password = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Confirm Password Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              textAlign: TextAlign.start, // Align text to the left
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                
                                border: InputBorder.none,
                                labelStyle: const TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 9,
                                  fontFamily: 'Inter',
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      obscureText = !obscureText;
                                    });
                                  },
                                ),
                              ),
                              obscureText: obscureText,
                              style: const TextStyle(
                                fontSize: 7, // Adjust font size for input text
                                fontFamily: 'Inter',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  confirmPassword = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 35),
                          // Register Button
                          Padding(
                            padding: const EdgeInsets.only(left: 11),
                            child: Container(
                              width: 250,
                              height: 40, // Adjust height as needed
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
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
                                onPressed: () {
                                  // Handle the registration logic here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent, // Make button transparent
                                  elevation: 0, // Remove default elevation
                                  shadowColor: Colors.transparent, // Remove default shadow
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: const Text(
                                  'Register',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
