import 'dart:convert'; // For JSON encoding and decoding
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_add_patient.dart';

class SpecialistRegister extends StatefulWidget {
  const SpecialistRegister({Key? key}) : super(key: key);

  @override
  _SpecialistRegisterState createState() => _SpecialistRegisterState();
}

class _SpecialistRegisterState extends State<SpecialistRegister> {
  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String gender = '';
  String age = '';

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  final GlobalKey _genderKey = GlobalKey();

  // Define a function to store data persistently
  Future<void> _saveSpecialistDetails(Map<String, String> specialistDetails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load the existing specialists list
    List<String> specialistsList = prefs.getStringList('specialists') ?? [];

    // Convert the specialist details map to a JSON string
    String specialistJson = jsonEncode(specialistDetails);

    // Add the new specialist to the list
    specialistsList.add(specialistJson);

    // Save the updated list back to SharedPreferences
    await prefs.setStringList('specialists', specialistsList);
  }

  // Define a function to load the specialist details
  Future<List<Map<String, String>>> _loadSpecialistDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> specialistsList = prefs.getStringList('specialists') ?? [];
    List<Map<String, String>> detailsList = [];

    // Convert the JSON strings back to maps
    for (String specialistJson in specialistsList) {
      Map<String, String> specialist = Map<String, String>.from(jsonDecode(specialistJson));
      detailsList.add(specialist);
    }

    return detailsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 412,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBF4),
            borderRadius: BorderRadius.circular(20),
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
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 55, 0, 0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
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
                      'Register as a Specialist',
                      style: TextStyle(
                        color: Color(0xFF373737),
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      label: 'Full Name',
                      onChanged: (value) {
                        setState(() {
                          fullName = value;
                        });
                      },
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildGenderDropdown(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Age',
                      onChanged: (value) {
                        setState(() {
                          age = value;
                        });
                      },
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Age is required';
                        } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'Age must be a number';
                        } else if (int.tryParse(value)! >= 100) {
                          return 'Age must be less than 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Email',
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value!.contains('@') ? null : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Password',
                      obscureText: obscurePassword,
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      suffixIcon: _buildPasswordToggle(() {
                        setState(() => obscurePassword = !obscurePassword);
                      }),
                      validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Confirm Password',
                      obscureText: obscureConfirmPassword,
                      onChanged: (value) {
                        setState(() {
                          confirmPassword = value;
                        });
                      },
                      suffixIcon: _buildPasswordToggle(() {
                        setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                      }),
                      validator: (value) => value != password ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 35),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: const Color(0xFF5C714C),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            Map<String, String> specialistDetails = {
                              'Full Name': fullName,
                              'Age': age,
                              'Email': email,
                              'Password': password,
                              'Confirm Password': confirmPassword,
                              'Gender': gender,
                            };
                            await _saveSpecialistDetails(specialistDetails);
                            print('Registration successful');
                            print('Registered Details: $specialistDetails');
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NoActivePatientsScreen()),
                            );
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

  Widget _buildGenderDropdown() {
    return Container(
      key: _genderKey,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 253, 245, 1).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: () async {
          RenderBox renderBox = _genderKey.currentContext!.findRenderObject() as RenderBox;
          Offset offset = renderBox.localToGlobal(Offset.zero);

          String? selectedGender = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              offset.dx,
              offset.dy + renderBox.size.height,
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
          decoration: InputDecoration(border: InputBorder.none),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(gender.isEmpty ? 'Select Gender' : gender),
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: const Icon(Icons.arrow_drop_down),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordToggle(VoidCallback onPressed) {
    return IconButton(
      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
      onPressed: onPressed,
    );
  }
}
