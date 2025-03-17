import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/patient_drawer.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  _PatientProfileScreenState createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  String fullName = "Loading...";
  String patientId = "Loading...";
  String gender = "Loading...";
  String age = "Loading...";
  String email = "Loading...";
  String contact = "Loading...";
  String weight = "Loading...";
  bool isSaving = false; // 👈 Add loading state

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _loadUserDetails();
  }

  /// Fetch user profile data
  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getPatientProfile();

      if (data.containsKey("error")) {
        print("⚠ Error fetching user profile: ${data['error']}");
        return;
      }

      if (mounted) {
        setState(() {
          fullName = data["fullname"] ?? "Unknown User";
          patientId = data["patientid"]?.toString() ?? "-";
          gender = data["gender"] ?? "-";
          age = data["age"]?.toString() ?? "-";
          email = data["email"] ?? "-";
          contact = data["contact"] ?? "-";
          weight = data["weight"] ?? "-";
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("full_name", fullName);
        await prefs.setString("gender", gender);
        await prefs.setString("age", age);
        await prefs.setString("patient_id", patientId);
        await prefs.setString("email", email);
        await prefs.setString("contact", contact);
        await prefs.setString("weight", weight);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// Load user details
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      gender = prefs.getString("gender") ?? "-";
      age = prefs.getString("age") ?? "-";
      patientId = prefs.getString("patient_id") ?? "-";
      contact = prefs.getString("contact") ?? "-";
      email = prefs.getString("email") ?? "-";
      weight = prefs.getString("weight") ?? "-";
    });
  }

  /// Show Edit Dialog
  void _showEditDialog() {
    TextEditingController nameController = TextEditingController(text: fullName);
    TextEditingController genderController = TextEditingController(text: gender);
    TextEditingController ageController = TextEditingController(text: age);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController contactController = TextEditingController(text: contact);
    TextEditingController weightController = TextEditingController(text: weight);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("Full Name", nameController),
                _buildTextField("Gender", genderController),
                _buildTextField("Age", ageController),
                _buildTextField("Email", emailController),
                _buildTextField("Contact", contactController),
                _buildTextField("Weight", weightController),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _saveProfile(
                  nameController.text,
                  genderController.text,
                  ageController.text,
                  emailController.text,
                  contactController.text,
                  double.parse(weightController.text)
                );
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// Save Updated Profile with loading indicator
  Future<void> _saveProfile(String name, String gender, String age, String email, String contact, double weight) async {
    setState(() => isSaving = true); // Show loading
    try {
      final response = await ApiClient().updatePatientProfile({
        "full_name": name,   
        "gender": gender,    
        "age": age,          
        "email": email,      
        "contact": contact,  
        "weight": weight.toString(), 
      });

      if (response.containsKey("error")) {
        print("⚠ Error updating profile: ${response['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response['error']}")),
        );
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("full_name", name);
        prefs.setString("gender", gender);
        prefs.setString("age", age);
        prefs.setString("email", email);
        prefs.setString("contact", contact);
        prefs.setString("weight", weight.toString());

        setState(() {
          fullName = name;
          this.gender = gender;
          this.age = age;
          this.email = email;
          this.contact = contact;
          this.weight = weight.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully!")),
        );
      }
    } catch (e) {
      print("❌ Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server unreachable. Check your connection.")),
      );
    } finally {
      setState(() => isSaving = false); // Hide loading
    }
  }

  /// Build Text Field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: PatientDrawer(fullName: fullName, email: email),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _getAvatarImage(gender), // Set custom image
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(fullName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showEditDialog,
                        child: Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  Text('ID: ${patientId.split('-').take(2).join('-')}', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFE0B2), Color(0xFFC8E6C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 2, blurRadius: 5, offset: Offset(0, 3)),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Gender', gender),
                        _buildInfoRow('Age', age),
                        _buildInfoRow('Email', email),
                        _buildInfoRow('Contact', contact),
                        _buildInfoRow('Weight', weight),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSaving) // Loading indicator overlay
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green, strokeWidth: 5),
              ),
            ),
        ],
      ),
    );
  }

 ImageProvider _getAvatarImage(String gender) {
  gender = gender.toLowerCase().trim(); // Normalize input

  if (gender == "male") {
    return AssetImage("assets/male_avatar.png"); // Male Avatar
  } else if (gender == "female") {
    return AssetImage("assets/female_avatar.png"); // Female Avatar
  } else {
    return AssetImage("assets/default_avatar.png"); // Default Avatar
  }
}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
