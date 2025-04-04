import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/Modules/specialist_patient_insights.dart';
import 'package:vitalsense/widgets/specialist_drawer.dart';
import '../services/api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 118, 150, 108),
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const Specialist_PatientsTrendsHistory(),
    );
  }
}

class Specialist_PatientsTrendsHistory extends StatefulWidget {
  const Specialist_PatientsTrendsHistory({super.key});
  @override
  State<Specialist_PatientsTrendsHistory> createState() =>
      _Specialist_PatientsTrendsHistoryState();
}

class _Specialist_PatientsTrendsHistoryState
    extends State<Specialist_PatientsTrendsHistory> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  String role = "-";
  String fullName = "";
  String email = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Focus for search
  bool isLoading = true;

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

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
      role = prefs.getString("role") ?? "-";
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      // Drawer width: 80% of the screen
      drawer: SizedBox(
        width: screenWidth * 0.6,
        child: SpecialistDrawer(fullName: fullName, email: email),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 134, 170, 122),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const SearchBarWidget(),
      ),
      body: Column(
        children: [
          // Curved header
          Container(
            width: screenWidth,
            height: screenHeight * 0.07,
            padding: EdgeInsets.all(screenWidth * 0.031),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 134, 170, 122),
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(screenWidth * 0.04)),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, spreadRadius: 1),
              ],
            ),
            child: Text(
              "Patient Trends and History",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // List of Reports
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

  Widget _buildPatientList() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.032),
      child: ListView.builder(
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.016),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(screenWidth * 0.031),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.031)),
                tileColor: Colors.white,
                leading: const Icon(Icons.timeline, color: Colors.black54),
                title: Text(
                  patient['fullname'],
                  style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                    "ID: ${patient['patientid'].split('-').take(2).join('-')}"),
                trailing: Icon(Icons.arrow_forward_ios,
                            size: screenWidth * 0.036, color: Colors.black54),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientInsightsScreen(
                        patientId: patient['patientid'],
                      ),
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

///Search Field
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    //final double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 242, 244, 241),
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
      ),
      child: Container(
        width: screenWidth * 0.7,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 242, 244, 241),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.031),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Search patient...",
                  hintStyle:
                      TextStyle(color: Color.fromARGB(179, 103, 103, 103)),
                  border: InputBorder.none,
                ),
              ),
            ),
            Icon(Icons.search, color: Color.fromARGB(179, 103, 103, 103)),
          ],
        ),
      ),
    );
  }
}
