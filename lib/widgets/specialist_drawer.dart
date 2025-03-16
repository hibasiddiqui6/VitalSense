import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Modules/welcome_page.dart';
import '../Modules/specialist_dashboard.dart';
import '../Modules/specialist_profile.dart';
import '../Modules/specialist_patients.dart';
import '../Modules/specialist_settings.dart';
import '../Modules/about_us.dart';
import '../Modules/patient_trends.dart';
import '../Modules/patient_reports.dart';

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
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header with user info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 193, 219, 188),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.black54),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
                _buildDrawerItem(Icons.dashboard, "Dashboard", context, const SpecialistDashboard()),
                _divider(),

                _buildDrawerItem(Icons.person, "My Profile", context, const SpecialistProfileScreen()),
                _divider(),

                _buildDrawerItem(Icons.people, "My Patients", context, const MyPatientsScreen()),
                _divider(),

                _buildDrawerItem(Icons.timeline, "Trends and History", context, const PatientTrendsHistory()),
                _divider(),

                _buildDrawerItem(Icons.insert_drive_file, "Reports", context, const PatientReportsScreen()),
                _divider(),

                _buildDrawerItem(Icons.settings, "Settings", context, SpecialistSettings()),
                _divider(),

                _buildDrawerItem(Icons.info, "About", context, const AboutUs()),
                const Divider(),

                // Logout Button
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
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
  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Widget screen) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: const Color.fromARGB(255, 82, 82, 82), size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
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
