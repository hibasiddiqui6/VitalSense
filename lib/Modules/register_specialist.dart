import 'package:flutter/material.dart';
import 'dart:async'; // For delayed navigation
import 'specialist_landingPage.dart';
import 'package:vitalsense/services/api_client.dart';  // Import ApiClient for API interaction

class SpecialistRegister extends StatefulWidget {
  const SpecialistRegister({super.key});

  @override
  _SpecialistRegisterState createState() => _SpecialistRegisterState();
}

class _SpecialistRegisterState extends State<SpecialistRegister> {
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String profession = '';
  String speciality = '';

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  final GlobalKey _professionKey = GlobalKey();
  final GlobalKey _specialityKey = GlobalKey();

  // A list to store the user details
  List<String> specialistDetails= [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 412,
          height: MediaQuery.of(context).size.height - 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBF4),
            borderRadius: BorderRadius.circular(20),
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
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 75, 0, 0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
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
                      'Register as a Specialist',
                      style: TextStyle(
                        color: Color(0xFF373737),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      label: 'Full Name',
                      onChanged: (value) {
                        setState(() {
                          fullName = value;
                        });
                      },
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
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
                    _buildTextField(
                      label: 'Email',
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value!.contains('@') ? null : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Password',
                      obscureText: obscurePassword,
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      suffixIcon: _buildPasswordToggle(() {
                        setState(() => obscurePassword = !obscurePassword);
                      }),
                      validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Confirm Password',
                      obscureText: obscureConfirmPassword,
                      onChanged: (value) {
                        setState(() {
                          confirmPassword = value;
                        });
                      },
                      suffixIcon: _buildPasswordToggle(() {
                        setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                      }),
                      validator: (value) => value != password ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 35),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: const Color(0xFF5C714C),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Store the user input in the list
                            specialistDetails.add(fullName);
                            specialistDetails.add(email);
                            specialistDetails.add(password);
                            specialistDetails.add(profession);
                            specialistDetails.add(speciality);
                            
                            // Print user details for debugging
                            print('Specialist Details: $specialistDetails');

                            // Call the API to register the specialist
                            ApiClient apiClient = ApiClient();
                            var response = await apiClient.registerSpecialist(
                              fullName, email, password, profession, speciality
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
                                    builder: (context) => NoActivePatientsScreen(),
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
            return 'Please select a $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: const Icon(Icons.visibility),
      onPressed: onPressed,
    );
  }
}
