import 'package:flutter/material.dart';

class PatientRegister extends StatefulWidget {
  const PatientRegister({Key? key}) : super(key: key);
  
  get select_gender => null;
  

  @override
  _PatientRegisterState createState() => _PatientRegisterState();
}

class _PatientRegisterState extends State<PatientRegister> {
  // Define variables for each input
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String gender = '';
  String age = '';

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
 

  final _formKey = GlobalKey<FormState>(); // For form validation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
         
          
        
          child: Container(
            width: 412, // Fixed width
            height: 850, // Fixed height
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBF4), // Sky green background color for the fixed frame size
              borderRadius: BorderRadius.circular(20), // Optional: curve the corners of the container
            ),
          
        
      
        child: SingleChildScrollView(
          child: Container(
            
            padding: const EdgeInsets.fromLTRB(33, 25, 33, 65),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 206, 226, 206),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Container(
                        margin: const EdgeInsets.fromLTRB(10, 55, 0, 0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context); // Navigate back to the previous screen
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
                    'Register as a Patient',
                    style: TextStyle(
                      color: Color(0xFF373737),
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Full Name Field
                  _buildTextField(
                    label: 'Full Name',
                    onChanged: (value) => fullName = value,
                    validator: (value) => value!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  // Gender Dropdown
                  _buildDropdownField(
                    label: 'Gender',
                    items: const ['Male', 'Female'],
                    onChanged: (value) => gender = value!,
                  ),
                  const SizedBox(height: 20),
                  // Age Field
                  _buildTextField(
                    label: 'Age',
                    onChanged: (value) => age = value,
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Age is required' : null,
                  ),
                  const SizedBox(height: 20),
                  // Email Field
                  _buildTextField(
                    label: 'Email',
                    onChanged: (value) => email = value,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.contains('@')
                        ? null
                        : 'Enter a valid email address',
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
                    validator: (value) => value!.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
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
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: const Color(0xFF5C714C),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Handle registration logic here
                          print('Registration successful');
                        }
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
=======
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
    ),
      ),);
  }

  // Build Text Field
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

  // Build Dropdown Field
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items
            .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Build Password Visibility Toggle
  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
      onPressed: onPressed,
    );
  }
=======
}
