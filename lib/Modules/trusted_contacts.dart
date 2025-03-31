import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../widgets/patient_drawer.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  _TrustedContactsScreenState createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, dynamic>> contacts = [];
  bool isLoading = false;
  bool isSaving = false; // 👈 Add for saving overlay
  String fullName = "...";
  String email = "...";

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _loadUserDetails();
  }

  /// Fetch Trusted Contacts from Database
  Future<void> _fetchContacts() async {
    setState(() => isLoading = true);
    try {
      final contactsList = await ApiClient().getTrustedContacts();
      setState(() {
        contacts = contactsList;
      });
    } catch (e) {
      print("❌ Error fetching contacts: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Load user details for Drawer
  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString("full_name") ?? "Unknown User";
      email = prefs.getString("email") ?? "example@example.com";
    });
  }

  /// Show Add Contact Dialog
  void _addContact() {
    TextEditingController nameController = TextEditingController();
    TextEditingController numberController = TextEditingController();

    _showContactDialog(
      title: "Add Trusted Contact",
      nameController: nameController,
      numberController: numberController,
      onSave: () async {
        if (numberController.text.length != 11) {
          _showErrorSnackbar("Contact number must be exactly 11 digits.");
          return;
        }
        setState(() => isSaving = true);
        bool success = await ApiClient().addTrustedContact(
          nameController.text, numberController.text,
        );
        setState(() => isSaving = false);
        if (success) {
          _fetchContacts();
          Navigator.pop(context);
        }
      },
    );
  }

  /// Show Edit Contact Dialog
  void _showEditDialog(Map<String, dynamic> contact) {
    TextEditingController nameController = TextEditingController(text: contact['contactname']);
    TextEditingController numberController = TextEditingController(text: contact['contactnumber']);

    _showContactDialog(
      title: "Edit Contact",
      nameController: nameController,
      numberController: numberController,
      onSave: () async {
        if (numberController.text.length != 11) {
          _showErrorSnackbar("Contact number must be exactly 11 digits.");
          return;
        }
        setState(() => isSaving = true);
        bool success = await ApiClient().updateTrustedContact(
          contact['contactid'], nameController.text, numberController.text,
        );
        setState(() => isSaving = false);
        if (success) {
          _fetchContacts();
          Navigator.pop(context);
        }
      },
    );
  }

  /// Delete Contact
  void _deleteContact(int contactId) async {
    setState(() => isSaving = true);
    bool success = await ApiClient().deleteTrustedContact(contactId);
    setState(() => isSaving = false);
    if (success) _fetchContacts();
  }

  /// Show Contact Dialog
  void _showContactDialog({
    required String title,
    required TextEditingController nameController,
    required TextEditingController numberController,
    required VoidCallback onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            SizedBox(height: 10),
            TextField(
              controller: numberController,
              decoration: InputDecoration(labelText: "Contact Number"),
              keyboardType: TextInputType.number,
              maxLength: 11,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(onPressed: onSave, child: Text("Save")),
        ],
      ),
    );
  }

  /// Show Error Snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  /// Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: PatientDrawer(fullName: fullName, email: email),
      backgroundColor: const Color.fromARGB(255, 239, 238, 229),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu Icon instead of back button
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Colors.black54, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Trusted Contacts',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 10),

                // Add Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.black54, size: 28),
                        onPressed: _addContact,
                      ),
                    ],
                  ),
                ),

                // List or Loading or Empty
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : contacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.contacts_outlined, size: 50, color: Colors.grey[400]),
                                  const Text(
                                    "No trusted contacts added.",
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: contacts.length,
                              itemBuilder: (context, index) => _buildContactRow(contacts[index]),
                            ),
                ),
              ],
            ),
          ),
          if (isSaving) // Saving overlay
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green, strokeWidth: 5),
              ),
            ),
        ],
      ),
    );
  }

  /// Build Contact Row
  Widget _buildContactRow(Map<String, dynamic> contact) {
  return Card(
    color: const Color.fromARGB(255, 224, 233, 217), // Light green background
    elevation: 3, // Elevation for subtle shadow
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15), // Rounded corners
    ),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: ListTile(
      title: Text(
        contact['contactname'],
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        contact['contactnumber'],
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.black87), // Black icon for consistency
        onSelected: (value) {
          if (value == 'Edit') _showEditDialog(contact);
          if (value == 'Delete') _deleteContact(contact['contactid']);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'Edit',
            child: Text("Edit"),
          ),
          const PopupMenuItem(
            value: 'Delete',
            child: Text("Delete"),
          ),
        ],
      ),
    ),
  );
}
}
