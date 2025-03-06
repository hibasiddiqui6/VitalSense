import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'all_vitals.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TrustedContactsScreen(),
    );
  }
}

class TrustedContactsScreen extends StatefulWidget {
  @override
  _TrustedContactsScreenState createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, dynamic>> contacts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  /// **Fetch Trusted Contacts from Database**
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

  /// **Show Add Contact Dialog**
  void _addContact() {
    TextEditingController nameController = TextEditingController();
    TextEditingController numberController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Trusted Contact"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Name")),
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
                if (isSubmitting) CircularProgressIndicator(),
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (numberController.text.length != 11) {
                            _showErrorSnackbar("Contact number must be exactly 11 digits.");
                            return;
                          }
                          setState(() => isSubmitting = true);
                          bool success = await ApiClient().addTrustedContact(
                            nameController.text, numberController.text,
                          );
                          if (success) {
                            _fetchContacts();
                            Navigator.pop(context);
                          }
                        },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// **Show Edit Contact Dialog**
  void _showEditDialog(Map<String, dynamic> contact) {
    TextEditingController nameController = TextEditingController(text: contact['ContactName']);
    TextEditingController numberController = TextEditingController(text: contact['ContactNumber']);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Contact"),
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
                if (isSubmitting) CircularProgressIndicator(),
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (numberController.text.length != 11) {
                            _showErrorSnackbar("Contact number must be exactly 11 digits.");
                            return;
                          }
                          setState(() => isSubmitting = true);
                          bool success = await ApiClient().updateTrustedContact(
                            contact['ContactID'], nameController.text, numberController.text,
                          );
                          if (success) {
                            _fetchContacts();
                            Navigator.pop(context);
                          }
                        },
                  child: Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// **Delete Contact**
  void _deleteContact(int contactId) async {
    setState(() => isLoading = true);
    bool success = await ApiClient().deleteTrustedContact(contactId);
    if (success) {
      _fetchContacts();
    }
  }

  /// **Show Snackbar for Errors**
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black54, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                },
              ),
            ),

            SizedBox(height: 10),

            // Header Title and Add Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trusted Contacts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.black54, size: 28),
                    onPressed: _addContact,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Loading Indicator
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              // Trusted Contacts Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  color: Color(0xFFD1D6CA),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: contacts.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  "No trusted contacts added.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            ]
                          : contacts.map((contact) => _buildContactRow(contact)).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// **Build Contact Row**
  Widget _buildContactRow(Map<String, dynamic> contact) {
    return ListTile(
      title: Text(contact['ContactName']),
      subtitle: Text(contact['ContactNumber']),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'Edit') _showEditDialog(contact);
          if (value == 'Delete') _deleteContact(contact['ContactID']);
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'Edit', child: Text("Edit")),
          PopupMenuItem(value: 'Delete', child: Text("Delete")),
        ],
      ),
    );
  }
}
