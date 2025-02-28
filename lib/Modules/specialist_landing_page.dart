import 'package:flutter/material.dart';
import 'welcome_page.dart';

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
  final FocusNode _focusNode = FocusNode(); // Create a FocusNode for the TextField
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
    return Scaffold(
      backgroundColor: Colors.transparent, // Make the background transparent to allow mobile frame to show
      body: Center(
        child: Container(
          width: 400, // Width of the mobile frame (adjust for Google Pixel 9 size)
          height: 800, // Adjust height to screen size (subtract appbar height)
          decoration: BoxDecoration(
            color: Colors.transparent, // Transparent background for the frame
            borderRadius: BorderRadius.circular(45), // Round corners for the mobile frame
            border: Border.all(
              color: Colors.black, // Border color to simulate the mobile frame
              width: 5, // Border width
            ),
          ),
          child: Builder(
            builder: (context) {
              return Scaffold(
                drawer: ClipRRect(
                borderRadius: BorderRadius.circular(45), // Set the desired border radius
                child: Drawer( // Add side menu (drawer)
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      const DrawerHeader(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 206, 226, 206),
                        ),
                        child: Text('Vital Sense'),
                      ),
                      // Add other menu items here if needed
                      ListTile(
                        title: const Text('Logout'),
                        onTap: () {
                          // Use Builder to ensure that the context is under a Scaffold
                          Navigator.pop(context); // Close the drawer
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const WelcomePage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
                backgroundColor: Colors.transparent,
                body: Container(
                  width: 400, // Width for the content container inside the frame
                  height: 800, // Same height as the frame
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Padding inside the frame
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 206, 226, 206), // Background color of the frame content
                    borderRadius: BorderRadius.circular(45), // Rounded corners for the content
                    boxShadow: [
                      BoxShadow(
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
                        padding: const EdgeInsets.fromLTRB(0, 20.0, 15, 0),
                        child: Row(
                          children: [
                            Builder(
                              builder: (BuildContext context) {
                                return IconButton(
                                  icon: const Icon(Icons.menu, color: Colors.black54),
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer(); // Open the side menu (drawer)
                                  },
                                );
                              },
                            ),
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 241, 247, 242),
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
                            backgroundColor: const Color.fromARGB(255, 241, 247, 242),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
