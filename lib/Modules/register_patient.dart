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
  final GlobalKey _genderKey = GlobalKey();

  bool _isLoading = false;

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
            color: Color.fromARGB(255, 206, 226, 206),
            borderRadius: BorderRadius.circular(45), // Rounded corners for the frame
            border: Border.all(
              width: 5, // 5px border width
              color: Colors.black, // Black border for Pixel 9 frame look
            ),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(40, 0, 20, 30),
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
                  const SizedBox(height: 35),
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
                        const SizedBox(height: 35),
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
                        const SizedBox(height: 35),
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
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: const Color(0xFF5C714C),
                            ),
                            // Function to handle form submission and patient registration
                            onPressed: _isLoading 
                                ? null
                                :() async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });

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
                                  setState(() {
                                  _isLoading = false; // Re-enable button after failed response
                                });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Registration Failed'),
                                        content: Text('Error: ${response['error']}'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  // Show success message in a dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Registration Successful'),
                                        content: Text('The patient has been registered successfully!'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  // Delay navigation by 3 seconds
                                  Future.delayed(const Duration(seconds: 3), () {
                                    // Navigate to the shirt_connection.dart page
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SmartShirtScreen(),
                                      ),
                                    );
                                  });
                                }
                              }
                            },
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                  color: Color(0xFF434242),
                                )
                                : const Text(
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
     height: 55,
      width: 312,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextFormField(
        obscureText: obscureText,
        onChanged: (value) {
          onChanged(value);
          // Trigger form validation to hide the error when typing starts
          _formKey.currentState?.validate();
        },
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, color: Colors.black),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 0, 5),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          
          border: InputBorder.none,
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
    return Container
        (
      key: key,
      height: 55,
      width: 312,
      padding: const EdgeInsets.symmetric(horizontal: 20),
    
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(enabled ? 0.6 : 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, color: Colors.black),
          contentPadding: const EdgeInsets.fromLTRB(15, 5, 0, 5),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
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
            return 'Please select a $label';
          }
          return null;
        },
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