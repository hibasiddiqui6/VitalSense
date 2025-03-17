import 'package:flutter/material.dart';
import 'dart:async'; // For delayed navigation
import 'specialist_dashboard.dart'; // Import the page where you want to navigate after registration
import 'package:vitalsense/services/api_client.dart'; // Import ApiClient for API interaction
import 'package:google_fonts/google_fonts.dart';

class SpecialistRegister extends StatefulWidget {
  const SpecialistRegister({super.key});

  @override
  _SpecialistRegisterState createState() => _SpecialistRegisterState();
}

class _SpecialistRegisterState extends State<SpecialistRegister> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(seconds: 1),
          child: Container(
            width: screenWidth, // 90% of screen width
            height: screenHeight, // 90% of screen height
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 206, 226, 206),
            ),

            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centers vertically
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ensures the form stays centered
                  const BackButtonWidget(),
                  SizedBox(height: screenHeight * 0.01),
                  // Spacing below back button
                  // Title
                  const Center(child: TitleWidget()),
                  SizedBox(height: screenHeight * 0.02),

                  // Registration Title
                  const Center(child: RegisterSpecialistTitle()),
                  SizedBox(height: screenHeight * 0.02),

                  // Form inside a Centered Column
                  Center(child: RegistrationForm()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TitleWidget extends StatelessWidget {
  const TitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Text(
      'VitalSense',
      style: GoogleFonts.lato(
        color: const Color(0xFF373737),
        fontSize: screenWidth * 0.08, // Adjust font size based on screen width
        fontWeight: FontWeight.bold, // Added bold for better visibility
      ),
      textAlign: TextAlign.center, // Center align for better UI
    );
  }
}

class RegisterSpecialistTitle extends StatelessWidget {
  const RegisterSpecialistTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // Adjustable margin
      child: Text(
        'Register as a Specialist',
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

class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  // Define variables for each input
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String profession = '';
  String speciality = '';

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isLoading = false;
  // A list to store the user details
  List<String> specialistDetails = [];

  final _formKey = GlobalKey<FormState>(); // For form validation
  final GlobalKey _professionKey = GlobalKey();
  final GlobalKey _specialityKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTextField(
            label: 'Full Name',
            onChanged: (value) => fullName = value,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Name is required';
              if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value))
                return 'Name must contain only letters and spaces';
              return null;
            },
          ),
          SizedBox(height: screenHeight * 0.03),
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
          SizedBox(height: screenHeight * 0.03),
          _buildDropdownField(
            key: _specialityKey,
            label: 'Speciality',
            value: speciality,
            options: profession == 'Doctor'
                ? [
                    'Cardiology',
                    'Neurology',
                    'Pediatrics',
                    'General Physician',
                    'Other'
                  ]
                : profession == 'Nurse'
                    ? [
                        'General Care',
                        'Surgical Assistance',
                        'Pediatrics',
                        'Other'
                      ]
                    : ['Other'],
            onChanged: (value) {
              setState(() {
                speciality = value;
              });
            },
            enabled: profession == 'Doctor' || profession == 'Nurse',
          ),
          SizedBox(height: screenHeight * 0.03),
          _buildTextField(
            label: 'Email',
            onChanged: (value) => email = value,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value))
                return 'Enter a valid email address';
              return null;
            },
          ),
          SizedBox(height: screenHeight * 0.03),
          _buildTextField(
            label: 'Password',
            obscureText: obscurePassword,
            onChanged: (value) => password = value,
            suffixIcon: _buildPasswordToggle(obscurePassword, () {
              setState(() => obscurePassword = !obscurePassword);
            }),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 8) return 'Password must be at least 8 characters long';
              if (!RegExp(r'[A-Z]').hasMatch(value))
                return 'Password must contain at least one uppercase letter';
              if (!RegExp(r'[0-9]').hasMatch(value))
                return 'Password must contain at least one number';
              return null;
            },
          ),

          SizedBox(height: screenHeight * 0.03),
          _buildTextField(
            label: 'Confirm Password',
            obscureText: obscureConfirmPassword,
            onChanged: (value) => confirmPassword = value,
            suffixIcon: _buildPasswordToggle(obscureConfirmPassword, () {
              setState(() => obscureConfirmPassword = !obscureConfirmPassword);
            }),
            validator: (value) =>
                value != password ? 'Passwords do not match' : null,
          ),
          SizedBox(height: screenHeight * 0.03),
          // Register Button
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 151, 185, 125),
                    Color(0xFFFBFBF4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20), // Match button shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 4), // Shadow position
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.2,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Colors.transparent, // Transparent to show gradient
                  shadowColor: Colors.transparent, // Optional: remove button shadow
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
                            fullName,
                            email,
                            password,
                            profession,
                            speciality,
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
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
                                  content: const Text(
                                      'The specialist has been registered successfully!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SpecialistDashboard()),
                              );
                            });
                          }
                        } catch (e) {
                          print('Error: $e');
                          setState(() {
                              _isLoading = false; // Ensure loading stops on error
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
                        style: TextStyle(
                          fontSize: 20,
                          color: const Color(0xFF434242), // Adjusted for contrast with light gradient
                        ),
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Generic Text Field Builder
  Widget _buildTextField({
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
    Widget? suffixIcon,
    required FormFieldValidator<String> validator,
  }) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.12, // Responsive height
      width: MediaQuery.of(context).size.width *
          0.85, // Takes full width of the parent container
      padding: EdgeInsets.symmetric(horizontal: 0), // Adds padding
      decoration: BoxDecoration(
        color: Colors.white, // White background color
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black12, // Light shadow
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey, width: 1), // Default border color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: const Color.fromARGB(255, 44, 59, 48), width: 2), // Active/focused border color
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Dropdown Field Builder
  Widget _buildDropdownField({
    required GlobalKey key,
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.12, // Responsive height
      width: MediaQuery.of(context).size.width *
          0.85, // Takes full width of the parent container// Ensures full responsiveness
      padding: EdgeInsets.symmetric(horizontal: 0), // Adds spacing
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(15), // Rounded corners
        // Outline border
        boxShadow: [
          BoxShadow(
            color: Colors.black12, // Light shadow for depth
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value.isNotEmpty ? value : null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey, width: 1), // Default border color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: const Color.fromARGB(255, 44, 59, 48), width: 2), // Active/focused border color
          ),
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

  // Password Visibility Toggle
  Widget _buildPasswordToggle(bool isObscured, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
      onPressed: onPressed,
    );
  }
}