import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Main Application
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
      home: const PatientReportsScreen(),
    );
  }
}

// Patient Reports Screen
class PatientReportsScreen extends StatelessWidget {
  const PatientReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: const [
          CurvedHeader(),
          Expanded(child: ReportsList()),
        ],
      ),
    );
  }
}

// Custom App Bar with Back Button & Search Field
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 118, 150, 108),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Padding(
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
              const Icon(Icons.search,
                  color: Color.fromARGB(179, 103, 103, 103)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Curved Header
class CurvedHeader extends StatelessWidget {
  const CurvedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 118, 150, 108),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: const Text(
        "REPORTS",
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

// Reports List
class ReportsList extends StatelessWidget {
  const ReportsList({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> reportTitles = ["View Health Report", "View Disease Report"];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: reportTitles.length,
        itemBuilder: (context, index) {
          return ReportItem(title: reportTitles[index]);
        },
      ),
    );
  }
}

// Report Item
class ReportItem extends StatelessWidget {
  final String title;
  const ReportItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          tileColor: Colors.white,
          leading: const Icon(Icons.insert_drive_file, color: Colors.black54),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 18, color: Colors.black54),
          onTap: () {
            // Add your onTap logic here
          },
        ),
      ),
    );
  }
}
