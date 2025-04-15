import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/widgets/patient_drawer.dart';
import '../services/api_client.dart';
import 'patient_wifi_setup.dart';

class SmartShirtManagementScreen extends StatefulWidget {
  const SmartShirtManagementScreen({super.key});

  @override
  _SmartShirtManagementScreenState createState() => _SmartShirtManagementScreenState();
}

class _SmartShirtManagementScreenState extends State<SmartShirtManagementScreen> {
  List<dynamic>? smartShirts; 
  bool isLoading = false;
  String fullName = "...";
  String email = "...";
  String patientId = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);   // <-- only here

    await _loadUserDetails();
    await _fetchSmartShirts();

    setState(() => isLoading = false);  // <-- only after both done
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    fullName = prefs.getString("full_name") ?? "Unknown User";
    email = prefs.getString("email") ?? "example@example.com";
    patientId = prefs.getString("patient_id") ?? "";

    if (kDebugMode) {
      print("🔍 Loaded patient_id in SmartShirt screen: $patientId");
    }

    setState(() {}); // optional: only if UI needs fullName/email refreshed
  }

  Future<void> _fetchSmartShirts() async {
    smartShirts = null;
    setState(() {}); // Trigger loading spinner

    try {
      final result = await ApiClient().getSmartShirts(patientId);

      if (result.containsKey("error")) {
        if (kDebugMode) {
          print("❌ Error: ${result['error']}");
        }
        smartShirts = [];
      } else {
        smartShirts = result['smartshirts'] ?? [];
      }

      if (kDebugMode) {
        print("🧩 SmartShirts fetched: $smartShirts");
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      if (kDebugMode) {
        print("❌ Exception: $e");
      }
      smartShirts = [];
      setState(() {});
    }
  }

  Future<void> _deleteSmartShirt(String macAddress) async {
    final success = await ApiClient().deleteSmartShirt(macAddress);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("smartshirt_registered", false);

      setState(() {
        smartShirts?.removeWhere((s) => s['devicemac'] == macAddress); 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ SmartShirt deleted.")),
      );

      // Navigate to Wi-Fi setup screen
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PatientWifiSetup()),
            (route) => false,
          );
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to delete SmartShirt.")),
      );
    }
  }

  void _confirmDeleteSmartShirt(String macAddress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete SmartShirt"),
        content: const Text("Are you sure you want to delete this SmartShirt?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSmartShirt(macAddress);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
      backgroundColor: Color.fromARGB(255, 239, 238, 229),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 239, 238, 229),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: PatientDrawer(fullName: fullName, email: email),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.032,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "My SmartShirts",
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            Expanded(
              child: smartShirts == null
                  ? const Center(child: CircularProgressIndicator())
                  : smartShirts!.isEmpty
                      ? const Center(child: Text("No SmartShirts connected."))
                      : ListView.builder(
                          itemCount: smartShirts!.length,
                          itemBuilder: (context, index) {
                            final shirt = smartShirts![index];
                            final mac = shirt["deviceMac"] ?? "Unknown";
                            final status = shirt["shirtStatus"] == true ? "Connected" : "Disconnected";

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: const Color.fromARGB(255, 224, 233, 217),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                title: Text(
                                  "Device MAC: $mac",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  "Status: $status",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _confirmDeleteSmartShirt(mac);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text("Remove Device"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

          ],
        ),
      ),
    );
  }
}
