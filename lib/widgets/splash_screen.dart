import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vitalsense/Modules/welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showButton = false; // Controls button visibility
  late AnimationController _controller; // Lottie animation controller

  @override
  void initState() {
    super.initState();
    // Initialize Lottie animation controller
    _controller = AnimationController(vsync: this);
    // Listen for animation completion
    _controller.addListener(() {
      if (_controller.isCompleted) {
        setState(() {
          _showButton = true; // Show button after animation finishes
        });
      }
    });
    // Show the "Continue" button after animation duration (4 sec)
    Future.delayed(Duration(seconds: 6), () {
      setState(() {
        _showButton = true;
      });
    });

    // Auto navigate after 20 seconds
    // Timer(Duration(seconds: 20), () {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => WelcomePage()),
    //   );
    // });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    //final screenHeight = MediaQuery.of(context).size.height;
    // TODO: implement build
    return Scaffold(
      backgroundColor: Color.fromRGBO(187, 201, 186, 1),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              width: 700, // Fixed container width
              height: 700, // Fixed container height
              child: Lottie.asset(
                'assets/animation/Flow1.json',
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration =
                      composition.duration; // Set animation duration
                  _controller.forward(); // Start animation
                },
                fit: BoxFit.contain, // Ensures animation scales inside the box
                repeat: false, // Play animation only once
              ),
            ),
          ),
          SizedBox(height: 0),
          AnimatedOpacity(
            duration: Duration(seconds: 1), // Fade-in duration
            opacity: _showButton ? 1.0 : 0.0,
            child: Center(
              child: Container(
                margin: EdgeInsets.only(
                    bottom: screenWidth * 0.12), // Adjust margin as needed
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(
                            milliseconds:
                                600), // Slower animation (default is ~300ms)
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            WelcomePage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0); // Start from right
                          const end = Offset(0.0, 0.0); // Move to left
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 131, 91),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}