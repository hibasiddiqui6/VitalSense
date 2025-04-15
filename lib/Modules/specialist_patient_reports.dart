import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/Modules/reports_history.dart';
import '../services/api_client.dart';
import '../widgets/specialist_drawer.dart';

class Specialist_Patients_Reports extends StatefulWidget {
  const Specialist_Patients_Reports({super.key});

  @override
  State<Specialist_Patients_Reports> createState() => _Specialist_Patients_ReportsState();
}

class _Specialist_Patients_ReportsState extends State<Specialist_Patients_Reports> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  String fullName = "...";
  String email = "...";

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Focus for search

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _loadUserDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Load patients list from API
  Future<void> _loadPatients() async {
    final fetchedPatients = await ApiClient.fetchSpecialistPatients();
    setState(() {
      patients = fetchedPatients;
      filteredPatients = List.from(fetchedPatients);
      isLoading = false;
    });
  }

  /// Filter patients as per search input
  void _filterPatients(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredPatients = query.isEmpty
          ? List.from(patients)
          : patients.where((patient) {
              final name = patient['fullname'].toString().toLowerCase();
              return name.contains(lowerQuery);
            }).toList();
    });
  }

  /// Load specialist profile from shared preferences
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "-";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SpecialistDrawer(fullName: fullName, email: email),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 154, 180, 154),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _buildSearchBar(),
      ),
      body: Column(
        children: [
          // Curved header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 154, 180, 154),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1)],
            ),
            child: const Text(
              "Patients Reports",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),

          // List of Patients
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPatients.isEmpty
                    ? const Center(
                        child: Text(
                          "No patients found.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : _buildPatientList(),
          ),
        ],
      ),
    );
  }

  /// Search Bar Widget
  Widget _buildSearchBar() {
    return Padding(
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
            Expanded(
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onChanged: _filterPatients,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Search patient...",
                  hintStyle: TextStyle(color: Color.fromARGB(179, 103, 103, 103)),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.black),
                onPressed: () {
                  _searchController.clear();
                  _filterPatients('');
                  _searchFocusNode.unfocus();
                },
              ),
            IconButton(
              icon: const Icon(Icons.search, color: Color.fromARGB(179, 103, 103, 103)),
              onPressed: () {
                _filterPatients(_searchController.text);
                _searchFocusNode.unfocus();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build List of Patients
  Widget _buildPatientList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(15),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                tileColor: Colors.white,
                leading: const Icon(Icons.person_outlined, color: Colors.black54),
                title: Text(
                  patient['fullname'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text("ID: ${patient['patientid'].split('-').take(2).join('-')}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportHistoryScreen(patientId: patient['patientid'], patientName: patient['fullname'],),
                    ),
                  );
                },

              ),
            ),
          );
        },
      ),
    );
  }
}
