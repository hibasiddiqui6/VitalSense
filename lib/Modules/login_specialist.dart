import 'package:flutter/material.dart';
import 'register_specialist.dart'; // Import the registration page
import 'specialist_landing_page.dart'; // Import the shirt_connection.dart page
import 'package:vitalsense/services/api_client.dart'; // Import the ApiClient for login functionality
import 'package:google_fonts/google_fonts.dart';

class SpecialistLogin extends StatefulWidget {
  const SpecialistLogin({super.key});

  @override
  _SpecialistLoginState createState() => _SpecialistLoginState();
}

class _SpecialistLoginState extends State<SpecialistLogin> {
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
  Future<void> _login(BuildContext contexT) async {
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

    // Call the login API
    final apiClient = ApiClient();
    final response = await apiClient.loginSpecialist(email, password);

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
      Future.delayed(const Duration(seconds: 3), () {
        // Navigate to the specialist landing page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoActivePatientsScreen(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the screen
    

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 400, // Fixed width for Google Pixel 9 frame
          height: 800, // Max height
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 206, 226, 206),
            border: Border.all(
              color: Colors.black,
              width: 5,
            ),
            borderRadius: BorderRadius.circular(45),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButtonWidget(),
                  const SizedBox(height: 36),
                  const Center(child: TitleWidget()),
                  const SizedBox(height: 65),
                  const LoginHeader(),
                  const SizedBox(height: 18),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                  ),
                  const SizedBox(height: 15),
                  if (_errorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20), // Add margin as per your need
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  const SizedBox(height: 30),
                  LoginButton(
                    isLoading: _isLoading,
                    onPressed: () => _login(context), // Pass context to _login
                  ),
                  const SizedBox(height: 30),
                  const RegisterPrompt(),
                  const SizedBox(height: 30),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 49, 0, 0),
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
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
    return  Text(
      'VitalSense',
      style: GoogleFonts.lato(
        color: Color(0xFF373737),
        fontSize: 32,
      ),
    );
  }
}

/// Login Header
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 15),
      child: Text(
        'Login as a Healthcare Specialist',
        style: TextStyle(
          color: Color(0xFF373737),
          fontSize: 22,
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
    return Form(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InputField(
              controller: emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              obscureText: false,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return Container(
      height: 55,
      width: 312,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: const TextStyle(
            color: Color(0xFF3E3838),
            fontSize: 17,
            fontFamily: 'Inter',
          ),
          border: InputBorder.none,
          suffixIcon: widget.labelText == 'Password'
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF3E3838),
                  ),
                  onPressed: _toggleVisibility,
                )
              : null,
        ),
        keyboardType: widget.keyboardType,
        obscureText: _obscureText,
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
    return Padding(
      padding: const EdgeInsets.only(left: 45),
      child: Container(
        width: 250,
        height: 50,
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
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Color(0xFF434242),
                )
              : const Text(
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
    );
  }
}

/// Register Prompt Widget
class RegisterPrompt extends StatelessWidget {
  const RegisterPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
          child: Text(
            "Don't have an account?",
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpecialistRegister()),
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
