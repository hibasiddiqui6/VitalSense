import 'package:flutter/material.dart';
import 'specialist_dashboard.dart';
import 'specialist_profile.dart';
import 'specialist_patients.dart';
import 'specialist_patient_trends.dart';
import 'specialist_settings.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 118, 150, 108),
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const PatientReportsScreen(),
    );
  }
}

class PatientReportsScreen extends StatelessWidget {
  const PatientReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer width: 80% of the screen
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: const SideMenuDrawer(),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 118, 150, 108),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 0.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 1.0,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 242, 244, 241),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search patient...",
                      hintStyle: TextStyle(color: Color.fromARGB(179, 103, 103, 103)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.search, color: Color.fromARGB(179, 103, 103, 103)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Curved header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 118, 150, 108),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
              ],
            ),
            child: const Text(
              "Patient Reports",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          // List of Reports
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(15),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        tileColor: Colors.white,
                        leading: const Icon(Icons.insert_drive_file, color: Colors.black54),
                        title: Text(
                          "#PID-${index + 1} (Patient Name) Report",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
                        onTap: () {
                          // Add your onTap logic here
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Side Menu Drawer Widget with Navigation
class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 134, 170, 122),
                  const Color.fromARGB(255, 134, 170, 122)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.black54),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Dr. John Doe",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "john.doe@example.com",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard, "Dashboard", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpecialistDashboard()),
                  );
                }),
                _divider(),
                // "My Profile" navigates to SpecialistProfileScreen
                _buildDrawerItem(Icons.person, "My Profile", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpecialistProfileScreen()),
                  );
                }),
                _divider(),
                _buildDrawerItem(Icons.people, "My Patients", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPatientsScreen()),
                  );
                }),
                _divider(),
                _buildDrawerItem(Icons.timeline, "Trends and History", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PatientTrendsHistory()),
                  );
                }),
                _divider(),
                _buildDrawerItem(Icons.insert_drive_file, "Reports", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PatientReportsScreen()),
                  );
                }),
                _divider(),
                // Settings navigation
                _buildDrawerItem(Icons.settings, "Settings", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SpecialistSettings()),
                  );
                }),
                _divider(),
                _buildDrawerItem(Icons.info, "About", onTap: () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: const Color.fromARGB(255, 82, 82, 82), size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Divider(
      color: Colors.grey,
      thickness: 0.8,
      indent: 20,
      endIndent: 20,
    );
  }
}
