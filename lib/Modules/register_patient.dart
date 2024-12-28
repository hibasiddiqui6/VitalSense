import 'package:flutter/material.dart';
import 'dart:async'; // For delayed navigation
import 'patient_landingPage.dart'; // Import the page where you want to navigate after registration
import 'package:vitalsense/services/api_client.dart';  // Import ApiClient for API interaction
import 'package:google_fonts/google_fonts.dart';

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

  // A list to store the user details
  List<String> patientDetails = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 400, // Fixed width (approximate size of Pixel 9)
          height: 800, // Full screen height minus top margin
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 174, 238, 123),
            borderRadius: BorderRadius.circular(45), // Rounded corners for the frame
            border: Border.all(
              width: 5, // 5px border width
              color: Colors.black, // Black border for Pixel 9 frame look
            ),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button placed outside the Form widget
                  Container(
                    margin: const EdgeInsets.fromLTRB(10, 49, 0, 0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to the previous screen
                      },
                    ),
                  ),
                  Center(
                    child: Text(
                      'VitalSense',
                      style: GoogleFonts.lato(
                        color: Color(0xFF373737),
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 25, 0, 0), // You can adjust the margin as needed
                    child: const Text(
                      'Register as a Patient', // Changed to "Patient"
                      style: TextStyle(
                        color: Color(0xFF373737),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Form widget containing other fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
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
                        const SizedBox(height: 30),
                        // Gender Dropdown
                        _buildGenderDropdown(
                          label: 'Gender',
                          value: gender,
                          options: ['Male', 'Female', 'Other'],
                          onChanged: (value) {
                            setState(() {
                              gender = value ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 30),
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
                        const SizedBox(height: 30),
                        // Email Field
                        _buildTextField(
                          label: 'Email',
                          onChanged: (value) => email = value,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 35),
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
                        const SizedBox(height: 35),
                        // Password Field
                        _buildTextField(
                          label: 'Password',
                          obscureText: obscurePassword,
                          onChanged: (value) => password = value,
                          suffixIcon: _buildPasswordToggle(() {
                            setState(() => obscurePassword = !obscurePassword);
                          }),
                          validator: (value) => value!.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 35),
                        // Confirm Password Field
                        _buildTextField(
                          label: 'Confirm Password',
                          obscureText: obscureConfirmPassword,
                          onChanged: (value) => confirmPassword = value,
                          suffixIcon: _buildPasswordToggle(() {
                            setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                          }),
                          validator: (value) => value != password
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 35),
                        // Register Button
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: const Color(0xFF5C714C),
                            ),
                            // Function to handle form submission and patient registration
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Store the user input in the list
                                patientDetails.add(fullName);
                                patientDetails.add(email);
                                patientDetails.add(password);
                                patientDetails.add(gender);
                                patientDetails.add(age.toString());
                                patientDetails.add(contact);

                                // Print user details for debugging
                                print('Patient Details: $patientDetails');

                                // Call the API to register the patient
                                ApiClient apiClient = ApiClient();
                                var response = await apiClient.registerPatient(
                                  fullName, gender, int.parse(age), email, password, contact
                                );

                                if (response.containsKey('error')) {
                                  // Show error if registration fails
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Registration failed: ${response['error']}')),
                                  );
                                } else {
                                  // Registration success
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Registration successful!')),
                                  );
                                  // Delay navigation by 3 seconds
                                  Future.delayed(const Duration(seconds: 3), () {
                                    // Navigate to the shirt_connection.dart page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SmartShirtScreen(),
                                      ),
                                    );
                                  });
                                }
                              }
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(fontSize: 18, color: Colors.white),
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
      margin: const EdgeInsets.fromLTRB(15, 0, 0, 5), // Added margin for spacing between input boxes
      height: 48,
      width: 300, // Set width for consistency
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
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, color: Colors.black),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 4, color: Colors.black),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
      onPressed: onPressed,
    );
  }

  Widget _buildGenderDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 0, 5),
      height: 48,
      width: 300,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        hint: Text(label),
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 24,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(width: 10, color: Colors.black),
          ),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }
}





  // Build Password Toggle Button
  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.remove_red_eye),
      onPressed: onPressed,
    );
  }

