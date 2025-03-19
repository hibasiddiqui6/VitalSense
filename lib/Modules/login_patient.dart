import 'package:flutter/material.dart';
import 'register_patient.dart'; // Import the registration page
import 'patient_wifi_setup.dart'; // Import the shirt_connection.dart page
import 'patient_dashboard.dart';
import 'package:vitalsense/services/api_client.dart'; // Import the ApiClient for login functionality
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientLogin extends StatefulWidget {
  const PatientLogin({super.key});

  @override
  _PatientLoginState createState() => _PatientLoginState();
}

class _PatientLoginState extends State<PatientLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Clear the error message when user starts editing the input fields
    _emailController.addListener(() {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
    _passwordController.addListener(() {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  // Function to handle login
  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password cannot be empty.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ApiClient();
    final response = await apiClient.loginPatient(email, password);

    setState(() {
      _isLoading = false;
    });

    if (response.containsKey('error')) {
      setState(() {
        _errorMessage = response['error'];
      });
      _showPopup(context, "Login Failed", _errorMessage!);
    } else {
      _showPopup(context, "Success", "Login successful!");
      // 🔹 Fetch Patient ID
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? patientId = prefs.getString("patient_id");

      if (patientId != null) {
        print("Patient ID: $patientId. Checking for registered SmartShirt...");

        // 🔹 Check if a SmartShirt is registered for this patient
        final smartShirtResponse = await apiClient.getSmartShirts(patientId);

        SharedPreferences prefs = await SharedPreferences.getInstance();

        if (smartShirtResponse.containsKey("smartshirts") &&
            smartShirtResponse["smartshirts"].isNotEmpty) {
          print("SmartShirt found! Navigating to SensorDataScreen...");

          await prefs.setBool('smartshirt_registered', true);

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDashboard(),
              ),
            );
          });
          return;
        } else {
          print("⚠ No SmartShirt found. Proceeding to SmartShirt connection screen...");
          await prefs.setBool('smartshirt_registered', false); 

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PatientWifiSetup()),
            );
          });
        }
      } else {
        print("Patient ID not found after login.");
      }
    }
  }

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
            width: screenWidth, // Adjust width dynamically
            height: screenHeight, // Adjust height dynamically
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 206, 226, 206),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButtonWidget(),
                  SizedBox(height: screenHeight * 0.04),
                  const Center(child: TitleWidget()),
                  SizedBox(height: screenHeight * 0.07),
                  const LoginHeader(),
                  SizedBox(height: screenHeight * 0.02),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  if (_errorMessage != null) ...[
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: screenWidth * 0.035, // Responsive font size
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.04),
                  LoginButton(
                    isLoading: _isLoading,
                    onPressed: () => _login(context),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  const RegisterPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back Button Widget
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

/// Title Widget

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

/// Login Header
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
          left: screenWidth * 0.05), // Scales padding dynamically
      child: Text(
        'Login as a Patient',
        style: TextStyle(
          color: const Color(0xFF373737),
          fontSize:
              screenWidth * 0.06, // Adjust font size based on screen width
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

/// Login Form with input fields
class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Form(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Responsive padding
            child: InputField(
              controller: emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              obscureText: false,
            ),
          ),
          SizedBox(height: screenWidth * 0.04), // Responsive spacing
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: InputField(
              controller: passwordController,
              labelText: 'Password',
              keyboardType: TextInputType.text,
              obscureText: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Input Field Widget
class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final bool obscureText;

  const InputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.keyboardType,
    required this.obscureText,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // Adaptive padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        height: screenWidth * 0.14, // Responsive height
        width: screenWidth * 0.85, // Responsive width
        child: TextFormField(
          controller: widget.controller,
          style: TextStyle(
            fontSize:
                screenWidth * 0.035, // Responsive font size for input text
            color: Colors.black, // Text color
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            floatingLabelBehavior:
                FloatingLabelBehavior.auto, // Enables floating label
            labelStyle: TextStyle(
              color: const Color(0xFF3E3838),
              fontSize: screenWidth * 0.045, // Responsive font size
              fontFamily: 'Inter',
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.05, // Adjust vertical padding
              horizontal: screenWidth * 0.04, // Adjust horizontal padding
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 44, 59, 48), width: 2), // Focused border color
              borderRadius: BorderRadius.circular(15),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                  color: Colors.grey, width: 1), // Default border color
              borderRadius: BorderRadius.circular(15),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            suffixIcon: widget.labelText == 'Password'
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF3E3838),
                      size: screenWidth * 0.06,
                    ),
                    onPressed: _toggleVisibility,
                  )
                : null,
          ),
          keyboardType: widget.keyboardType,
          obscureText: widget.labelText == 'Password' ? _obscureText : false,
        ),
      ),
    );
  }
}

/// Login Button Widget
class LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      // Ensures the button is always centered
      child: Container(
        width: screenWidth * 0.65, // 65% of screen width
        height: screenWidth * 0.13, // Scales height based on width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 151, 185, 125),
              Color(0xFFFBFBF4),
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
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Color(0xFF434242),
                )
              : Text(
                  'Log in',
                  style: TextStyle(
                    color: const Color(0xFF434242),
                    fontSize:
                        screenWidth * 0.055, // Adjust font size dynamically
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
        ),
      ),
    );
  }
}

/// Register Prompt Widget
class RegisterPrompt extends StatelessWidget {
  const RegisterPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Center(
          child: FittedBox(
            child: Text(
              "Don't have an account?",
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.045, // Responsive font size
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(height: 5), // Responsive spacing
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PatientRegister()),
              );
            },
            child: FittedBox(
              child: Text(
                'Register',
                style: TextStyle(
                  color: const Color(0xFF5764A9),
                  fontSize: screenWidth * 0.045, // Responsive font size
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _showPopup(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}