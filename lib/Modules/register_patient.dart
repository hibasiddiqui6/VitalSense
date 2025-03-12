import 'package:flutter/material.dart';
import 'dart:async'; // For delayed navigation
import 'patient_landing_page.dart'; // Import the page where you want to navigate after registration
import 'package:vitalsense/services/api_client.dart'; // Import ApiClient for API interaction
import 'package:google_fonts/google_fonts.dart';
import 'login_patient.dart';

class PatientRegister extends StatefulWidget {
  const PatientRegister({super.key});

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
  String contact = '';

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>(); // For form validation
  final GlobalKey _genderKey = GlobalKey();

  bool _isLoading = false;

  // A list to store the user details
  List<String> patientDetails = [];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: screenWidth, // 90% of screen width
          height: screenHeight, // 90% of screen height
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 206, 226, 206),
          ),

          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Center(
                // Ensures the form stays centered
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Centers vertically
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Centers horizontally
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: screenWidth *
                              0.07, // 8% of screen width for responsiveness
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    SizedBox(
                        height:
                            screenHeight * 0.04), // Spacing below back button
                    // Title
                    const Center(child: TitleWidget()),
                    SizedBox(height: screenHeight * 0.07),

                    // Registration Title
                    const Center(child: RegisterPatientTitle()),
                    SizedBox(height: screenHeight * 0.02),

                    // Form inside a Centered Column
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Full Name
                          _buildTextField(
                            label: 'Full Name',
                            onChanged: (value) => fullName = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                                return 'Name must contain only letters and spaces';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Gender Dropdown
                          _buildDropdownField(
                            key: _genderKey,
                            label: 'Gender',
                            value: gender,
                            options: ['Male', 'Female', 'Other'],
                            onChanged: (value) {
                              setState(() {
                                gender = value;
                              });
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Age Field
                          _buildTextField(
                            label: 'Age',
                            onChanged: (value) => age = value,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Age is required';
                              }
                              if (!RegExp(r"^\d+$").hasMatch(value)) {
                                return 'Age must be a number';
                              }
                              int ageValue = int.parse(value);
                              if (ageValue < 0 || ageValue > 120) {
                                return 'Age must be between 0 and 120';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Email Field
                          _buildTextField(
                            label: 'Email',
                            onChanged: (value) => email = value,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                  .hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Contact Field
                          _buildTextField(
                            label: 'Contact Number',
                            onChanged: (value) => contact = value,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Contact number is required';
                              }
                              if (value.length != 11) {
                                return 'Contact number must be 11 characters';
                              }
                              if (!RegExp(r"^\d{11}$").hasMatch(value)) {
                                return 'Contact number must be numeric';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Password Field
                          _buildTextField(
                            label: 'Password',
                            obscureText: obscurePassword,
                            onChanged: (value) => password = value,
                            suffixIcon: _buildPasswordToggle(() {
                              setState(
                                  () => obscurePassword = !obscurePassword);
                            }),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return 'Password must contain at least one uppercase letter';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return 'Password must contain at least one number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Confirm Password Field
                          _buildTextField(
                            label: 'Confirm Password',
                            obscureText: obscureConfirmPassword,
                            onChanged: (value) => confirmPassword = value,
                            suffixIcon: _buildPasswordToggle(() {
                              setState(() => obscureConfirmPassword =
                                  !obscureConfirmPassword);
                            }),
                            validator: (value) => value != password
                                ? 'Passwords do not match'
                                : null,
                          ),
                          SizedBox(height: screenHeight * 0.03),

                          // Register Button
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.2,
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                backgroundColor: const Color(0xFF5C714C),
                              ),
                              // Function to handle form submission and patient registration
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        // Collect user details
                                        patientDetails = [
                                          fullName,
                                          email,
                                          password,
                                          gender,
                                          age,
                                          contact,
                                        ];

                                        try {
                                          // Make API call
                                          ApiClient apiClient = ApiClient();
                                          var response =
                                              await apiClient.registerPatient(
                                                  fullName,
                                                  gender,
                                                  int.parse(age),
                                                  email,
                                                  password,
                                                  contact);

                                          // Handle response
                                          if (response.containsKey('error')) {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Registration Failed'),
                                                  content: Text(
                                                      'Error: ${response['error']}'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            // Success logic
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Registration Successful'),
                                                  content: const Text(
                                                      'The patient has been registered successfully!'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            // Navigate after success
                                            Future.delayed(
                                                const Duration(seconds: 3), () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SmartShirtScreen()),
                                              );
                                            });
                                          }
                                        } catch (e) {
                                          print('Error: $e');
                                        }
                                      }
                                    },

                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Color(0xFF434242),
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
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

  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.07, // Responsive height
      width: MediaQuery.of(context).size.width * 0.85, // Responsive width
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            0.05, // Adjust padding dynamically
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        obscureText: obscureText,
        onChanged: onChanged,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
      onPressed: onPressed,
    );
  }

  Widget _buildDropdownField({
    required GlobalKey key,
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    bool enabled = true,
  }) {
    return Container(
      key: key,
      height: MediaQuery.of(context).size.height * 0.07, // Responsive height
      width: MediaQuery.of(context).size.width * 0.85, // Responsive width
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05, // Dynamic padding
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1)
            .withOpacity(enabled ? 0.6 : 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, color: Colors.black),
          contentPadding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height *
                0.015, // Adjust content padding dynamically
            horizontal: 5,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
        ),
        items: options
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option,
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width *
                              0.04)), // Responsive text size
                ))
            .toList(),
        onChanged: enabled ? (value) => onChanged(value!) : null,
        validator: (value) {
          if (enabled && (value == null || value.isEmpty)) {
            return 'Please select a $label';
          }
          return null;
        },
      ),
    );
  }
}

class RegisterPatientTitle extends StatelessWidget {
  const RegisterPatientTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.fromLTRB(
        screenWidth * 0.05, // Responsive left margin
        screenHeight * 0.03, // Responsive top margin
        0,
        0,
      ), // Adjustable margin
      child: Text(
        'Register as a Patient',
        style: TextStyle(
          color: const Color(0xFF373737),
          fontSize: screenWidth * 0.06, // Responsive font size
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(
        left: screenWidth * 0.03, // 3% of screen width for left margin
        top: screenHeight * 0.06, // 6% of screen height for top margin
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          size: screenWidth * 0.07, // Responsive icon size
        ), // Slightly larger icon for better visibility
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
