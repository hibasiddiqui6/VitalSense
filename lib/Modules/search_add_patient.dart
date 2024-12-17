import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const NoActivePatientsScreen(),
    );
  }
}

class NoActivePatientsScreen extends StatefulWidget {
  const NoActivePatientsScreen({super.key});

  @override
  _NoActivePatientsScreenState createState() =>
      _NoActivePatientsScreenState();
}

class _NoActivePatientsScreenState extends State<NoActivePatientsScreen> {
  final FocusNode _focusNode = FocusNode();  // Create a FocusNode for the TextField
  bool _isFocused = false; // Track whether the TextField is focused

  @override
  void initState() {
    super.initState();
    // Add a listener to track the focus state of the TextField
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose the FocusNode when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the screen
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F3), // Light background color
      body: Center(
        child: Container(
          width: 412, // Fixed width for the center frame
          height: screenHeight - 60, // Adjust height to screen size (subtract appbar height)
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Padding inside the frame
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the frame
            borderRadius: BorderRadius.circular(15), // Rounded corners for the frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
              // Custom AppBar inside the frame
              Container(
                padding: const EdgeInsets.fromLTRB(0,20.0,15,0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black54),
                      onPressed: () {
                        // Add functionality for side menu
                      },
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
                       
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFDCC3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(20, 1, 50, 12),
                                child: TextField(
                                  focusNode: _focusNode, // Attach the FocusNode
                                  decoration: const InputDecoration(
                                    hintText: 'Search patient',
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            // Show the search icon only when the TextField is focused
                            if (_isFocused)
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.black54),
                                onPressed: () {
                                  // Add search functionality
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Main content below the AppBar, centered inside the frame
              Container(
                margin: const EdgeInsets.fromLTRB(0, 170, 0, 0), // Add margin to the text
                child: const Text(
                  'No Active Patients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 0), // Add margin to the text
                child: const Text(
                  'No readings to Display!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20), // Add margin to the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFDCC3),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    // Add patient button action here
                  },
                  child: const Text(
                    'Add patient',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
