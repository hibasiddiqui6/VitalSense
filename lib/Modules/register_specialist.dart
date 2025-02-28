
import 'package:flutter/material.dart';
import 'dart:async'; // For delayed navigation
import 'specialist_landing_page.dart'; // Import the page where you want to navigate after registration
import 'package:vitalsense/services/api_client.dart';  // Import ApiClient for API interaction
import 'package:google_fonts/google_fonts.dart';

class SpecialistRegister extends StatefulWidget {
  const SpecialistRegister({super.key});

  @override
  _SpecialistRegisterState createState() => _SpecialistRegisterState();
}

class _SpecialistRegisterState extends State<SpecialistRegister> {
  // Define variables for each input
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String profession = '';
  String speciality = '';
  
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>(); // For form validation
  final GlobalKey _professionKey = GlobalKey();
  final GlobalKey _specialityKey = GlobalKey();

  bool _isLoading = false;

  // A list to store the user details
  List<String> specialistDetails = [];

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
                      'Register as a Healthcare Specialist', // Changed to "Specialist"
                      style: TextStyle(
                        color: Color(0xFF373737),
                        fontSize: 19,
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
                        const SizedBox(height: 20),
                        // Profession Dropdown
                        _buildDropdownField(
                      key: _professionKey,
                      label: 'Profession',
                      value: profession,
                      options: ['Doctor', 'Nurse', 'Other'],
                      onChanged: (value) {
                        setState(() {
                          profession = value;
                          speciality = ''; // Reset speciality when profession changes
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                        // Speciality Field
                        _buildDropdownField(
                      key: _specialityKey,
                      label: 'Speciality',
                      value: speciality,
                      options: profession == 'Doctor'
                          ? ['Cardiology', 'Neurology', 'Pediatrics', 'General Physician', 'Other']
                          : profession == 'Nurse'
                              ? ['General Care', 'Surgical Assistance', 'Pediatrics', 'Other']
                              : ['Other'],
                      onChanged: (value) {
                        setState(() {
                          speciality = value;
                        });
                      },
                      enabled: profession == 'Doctor' || profession == 'Nurse',
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

                                  // Collect user details
                                specialistDetails = [
                                    fullName,
                                    email,
                                    password,
                                    profession,
                                    speciality,
                                  ];

                                  try {
                                    // Make API call
                                    ApiClient apiClient = ApiClient();
                                    var response = await apiClient.registerSpecialist(
                                      fullName, email, password, profession, speciality, 
                                    );

                                    // Handle response
                                    if (response.containsKey('error')) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Registration Failed'),
                                            content: Text('Error: ${response['error']}'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
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
                                            title: const Text('Registration Successful'),
                                            content: const Text('The specialist has been registered successfully!'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      // Navigate after success
                                      Future.delayed(const Duration(seconds: 3), () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => NoActivePatientsScreen()),
                                        );
                                      });
                                    }
                                  } catch (e) {
                                    // Handle exceptions
                                    setState(() {
                                      _isLoading = false;
                                    });
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
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextFormField(
          obscureText: obscureText,
          onChanged: onChanged, // Only update state, no validation
          keyboardType: keyboardType,
          validator: validator, // Validation will occur on form submission
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(15, 10, 0, 0),
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
          contentPadding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          
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
