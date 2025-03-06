import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'all_vitals.dart';

void main() {
  runApp(SettingsScreen());
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = false;
  bool locationEnabled = false;

  Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isGranted) {
      setState(() {
        notificationsEnabled = true;
      });
    } else {
      setState(() {
        notificationsEnabled = false;
      });
    }
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        locationEnabled = true;
      });
    } else {
      setState(() {
        locationEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFFAF9F4),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                },
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 30),
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
              SettingTile(
                title: "Location",
                hasSwitch: true,
                switchValue: locationEnabled,
                onChanged: (value) {
                  if (value) {
                    requestLocationPermission();
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
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final String title;
  final bool hasSwitch;
  final bool? switchValue;
  final Function(bool)? onChanged;

  const SettingTile({
    required this.title,
    this.hasSwitch = false,
    this.switchValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      padding: EdgeInsets.symmetric(horizontal: 15),
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFFD1D6CA),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.black)),
          if (hasSwitch)
            Switch(
              value: switchValue ?? false,
              onChanged: onChanged,
              activeColor: Color(0xFF3A3A3A),
              inactiveThumbColor: Color(0xFF6D6D6D),
              activeTrackColor: Color(0xFFEAE6E6),
              inactiveTrackColor: Color(0xFFEAE6E6),
            ),
        ],
      ),
    );
  }
}
