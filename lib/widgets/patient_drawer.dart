import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Modules/welcome_page.dart';
import '../Modules/patient_dashboard.dart';
import '../Modules/patient_profile.dart';
import '../Modules/trusted_contacts.dart';
import '../Modules/patient_settings.dart';
import '../Modules/about_us.dart';
import '../Modules/patient_wifi_setup.dart';
// Import trends/reports when available
// import '../Modules/patient_trends.dart';
// import '../Modules/patient_reports.dart';

class PatientDrawer extends StatefulWidget {
  final String fullName;
  final String email;

  const PatientDrawer({Key? key, required this.fullName, required this.email}) : super(key: key);

  @override
  State<PatientDrawer> createState() => _PatientDrawerState();
}

class _PatientDrawerState extends State<PatientDrawer> {
  bool smartShirtRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkSmartShirtStatus();
  }

  /// Check SmartShirt registration status
  Future<void> _checkSmartShirtStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? registered = prefs.getBool('smartshirt_registered');
    setState(() {
      smartShirtRegistered = registered ?? false;
    });
  }

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
                        widget.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
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
                _buildDrawerItem(
                  Icons.dashboard,
                  "Dashboard",
                  () {
                    _navigateTo(context, smartShirtRegistered ? PatientDashboard() : PatientWifiSetup());
                  },
                ),
                _divider(),

                _buildDrawerItem(Icons.person, "My Profile", () {
                  _navigateTo(context, PatientProfileScreen());
                }),
                _divider(),

                _buildDrawerItem(Icons.contacts, "Trusted Contacts", () {
                  _navigateTo(context, TrustedContactsScreen());
                }),
                _divider(),

                // Add these when implemented
                // _buildDrawerItem(Icons.timeline, "Trends and History", () {
                //   _navigateTo(context, const PatientTrendsHistory());
                // }),
                // _divider(),

                // _buildDrawerItem(Icons.insert_drive_file, "Reports", () {
                //   _navigateTo(context, const PatientReportsScreen());
                // }),
                // _divider(),

                _buildDrawerItem(Icons.settings, "Settings", () {
                  _navigateTo(context, PatientSettings());
                }),
                _divider(),

                _buildDrawerItem(Icons.info, "About", () {
                  _navigateTo(context, const AboutUs());
                }),

                const Divider(), // Separator

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
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: const Color.fromARGB(255, 82, 82, 82), size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer first
        onTap(); // Then navigate
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

  /// Navigate Helper
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Handle Logout Function
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
