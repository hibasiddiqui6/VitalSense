import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/Modules/patient_trends_selector.dart';
import '../Modules/welcome_page.dart';
import '../Modules/patient_dashboard.dart';
import '../Modules/patient_profile.dart';
import '../Modules/patient_trusted_contacts.dart';
import '../Modules/patient_settings.dart';
import '../Modules/about_us.dart';
import '../Modules/patient_wifi_setup.dart';
import '../Modules/patient_smartshirt_manager.dart';
import '../Modules/reports_history.dart';

class PatientDrawer extends StatefulWidget {
  final String fullName;
  final String email;

  const PatientDrawer({super.key, required this.fullName, required this.email});

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
              color: Color.fromARGB(255, 193, 219, 188),
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
                        widget.fullName,
                        style: TextStyle(
                            fontSize: screenWidth * 0.043,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      Text(
                        widget.email,
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
                _buildDrawerItem(
                  Icons.dashboard,
                  "Dashboard",
                  () {
                    _navigateTo(
                        context,
                        smartShirtRegistered
                            ? PatientDashboard()
                            : PatientWifiSetup());
                  },
                ),
                _divider(),

                _buildDrawerItem(Icons.person, "My Profile", () {
                  _navigateTo(context, PatientProfileScreen());
                }),
                _divider(),

                _buildDrawerItem(Icons.sensor_window, "My SmartShirts", () {
                  _navigateTo(context, SmartShirtManagementScreen());
                }),
                _divider(),

                _buildDrawerItem(Icons.contacts, "Trusted Contacts", () {
                  _navigateTo(context, TrustedContactsScreen());
                }),
                _divider(),

                // Add these when implemented
                _buildDrawerItem(Icons.timeline, "Trends and History", () {
                  _navigateTo(context, const PatientTrends());
                }),
                _divider(),

                _buildDrawerItem(Icons.insert_drive_file, "Reports", () {
                  _navigateTo(context, const ReportHistoryScreen());
                }),
                _divider(),

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
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      leading:
          Icon(icon, color: const Color.fromARGB(255, 82, 82, 82), size: 28),
      title: Text(
        title,
        style: TextStyle(
            fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500),
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
