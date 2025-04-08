import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    print("🔍 Loaded patient_id in SmartShirt screen: $patientId");

    setState(() {}); // optional: only if UI needs fullName/email refreshed
  }

  Future<void> _fetchSmartShirts() async {
    smartShirts = null;
    setState(() {}); // Trigger loading spinner

    try {
      final result = await ApiClient().getSmartShirts(patientId);

      if (result.containsKey("error")) {
        print("❌ Error: ${result['error']}");
        smartShirts = [];
      } else {
        smartShirts = result['smartshirts'] ?? [];
      }

      print("🧩 SmartShirts fetched: $smartShirts");
      setState(() {}); // Refresh UI
    } catch (e) {
      print("❌ Exception: $e");
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

  void _resetWifiFromBackend(String ip) async {
    final url = Uri.parse("http://$ip/reset_wifi");

    final status = await ApiClient.simpleGetRequest(url);
    if (status == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ ESP32 Wi-Fi reset triggered.")),
      );

      // Clear flag from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("smartshirt_registered", false);

      // Navigate to Wi-Fi setup screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PatientWifiSetup()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to reset ESP32 Wi-Fi.")),
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

  void _showWifiResetFallbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Can't reach ESP32"),
        content: const Text(
            "If your ESP32 is not responding and the original Wi-Fi is unavailable:\n\n"
            "🔌 Unplug and replug your SmartShirt.\n"
            "📶 Wait for it to create a Wi-Fi hotspot named 'ESP32_Setup'.\n"
            "📲 Reconnect to that network and configure your Wi-Fi again."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("My SmartShirts"),
        backgroundColor: const Color.fromARGB(255, 193, 219, 188),
      ),
      body: smartShirts == null
        ? const Center(child: CircularProgressIndicator())  // still loading
        : smartShirts!.isEmpty
            ? const Center(child: Text("No SmartShirts connected."))
            : ListView.builder(
                padding: EdgeInsets.all(screenWidth * 0.04),
                itemCount: smartShirts!.length,
                itemBuilder: (context, index) {
                  final shirt = smartShirts![index];
                  return Card(
                    elevation: 3,
                    color: const Color.fromARGB(255, 224, 233, 217),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: ListTile(
                      title: Text(
                        "MAC: ${shirt['deviceMac'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 14), // You can tweak this size
                      ),
                      subtitle: Text("Status: ${shirt['shirtStatus'] == true ? 'Connected' : 'Disconnected'}"),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDeleteSmartShirt(shirt['deviceMac']);
                          } else if (value == 'reset') {
                            final ip = shirt['ip_address'];
                            if (ip != null && ip.toString().isNotEmpty) {
                              _resetWifiFromBackend(ip);
                            } else {
                              _showWifiResetFallbackDialog();
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'reset', child: Text("Reset Wi-Fi")),
                          PopupMenuItem(value: 'delete', child: Text("Remove Device")),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
      }
  }
