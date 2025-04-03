import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/specialist_drawer.dart';

class SpecialistProfileScreen extends StatefulWidget {
  const SpecialistProfileScreen({super.key});

  @override
  _SpecialistProfileScreenState createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends State<SpecialistProfileScreen> {
  String fullName = "Loading...";
  String email = "Loading...";
  String profession = "Loading...";
  String speciality = "Loading...";
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchSpecialistProfile();
    _loadUserDetails();
  }

  /// Fetch profile
  Future<void> fetchSpecialistProfile() async {
    try {
      final data = await ApiClient().getSpecialistProfile();

      if (data.containsKey("error")) return;

      setState(() {
        fullName = data["fullname"] ?? "Unknown User";
        email = data["email"] ?? "-";
        profession = data["profession"] ?? "-";
        speciality = data["speciality"] ?? "-";
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("full_name", fullName);
      prefs.setString("email", email);
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  /// Load details for drawer
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "-";
    });
  }

  /// Edit dialog
  void _showEditDialog() {
    TextEditingController nameController =
        TextEditingController(text: fullName);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController professionController =
        TextEditingController(text: profession);
    TextEditingController specialityController =
        TextEditingController(text: speciality);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Full Name", nameController),
              _buildTextField("Email", emailController),
              _buildTextField("Profession", professionController),
              _buildTextField("Speciality", specialityController),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProfile(
                nameController.text,
                emailController.text,
                professionController.text,
                specialityController.text,
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Save profile
  Future<void> _saveProfile(
      String name, String email, String profession, String speciality) async {
    setState(() => isSaving = true);
    try {
      final response = await ApiClient().updateSpecialistProfile({
        "fullname": name,
        "email": email,
        "profession": profession,
        "speciality": speciality,
      });

      if (response.containsKey("error")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response['error']}")),
        );
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("full_name", name);
        prefs.setString("email", email);

        setState(() {
          fullName = name;
          this.email = email;
          this.profession = profession;
          this.speciality = speciality;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server unreachable. Check connection.")),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  /// Text field builder
  Widget _buildTextField(String label, TextEditingController controller) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.016),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.024)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  /// Info row builder
  Widget _buildInfoRow(String label, String value, IconData icon) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.024, horizontal: screenWidth * 0.032),
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 244, 241),
        borderRadius: BorderRadius.circular(screenWidth * 0.024),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700], size: screenWidth * 0.048),
          SizedBox(width: screenWidth * 0.024),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: screenHeight * 0.008),
                Text(value, style: TextStyle(fontSize: screenWidth * 0.032)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 175, 175, 175),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: SpecialistDrawer(fullName: fullName, email: email),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.12,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person,
                      size: screenWidth * 0.1, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.024),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fullName,
                        style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: screenWidth * 0.016),
                    GestureDetector(
                      onTap: _showEditDialog,
                      child: Icon(Icons.edit,
                          color: Colors.blueGrey, size: screenWidth * 0.04),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.04),
                _buildInfoRow('Email', email, Icons.email_outlined),
                _buildInfoRow('Profession', profession, Icons.badge_outlined),
                _buildInfoRow('Speciality', speciality, Icons.star_outline),
              ],
            ),
          ),
          if (isSaving)
            Container(
              color: Colors.black54.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: Colors.green, strokeWidth: 5)),
            ),
        ],
      ),
    );
  }
}
