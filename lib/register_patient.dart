import 'package:flutter/material.dart';
import 'login_patient.dart';

class PatientRegister extends StatelessWidget {
  const PatientRegister({Key? key}) : super(key: key);
  
  get select_gender => null;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF4), // Set background color
      body: Center(
        child: Container(
          width: 412,
          height: 850,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 206, 226, 206), // Sky green background color for the fixed frame size
            borderRadius: BorderRadius.circular(20), // Optional: curve the corners of the container
          ),
          child: SingleChildScrollView(
            
            child: Padding(
              padding: const EdgeInsets.fromLTRB(33, 0, 33, 50),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Container(
                      margin: const EdgeInsets.fromLTRB(4, 85, 0, 0),
                      child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to the previous screen
                      },
                    ),
                    ),
                    
                    const SizedBox(),
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
                    const SizedBox(),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 20, 0, 0),
                      child: Text(
                        'Register as a Patient',
                        style: TextStyle(
                          color: Color(0xFF373737),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Form(
                      child: Column(
                        children: [
                          // Name Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          
                          // Gender Dropdown Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: DropdownButtonFormField<String>(
                              
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              items: ['Male', 'Female']
                                  
                                  .map((gender) => DropdownMenuItem<String>(
                                        value: gender,
                                        child: Text(gender),
                                      
                                      ))
                                  .toList(),
                              onChanged: (value) {},
                              
                                
                               // Adjust icon size as needed
                
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Age Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  color: Color(0xFF3E3838),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 25),
                          // Email Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
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
                          const SizedBox(height: 25),
                          // Password Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
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
                          const SizedBox(height: 25),
                          // Confirm Password Field
                          Container(
                            width: 312,
                            height: 45,
                            padding: const EdgeInsets.fromLTRB(24, 0, 34, 0),
                            color: Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
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
                          // Register Button
                          Padding(
                            padding: const EdgeInsets.only(left: 11),
                            child: Container(
                              width: 250,
                              height: 40, // Adjust height as needed
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFBFBF4), // Gradient start color
                                    Color(0xFF5C714C), // Gradient end color
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
                                  'Register',
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
