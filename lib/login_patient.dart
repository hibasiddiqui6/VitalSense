import 'package:flutter/material.dart';
import 'register_patient.dart'; // Import the registration page

class PatientLogin extends StatelessWidget {
  const PatientLogin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FixedContainer(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(33, 10, 33, 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButtonWidget(),
                  const SizedBox(height: 36),
                  const Center(child: TitleWidget()),
                  const SizedBox(height: 65),
                  const LoginHeader(),
                  const SizedBox(height: 18),
                  const LoginForm(),
                  const SizedBox(height: 57),
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

/// FixedContainer for the background and layout constraints
class FixedContainer extends StatelessWidget {
  final Widget child;
  const FixedContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 412,
      height: 850,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 206, 226, 206),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Back Button Widget
class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 69, 0, 0),
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
  const TitleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'VitalSense',
      style: TextStyle(
        color: Color(0xFF373737),
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
    );
  }
}

/// Login Header
class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 19),
      child: Text(
        'Login as a Patient',
        style: TextStyle(
          color: Color(0xFF373737),
          fontSize: 24,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

/// Login Form with input fields and login button
class LoginForm extends StatelessWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          const InputField(
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            obscureText: false,
          ),
          const SizedBox(height: 18),
          const InputField(
            labelText: 'Password',
            keyboardType: TextInputType.text,
            obscureText: true,
          ),
          const SizedBox(height: 35),
          const LoginButton(),
        ],
      ),
    );
  }
}

/// Input Field Widget
class InputField extends StatelessWidget {
  final String labelText;
  final TextInputType keyboardType;
  final bool obscureText;

  const InputField({
    Key? key,
    required this.labelText,
    required this.keyboardType,
    required this.obscureText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: 312,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: const TextStyle(
            color: Color(0xFF3E3838),
            fontSize: 17,
            fontFamily: 'Inter',
          ),
          border: InputBorder.none,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
      ),
    );
  }
}

/// Login Button Widget
class LoginButton extends StatelessWidget {
  const LoginButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Container(
        width: 312,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5C714C),
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
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: const Text(
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
  const RegisterPrompt({Key? key}) : super(key: key);

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
                MaterialPageRoute(builder: (context) => const PatientRegister()),
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
=======
       // Sky green background color
      body: Center(
        child: Container(
          
          
          width: 412, // Fixed width
          height: 850, // Fixed height
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 206, 226, 206), // Sky green background color for the fixed frame size
            borderRadius: BorderRadius.circular(20), // Optional: curve the corners of the container
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(33, 10, 33, 150),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 69, 0, 0),
                      child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to the previous screen
                      },
                    ),
                    ),
                    const SizedBox(height: 36),
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
                    const SizedBox(height: 65),
                    const Padding(
                      padding: EdgeInsets.only(left: 19),
                      child: Text(
                        'Login as a Patient',
                        style: TextStyle(
                          color: Color(0xFF373737),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Form(
                      child: Column(
                        children: [
                          Container(
                            height:55,
                            width: 312,
                            padding: const EdgeInsets.fromLTRB(34, 14, 34, 25),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15), // Curved borders
                            ),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            height: 55,
                            width: 312,
                            padding: const EdgeInsets.fromLTRB(34, 14, 34, 26),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15), // Curved borders
                            ),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              obscureText: true,
                            ),
                          ),
                          const SizedBox(height: 35),
                          Padding(
                            padding: const EdgeInsets.only(left: 11),
                            child: Container(
                              width: 312,
                              height: 50, // Adjust height as needed
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5C714C), // Gradient start color
                                    Color(0xFFFBFBF4), // Gradient end color
                                     
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
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent, // Make button transparent
                                  elevation: 0, // Remove default elevation
                                  shadowColor: Colors.transparent, // Remove default shadow
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: const Text(
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 57),
                    const Center(
                      child: Text(
                        'Don\'t have an account?',
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
                          // Navigate to the PatientRegister page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientRegister()),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
