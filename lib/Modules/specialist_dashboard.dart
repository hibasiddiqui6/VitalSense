import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/specialist_drawer.dart';
import 'specialist_patients.dart';
import 'specialist_patient_insights.dart';

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
          : patients
              .where((p) => p['fullname'].toLowerCase().contains(lowerQuery))
              .toList();
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      extendBodyBehindAppBar:
          true, // This allows the body to go under the AppBar

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 238, 64, 64),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: SpecialistDrawer(
          fullName: fullName, // fetched and stored in State
          email: email, // fetched and stored in State
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 254, 250),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                // -Background Circles
                Positioned(
                  top: screenHeight * -0.15, // 15% of screen height
                  left: screenWidth * 0.45, // 45% of screen width
                  child: Container(
                    width: screenWidth * 0.9, // 90% of screen width
                    height: screenHeight * 0.5, // 50% of screen height
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(120, 219, 237, 219),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * -0.1, // 10% of screen height
                  left: screenWidth * -0.25, // 25% of screen width
                  child: Container(
                    width: screenWidth * 0.6, // 60% of screen width
                    height: screenHeight * 0.3, // 30% of screen height
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(120, 219, 237, 219),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // -Main Scrollable Content
                _buildMainContent(context),
              ],
            ),
            // -Search Dropdown if Searching
            if (isSearching) _buildSearchDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, vertical: screenHeight * 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // -Profile Header
            Text('Hi! $fullName',
                style: TextStyle(
                    fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
            Text('$profession, $speciality',
                style: TextStyle(
                    fontSize: screenWidth * 0.035, color: Colors.grey)),

            SizedBox(height: screenHeight * 0.02),

            // -Search Bar
            _buildSearchBar(),

            SizedBox(height: screenHeight * 0.035),

            // -Total Patients Card with Count and Add Button
            _buildTotalPatientsCard(),

            SizedBox(height: screenHeight * 0.04),

            // -Recently Added Section (Only if not searching)
            if (!isSearching) ..._buildRecentlyAddedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025), // 2.5% of screen width
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 186, 216, 186),
        borderRadius: BorderRadius.circular(
          screenWidth * 0.06,
        ),
      ),
      child: TextField(
        focusNode: _searchFocusNode,
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: InputDecoration(
          hintText: "Search patient",
          hintStyle: TextStyle(
            fontSize: screenWidth * 0.04, // 4% of screen width
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, // 4% of screen width
            vertical: screenHeight * 0.015, // 1.5% of screen height
          ),
          border: InputBorder.none,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                    icon: const Icon(Icons.clear), onPressed: _clearSearch),
              IconButton(
                icon: Icon(Icons.search,
                    size: screenWidth * 0.06), // 6% of screen width
                onPressed: () {
                  _filterPatients(_searchController.text);
                  _searchFocusNode.unfocus();
                },
              ),
            ],
          ),
        ),
        style: TextStyle(
          fontSize: screenWidth * 0.045, // 4.5% of screen width
        ),
      ),
    );
  }

  Widget _buildTotalPatientsCard() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.050),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.050),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(screenWidth * 0.04), // 4% of screen width
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 224, 233, 217),
              Color.fromARGB(255, 159, 179, 149),
              Color.fromARGB(255, 158, 180, 146),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total No. of Patients",
                    style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500),
                    maxLines: 2,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "~${patients.length}", // Dynamic patient count
                    style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) =>
                    AddPatientPopup(onPatientAdded: _loadPatients),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.045, // 4.5% of screen width
                    vertical: screenHeight * 0.012), // 1.2% of screen height
              ),
              child: const Text("+ Add Patient",
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentlyAddedSection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return [
      Text("Recently Added Patients:",
          style: TextStyle(
              fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
      SizedBox(height: screenHeight * 0.01),
      if (isLoading)
        const CircularProgressIndicator()
      else if (filteredPatients.isEmpty)
        const Text("No patients found.", style: TextStyle(color: Colors.grey)),
      ...filteredPatients.take(3).map((p) =>
          PatientCard(patientName: p['fullname'], patientId: p['patientid'])),
      if (filteredPatients.length > 3)
        TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyPatientsScreen())),
          child: const Text("See All Patients"),
        ),
    ];
  }

  Widget _buildSearchDropdown() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Positioned(
      top: screenHeight * 0.3, // 30% of screen height
      left: screenWidth * 0.05, // 5% of screen width
      right: screenWidth * 0.05, // 5% of screen width
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.02), // 2% of screen width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(screenWidth * 0.03), // 3% of screen width
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: filteredPatients.isEmpty
            ? const Center(
                child: Text("No patients found.",
                    style: TextStyle(color: Colors.grey)))
            : Column(
                children: [
                  const Text("Search Results:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...filteredPatients.map((p) => PatientCard(
                      patientName: p['fullname'], patientId: p['patientid'])),
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

  const PatientCard(
      {super.key, required this.patientName, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.only(
          bottom: screenHeight * 0.015), // 1.5% of screen height
      padding: EdgeInsets.all(screenHeight * 0.02),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 172, 202, 172),
        borderRadius: BorderRadius.circular(screenWidth * 0.031),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              patientName,
              style: TextStyle(
                  fontSize: screenWidth * 0.045, // 4.5% of screen width
                  fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PatientInsightsScreen(patientId: patientId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04)),
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
  final VoidCallback
      onPatientAdded; // Callback function to refresh patient list

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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 204, 215, 188),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
        screenWidth * 0.04,
      )), // 4% of screen width
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Enter Patient ID",
              style: TextStyle(
                  fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
          SizedBox(height: screenHeight * 0.025), // 2.5% of screen height
          TextField(
            controller: _idController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(
                      screenWidth * 0.03))), // 3% of screen width
            ),
          ),
          SizedBox(height: screenHeight * 0.02), // 2% of screen height
          ElevatedButton(
            onPressed: isLoading ? null : _handleAddPatient,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 119, 147, 120),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.033)),
              minimumSize: const Size(110, 40),
            ),
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : Text("Add",
                    style: TextStyle(
                        fontSize: screenWidth * 0.031, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
