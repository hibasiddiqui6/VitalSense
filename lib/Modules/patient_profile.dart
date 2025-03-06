import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'settings.dart';
import 'all_vitals.dart'; // Import Dashboard for Drawer
import 'trusted_contacts.dart';
import 'welcome_page.dart';
import 'about_us.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PatientProfileScreen(),
    );
  }
}

class PatientProfileScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _loadUserDetails();
  }

  /// **Fetch user profile data**
  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getPatientProfile();

      if (data.containsKey("error")) {
        print("⚠ Error fetching user profile: ${data['error']}");
        return;
      }

      if (mounted) {
        setState(() {
          fullName = data["FullName"] ?? "Unknown User";
          patientId = data["PatientID"]?.toString() ?? "N/A";
          gender = data["Gender"] ?? "N/A";
          age = data["Age"]?.toString() ?? "N/A";
          email = data["Email"] ?? "N/A";
          contact = data["Contact"] ?? "N/A";
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("full_name", fullName);
        await prefs.setString("gender", gender);
        await prefs.setString("age", age);
        await prefs.setString("patient_id", patientId);
        await prefs.setString("email", email);
        await prefs.setString("contact", contact);
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  /// **Load Full Name from SharedPreferences**
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
    });
    setState(() {
      gender = prefs.getString("gender") ?? "N/A";
    });
    setState(() {
      age = prefs.getString("age") ?? "N/A";
    });
    setState(() {
      patientId = prefs.getString("patient_id") ?? "N/A";
    });
    setState(() {
      contact = prefs.getString("contact") ?? "N/A";
    });
    setState(() {
      email = prefs.getString("email") ?? "N/A";
    });
  }


  /// **Show Edit Dialog**
  void _showEditDialog() {
    TextEditingController nameController = TextEditingController(text: fullName);
    TextEditingController genderController = TextEditingController(text: gender);
    TextEditingController ageController = TextEditingController(text: age);
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController contactController = TextEditingController(text: contact);

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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _saveProfile(
                  nameController.text,
                  genderController.text,
                  ageController.text,
                  emailController.text,
                  contactController.text,
                );
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// **Build Text Field for Editing**
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

  /// **Save Updated Profile**
  Future<void> _saveProfile(String name, String gender, String age, String email, String contact) async {
    try {
      // Send data to API
      final response = await ApiClient().updatePatientProfile({
        "FullName": name,
        "Gender": gender,
        "Age": age,
        "Email": email,
        "Contact": contact,
      });

      if (response.containsKey("error")) {
        print("⚠ Error updating profile: ${response['error']}");
        return;
      }

      // Update local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("full_name", name);
      prefs.setString("gender", gender);
      prefs.setString("age", age);
      prefs.setString("email", email);
      prefs.setString("contact", contact);

      // Update UI
      setState(() {
        fullName = name;
        this.gender = gender;
        this.age = age;
        this.email = email;
        this.contact = contact;
      });

      print("✅ Profile updated successfully!");
    } catch (e) {
      print("❌ Error updating profile: $e");
    }
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
      drawer: AppDrawer(), 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 10),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showEditDialog,
                      child: Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                    ),
                  ],
                ),
              Text(
                'ID: ${patientId.split('-').take(2).join('-')}', 
                style: TextStyle(color: Colors.grey)
                ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFE0B2), // Light Orange
                      Color(0xFFC8E6C9), // Light Green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
          Divider(color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class AppDrawer extends StatefulWidget {
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 193, 219, 188),
            ),
            child: Text(
              'VitalSense', 
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _buildDrawerItem(Icons.person, 'Dashboard', context,),
          _buildDrawerItem(Icons.person, 'My Profile', context,),
          _buildDrawerItem(Icons.contacts, 'Trusted Contacts', context),
          _buildDrawerItem(Icons.trending_up, 'Trends and History', context),
          _buildDrawerItem(Icons.file_present, 'Reports', context),
          _buildDrawerItem(Icons.settings, 'Settings', context),
          _buildDrawerItem(Icons.info, 'About', context),

          const Divider(), // Adds a separator

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              _handleLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () {
      Navigator.pop(context); // Close the drawer

      // Navigate
      if (title == 'Dashboard') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      }
      if (title == 'My Profile') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PatientProfileScreen()),
        );
      }
      if (title == 'Settings') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen()),
        );
      }
      if (title == 'Trusted Contacts') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TrustedContactsScreen()),
        );
      }
      if (title == 'About') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AboutUsPage()),
        );
      }
    },
  );
}

  /// **Handle Logout Function**
  void _handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }
}