import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/patient_drawer.dart'; // Importing the drawer
import 'package:shared_preferences/shared_preferences.dart';

class PatientSettings extends StatefulWidget {
  const PatientSettings({super.key});

  @override
  _PatientSettingsState createState() => _PatientSettingsState();
}

class _PatientSettingsState extends State<PatientSettings> {
  bool notificationsEnabled = false;
  bool locationEnabled = false;
  String fullName = "Loading...";
  String email = "example@example.com";

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  /// Load user details for drawer
  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
    });
  }

  /// Request notification permission
  Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    setState(() {
      notificationsEnabled = status.isGranted;
    });
  }

  /// Request location permission
  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();

    setState(() {
      locationEnabled = status.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 239, 238, 229),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Hamburger color
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: PatientDrawer(
          fullName: fullName,
          email: email,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Notifications toggle
            SettingTile(
              title: "Notifications",
              hasSwitch: true,
              switchValue: notificationsEnabled,
              onChanged: (value) async {
                if (value) {
                  await requestNotificationPermission();
                } else {
                  setState(() {
                    notificationsEnabled = false;
                  });
                }
              },
            ),
            // Location toggle
            SettingTile(
              title: "Location",
              hasSwitch: true,
              switchValue: locationEnabled,
              onChanged: (value) async {
                if (value) {
                  await requestLocationPermission();
                } else {
                  setState(() {
                    locationEnabled = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Setting Tile Widget
class SettingTile extends StatelessWidget {
  final String title;
  final bool hasSwitch;
  final bool? switchValue;
  final Function(bool)? onChanged;

  const SettingTile({super.key, 
    required this.title,
    this.hasSwitch = false,
    this.switchValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 199, 206, 194),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black)),
          if (hasSwitch)
            Switch(
              value: switchValue ?? false,
              onChanged: onChanged,
              activeColor: const Color(0xFF3A3A3A),
              inactiveThumbColor: const Color(0xFF6D6D6D),
              activeTrackColor: const Color(0xFFEAE6E6),
              inactiveTrackColor: const Color(0xFFEAE6E6),
            ),
        ],
      ),
    );
  }
}
