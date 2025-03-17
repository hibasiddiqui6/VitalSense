import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/specialist_drawer.dart';
import 'specialist_patients.dart';
import 'patient_insights.dart';

class SpecialistDashboard extends StatefulWidget {
  const SpecialistDashboard({super.key});

  @override
  State<SpecialistDashboard> createState() => _SpecialistDashboardState();
}

class _SpecialistDashboardState extends State<SpecialistDashboard> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  bool isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String fullName = "...";
  String email = "...";
  String profession = "-";
  String speciality = "-";

  @override
  void initState() {
    super.initState();
    _loadPatients();
    fetchUserProfile();
    _loadUserDetails();
  }

  Future<void> _loadPatients() async {
    final fetchedPatients = await ApiClient.fetchSpecialistPatients();
    setState(() {
      patients = fetchedPatients;
      filteredPatients = List.from(fetchedPatients);
      isLoading = false;
    });
  }

  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiClient().getSpecialistProfile();
      if (data.containsKey("error")) return;

      setState(() {
        fullName = data["fullname"] ?? "Unknown User";
        email = data["email"] ?? "-";
        profession = data["profession"] ?? "-";
        speciality = data["speciality"] ?? "-";
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("full_name", fullName);
      await prefs.setString("email", email);
      await prefs.setString("profession", profession);
      await prefs.setString("speciality", speciality);
    } catch (e) {
      print("Failed to fetch profile: $e");
    }
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      profession = prefs.getString("profession") ?? "-";
      speciality = prefs.getString("speciality") ?? "-";
      email = prefs.getString("email") ?? "-";
    });
  }

  void _filterPatients(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      filteredPatients = query.isEmpty
          ? List.from(patients)
          : patients.where((p) => p['fullname'].toLowerCase().contains(lowerQuery)).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      filteredPatients = List.from(patients);
    });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: SpecialistDrawer(fullName: fullName, email: email),
    backgroundColor: const Color.fromARGB(255, 255, 254, 250),
    body: Stack(
      children: [
        // -Background Circles
        Positioned(
          top: -150,
          left: 180,
          child: Container(
            width: 430,
            height: 430,
            decoration: const BoxDecoration(
              color: Color.fromARGB(120, 219, 237, 219),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              color: Color.fromARGB(120, 219, 237, 219),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // -Main Scrollable Content
        _buildMainContent(context),

        // -Search Dropdown if Searching
        if (isSearching) _buildSearchDropdown(),
      ],
    ),
  );
}

Widget _buildMainContent(BuildContext context) {
  return SizedBox(
    height: MediaQuery.of(context).size.height,
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -Menu Icon
          Builder(
            builder: (context) => Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // -Profile Header
          Text('Hi! $fullName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('$profession, $speciality', style: const TextStyle(fontSize: 14, color: Colors.grey)),

          const SizedBox(height: 20),

          // -Search Bar
          _buildSearchBar(),

          const SizedBox(height: 35),

          // -Total Patients Card with Count and Add Button
          _buildTotalPatientsCard(),

          const SizedBox(height: 40),

          // -Recently Added Section (Only if not searching)
          if (!isSearching) ..._buildRecentlyAddedSection(),
        ],
      ),
    ),
  );
}

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 186, 216, 186),
        borderRadius: BorderRadius.circular(26),
      ),
      child: TextField(
        focusNode: _searchFocusNode,
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: InputDecoration(
          hintText: "Search patient",
          border: InputBorder.none,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _filterPatients(_searchController.text);
                  _searchFocusNode.unfocus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildTotalPatientsCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 224, 233, 217),
            Color.fromARGB(255, 159, 179, 149),
            Color.fromARGB(255, 158, 180, 146),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(4, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total No. of Patients",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  "~${patients.length}", // Dynamic patient count
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddPatientPopup(onPatientAdded: _loadPatients),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text("+ Add Patient", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

  List<Widget> _buildRecentlyAddedSection() {
    return [
      const Text("Recently Added Patients:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (isLoading)
        const CircularProgressIndicator()
      else if (filteredPatients.isEmpty)
        const Text("No patients found.", style: TextStyle(color: Colors.grey)),
      ...filteredPatients.take(3).map((p) => PatientCard(patientName: p['fullname'], patientId: p['patientid'])),
      if (filteredPatients.length > 3)
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPatientsScreen())),
          child: const Text("See All Patients"),
        ),
    ];
  }

  Widget _buildSearchDropdown() {
    return Positioned(
      top: 260,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: filteredPatients.isEmpty
            ? const Center(child: Text("No patients found.", style: TextStyle(color: Colors.grey)))
            : Column(
                children: [
                  const Text("Search Results:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...filteredPatients.map((p) => PatientCard(patientName: p['fullname'], patientId: p['patientid'])),
                ],
              ),
      ),
    );
  }
}

// Reusable Patient Card Widget
class PatientCard extends StatelessWidget {
  final String patientName;
  final String patientId;

  const PatientCard({super.key, required this.patientName, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 172, 202, 172),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientInsightsScreen(patientId: patientId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("View Insights"),
          ),
        ],
      ),
    );
  }
}

// Add Patient Popup with API Call Integration
class AddPatientPopup extends StatefulWidget {
  final VoidCallback onPatientAdded; // Callback function to refresh patient list

  const AddPatientPopup({super.key, required this.onPatientAdded});

  @override
  State<AddPatientPopup> createState() => _AddPatientPopupState();
}

class _AddPatientPopupState extends State<AddPatientPopup> {
  final TextEditingController _idController = TextEditingController();
  bool isLoading = false;

  Future<void> _handleAddPatient() async {
    final patientId = _idController.text.trim();
    if (patientId.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    final result = await ApiClient.addPatientById(patientId);

    setState(() {
      isLoading = false;
    });

    // Close the input popup first
    Navigator.of(context).pop();

    // After closing input popup, show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.containsKey('message') ? 'Success' : 'Error'),
        content: Text(result['message'] ?? result['error'] ?? 'Unknown error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close result dialog
              if (result.containsKey('message')) {
                widget.onPatientAdded(); // Refresh patient list if successful
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 204, 215, 188),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter Patient ID", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(13))),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: isLoading ? null : _handleAddPatient,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 119, 147, 120),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
              minimumSize: const Size(110, 40),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text("Add", style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
