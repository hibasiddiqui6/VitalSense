import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Modules/welcome_page.dart';
import '../Modules/specialist_dashboard.dart';
import '../Modules/specialist_profile.dart';
import '../Modules/specialist_patients.dart';
import '../Modules/specialist_settings.dart';
import '../Modules/about_us.dart';
import '../Modules/specialist_patient_trends.dart';
import '../Modules/specialist_patient_reports.dart';

class SpecialistDrawer extends StatelessWidget {
  final String fullName;
  final String email;

  const SpecialistDrawer({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header with user info
          Container(
            width: screenWidth,
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, vertical: screenHeight * 0.08),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 154, 180, 154),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.06,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person,
                      size: screenWidth * 0.08, color: Colors.black54),
                ),
                SizedBox(width: screenWidth * 0.031),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.043,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      Text(
                        email,
                        style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.031),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard, "Dashboard", context,
                    const SpecialistDashboard()),
                _divider(),

                _buildDrawerItem(Icons.person, "My Profile", context,
                    const SpecialistProfileScreen()),
                _divider(),

                _buildDrawerItem(Icons.people, "My Patients", context,
                    const MyPatientsScreen()),
                _divider(),

                _buildDrawerItem(Icons.timeline, "Trends and History", context,
                    const Specialist_Patients_TrendsHistory()),
                _divider(),

                _buildDrawerItem(Icons.insert_drive_file, "Reports", context,
                    const Specialist_Patients_Reports()),
                _divider(),

                _buildDrawerItem(
                    Icons.settings, "Settings", context, SpecialistSettings()),
                _divider(),

                _buildDrawerItem(Icons.info, "About", context, const AboutUs()),
                const Divider(),

                // Logout Button
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Drawer Item Widget
  Widget _buildDrawerItem(
      IconData icon, String title, BuildContext context, Widget screen) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      leading:
          Icon(icon, color: const Color.fromARGB(255, 82, 82, 82), size: 28),
      title: Text(
        title,
        style: TextStyle(fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
      },
    );
  }

  /// Divider Widget
  Widget _divider() {
    return const Divider(
      color: Colors.grey,
      thickness: 0.8,
      indent: 20,
      endIndent: 20,
    );
  }

  /// Handle Logout Function
  void _handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored session data
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (route) => false,
    );
  }
}
