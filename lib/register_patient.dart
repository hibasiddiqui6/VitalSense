import 'package:flutter/material.dart';

class PatientRegister extends StatefulWidget {
  const PatientRegister({Key? key}) : super(key: key);

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
}
