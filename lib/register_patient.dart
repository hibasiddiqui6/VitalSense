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

  final GlobalKey _genderKey = GlobalKey(); // Key for the gender field to get its position

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 412, // Fixed width
          height: MediaQuery.of(context).size.height, // Full screen height
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
                      'Register as a Patient', // Changed to "Patient"
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
                    // Gender Dropdown - Custom
                    _buildGenderDropdown(),
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
    );
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

  // Build Gender Dropdown - Custom
  Widget _buildGenderDropdown() {
    return Container(
      key: _genderKey, // Attach the key to the gender field
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: () async {
          // Get the position of the gender input field
          RenderBox renderBox = _genderKey.currentContext!.findRenderObject() as RenderBox;
          Offset offset = renderBox.localToGlobal(Offset.zero); // Position of the field

          // Show custom dropdown menu positioned just below the gender field
          String? selectedGender = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              offset.dx,
              offset.dy + renderBox.size.height, // Position it right below the input field
              offset.dx + renderBox.size.width,
              offset.dy,
            ),
            items: [
              PopupMenuItem<String>(value: 'Male', child: Text('Male')),
              PopupMenuItem<String>(value: 'Female', child: Text('Female')),
            ],
          );
          if (selectedGender != null) {
            setState(() {
              gender = selectedGender;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            // Removed labelText here
            border: InputBorder.none,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(gender.isEmpty ? 'Select Gender' : gender),
              Padding(
                padding: const EdgeInsets.only(right: 6.0), // Adjust the margin here
                child: const Icon(Icons.arrow_drop_down),
              ),
            ],
          ),
        ),
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
