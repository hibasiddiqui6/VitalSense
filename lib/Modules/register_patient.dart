import 'package:flutter/material.dart';
import 'dart:async'; // For delayed navigation
import 'patient_landingPage.dart'; // Import the page where you want to navigate after registration
import 'package:vitalsense/services/api_client.dart';  // Import ApiClient for API interaction

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
  final GlobalKey _genderKey = GlobalKey(); // Key for the gender field to get its position

  // A list to store the user details
  List<String> patientDetails = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 412, // Fixed width
          height: MediaQuery.of(context).size.height - 60, // Full screen height
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBF4), // Sky green background color for the fixed frame size
            borderRadius: BorderRadius.circular(20), // Optional: curve the corners of the container
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(33, 0, 33, 20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 206, 226, 206),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 75, 0, 0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to the previous screen
                        },
                      ),
                    ),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Register as a Patient', // Changed to "Patient"
                      style: TextStyle(
                        color: Color(0xFF373737),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 25),
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
                    const SizedBox(height: 20),
                    // Gender Dropdown 
                    _buildGenderDropdown(
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
                    SizedBox(height: 25), 
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

                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                    // Contact Field (New)
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 25),
                    // Register Button
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
            ),
          ),
        ),
      ),
    );
  }

  // Build Text Field
  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

Widget _buildGenderDropdown({
    required GlobalKey key,
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    bool enabled = true,
  }) {
    return Container
        (
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(enabled ? 0.6 : 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        items: options
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: enabled
            ? (value) {
                onChanged(value!);
              }
            : null,
        validator: (value) {
          if (enabled && (value == null || value.isEmpty)) {
            return 'Select a $label';
          }
          return null;
        },
      ),
    );
  }

  // Build Password Toggle Button
  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.remove_red_eye),
      onPressed: onPressed,
    );
  }
}
