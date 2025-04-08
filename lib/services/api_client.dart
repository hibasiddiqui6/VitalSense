
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_database/firebase_database.dart';

class ApiClient {
  static final String _baseUrl = "https://vitalsense-flask-backend.fly.dev";
  
  // Get Base URL
  static String get baseUrl => _baseUrl;
  
   // Fetch Sensor Data from database
  // Future<Map<String, dynamic>> getSensorData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? patientId = prefs.getString("patient_id");

  //   if (patientId == null) {
  //     return {'error': 'Patient ID not found in storage'};
  //   }

  //   final url = Uri.parse('$_baseUrl/get_sensor?patient_id=$patientId');

  //   try {
  //     final response = await http.get(url).timeout(const Duration(seconds: 3));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (!prefs.containsKey("stabilization_start_time")) {
  //         final temp = double.tryParse(data['temperature'].toString()) ?? -100;
  //         if (temp != -100) {
  //           await prefs.setInt("stabilization_start_time", DateTime.now().millisecondsSinceEpoch);
  //         }
  //       }
  //       return data;

  //     } else if (response.statusCode == 410) {
  //         return {'error': 'Stale data'};
  //       } else {
  //         return {'error': 'Failed to fetch sensor data (HTTP ${response.statusCode})'};
  //     }
  //   } catch (e) {
  //     return {'error': 'Server unreachable. Check your connection.'};
  //   }
  // }
   
   // Fetch Sensor Data from firebase
  // Stream<List<Map<String, dynamic>>> getFirebaseECGBatchStream(String patientId) {
  //   final dbRef = FirebaseDatabase.instance.ref("ecg_data/$patientId");

  //   return dbRef.limitToLast(1).onChildAdded.map((DatabaseEvent event) {
  //     final value = event.snapshot.value as Map;
  //     final List ecgList = value['ecg'] as List;

  //     return ecgList.map<Map<String, dynamic>>((item) => {
  //       "value": item["value"],
  //       "timestamp_ms": item["timestamp_ms"]
  //     }).toList();
  //   });
  // }

   // Patient
  static Future<void>fetchAndSavePatientId(String email) async { 
    try {
        final url = Uri.parse("${ApiClient.baseUrl}/get_patient_id?email=$email");
        final response = await http.get(url).timeout(const Duration(seconds: 10)); // ⏳ Increased timeout

        if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data != null && data.containsKey("patient_id")) {
                String patientId = data["patient_id"].toString();
                String role = data["role"].toString();

                if (patientId.isNotEmpty) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString("patient_id", patientId);
                    await prefs.setString("role", role);
                    print("Patient ID saved: $patientId");
                    print("Role saved: $role");
                } else {
                    print("⚠ No patient ID found in response.");
                }
            } else {
                print("⚠ Response does not contain patient_id.");
            }
        } else {
            print("⚠ Failed to fetch patient ID (HTTP ${response.statusCode}).");
        }
    } catch (e) {
        print("⚠ Error fetching patient ID: $e");
    }
  }

  Future<Map<String, dynamic>> registerPatient(
      String fullName, String gender, int age, String email, String password, String contact, double weight) async {

      final url = Uri.parse('${ApiClient.baseUrl}/register/patient');
      final data = {
          'fullname': fullName,
          'gender': gender,
          'age': age,
          'email': email.toLowerCase(),
          'password': password,
          'contact': contact,
          'weight': weight
      };

      try {
          final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
          );

          if (response.statusCode == 201) {
              print("Patient registered successfully! Fetching patient ID...");

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("email", email.toLowerCase());
              // 🔹 Ensure DB commit before fetching patient ID
              await Future.delayed(const Duration(seconds: 1));
              await fetchAndSavePatientId(email.toLowerCase());

              return json.decode(response.body);
          } else if (response.statusCode == 400) {
              return {'error': 'Invalid input data. Please check your details.'};
          } else if (response.statusCode == 500) {
            final responseBody = json.decode(response.body);
            final errorMessage = responseBody['error'] ?? 'Server error. Please try again later.';

            // Check for PostgreSQL duplicate error patterns
            if (errorMessage.contains('duplicate key value') || errorMessage.contains('unique constraint')) {
                return {'error': 'A patient with this email already exists.'};
            }

            return {'error': errorMessage}; // Generic fallback

          } else {
              return {'error': 'Unexpected error: ${response.statusCode}'}; 
          }
      } catch (e) {
          return {'error': 'An error occurred: $e'};
      }
  }

  Future<Map<String, dynamic>> loginPatient(String email, String password) async {
      final url = Uri.parse('$baseUrl/login/patient');
      final data = {'email': email.toLowerCase(), 'password': password};

      try {
          final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
          );

          if (response.statusCode == 200) {
              final responseData = json.decode(response.body);
              
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("email", email.toLowerCase());

              // Fetch and Save patient_id
              await Future.delayed(const Duration(seconds: 1));
              await fetchAndSavePatientId(email.toLowerCase());

              return responseData;
          } else if (response.statusCode == 401) {
              return {'error': 'Invalid email or password.'};
          } else if (response.statusCode == 500) {
              final errorResponse = json.decode(response.body);
              return {'error': errorResponse['error'] ?? 'Server error. Please try again later.'};
          } else {
              return {'error': 'Unexpected error: ${response.statusCode}'}; 
          }
      } catch (e) {
          return {'error': 'An error occurred: $e'};
      }
  }

   // Specialist
  static Future<void> fetchAndSaveSpecialistId(String email) async { 
    try {
        final url = Uri.parse("${ApiClient.baseUrl}/get_specialist_id?email=$email");
        final response = await http.get(url).timeout(const Duration(seconds: 10)); // ⏳ Increased timeout

        if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data != null && data.containsKey("specialist_id")) {
                String specialistId = data["specialist_id"].toString();
                String role = data["role"].toString();

                if (specialistId.isNotEmpty) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString("specialist_id", specialistId);
                    await prefs.setString("role", role);
                    print("Specialist ID saved: $specialistId");
                    print("Role saved: $role");
                } else {
                    print("⚠ No specialist ID found in response.");
                }
            } else {
                print("⚠ Response does not contain specialist_id.");
            }
        } else {
            print("⚠ Failed to fetch specialist ID (HTTP ${response.statusCode}).");
        }
    } catch (e) {
        print("⚠ Error fetching specialist ID: $e");
    }
  }
  
  Future<Map<String, dynamic>> registerSpecialist(
      String fullName, String email, String password, String profession, String speciality) async {
    final url = Uri.parse('$baseUrl/register/specialist');

    final data = {
      'fullname': fullName,
      'email': email.toLowerCase(),
      'password': password,
      'profession': profession,
      'speciality': speciality
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email.toLowerCase());
        // 🔹 Ensure DB commit before fetching specialist ID
        await Future.delayed(const Duration(seconds: 1));
        await fetchAndSaveSpecialistId(email.toLowerCase());

        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        return {'error': 'Invalid input data. Please check your details.'};
      } else if (response.statusCode == 409) {
        return {'error': 'A health specialist with this email already exists.'};
      } else if (response.statusCode == 500) {
          final responseBody = json.decode(response.body);
          final errorMessage = responseBody['error'] ?? 'Server error. Please try again later.';

          // Check for PostgreSQL duplicate error patterns
          if (errorMessage.contains('duplicate key value') || errorMessage.contains('unique constraint')) {
              return {'error': 'A patient with this email already exists.'};
          }

          return {'error': errorMessage}; // Generic fallback
      } else {
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> loginSpecialist(String email, String password) async {
    final url = Uri.parse('$baseUrl/login/specialist');

    final data = {'email': email.toLowerCase(), 'password': password};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email.toLowerCase());

        // Fetch and Save specialist_id
        await Future.delayed(const Duration(seconds: 1));
        await fetchAndSaveSpecialistId(email.toLowerCase());

        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        return {'error': 'Invalid email or password.'};
      } else if (response.statusCode == 500) {
        final errorResponse = json.decode(response.body);
        return {'error': errorResponse['error'] ?? 'Server error. Please try again later.'};
      } else {
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

   // Smartshirt
  Future<Map<String, dynamic>> checkSmartShirt(String macAddress) async {
    final url = Uri.parse('$baseUrl/check_smartshirt?mac_address=$macAddress');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'SmartShirt not found.'};
      }
    } catch (e) {
      return {'error': 'Failed to check SmartShirt: $e'};
    }
  }

  Future<Map<String, dynamic>> registerSmartShirt(String macAddress, String patientId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/register_mac');

    final data = {'mac_address': macAddress, 'patient_id': patientId};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to register MAC Address'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> getSmartShirts(String patientId) async {
    final url = Uri.parse('$baseUrl/get_smartshirts?patient_id=$patientId');

    print("url: $url");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'smartshirts': (data['smartshirts'] as List).map((s) => {
            'smartshirtId': s['smartshirtid'],  
            'deviceMac': s['devicemac'],
            'shirtStatus': s['shirtstatus'],
          }).toList()
        };
      } else {
        final body = json.decode(response.body);
        return {
          'error': body['error'] ?? body['message'] ?? 'No SmartShirts found.',
        };
      }
    } catch (e) {
      return {'error': 'Failed to fetch SmartShirts: $e'};
    }
  }

  Future<bool> deleteSmartShirt(String macAddress) async {
    final url = Uri.parse('$baseUrl/delete_smartshirt');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mac_address': macAddress}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error deleting SmartShirt: $e");
      return false;
    }
  }

  // Simple GET Request Handler (for ESP endpoints like /reset_wifi)
  static Future<int> simpleGetRequest(Uri url) async {
    try {
      final response = await http.get(url);
      return response.statusCode;
    } catch (e) {
      print("❌ Error during GET request: $e");
      return 500;
    }
  }

  // Fetch latest ESP32 MAC + IP address from backend
  Future<Map<String, dynamic>> getLatestMacAndIP({int retries = 3}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Try to use saved IP first
    String? savedIp = prefs.getString("latest_ip");
    String? savedMac = prefs.getString("latest_mac");
    if (savedIp != null && savedMac != null) {
      print("📦 Using cached IP: $savedIp");
      return {"ip_address": savedIp, "mac_address": savedMac};
    }

    final url = Uri.parse('$baseUrl/get_latest_mac_ip');

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await http.get(url);
        print("🔁 GET /get_latest_mac_ip — Code: ${response.statusCode}");
        print("🔁 Response Body: ${response.body}");

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await prefs.setString("latest_ip", data["ip_address"]);
          await prefs.setString("latest_mac", data["mac_address"]);
          return data;
        } else if (response.statusCode == 404) {
          print("⚠️ MAC/IP not ready yet, retrying...");
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          return {'error': 'Unexpected status: ${response.statusCode}'};
        }
      } catch (e) {
        print("❌ Exception during MAC/IP fetch: $e");
        return {'error': 'Failed to contact server: $e'};
      }
    }

    return {'error': 'Max retries exceeded'};
  }

  // Patient Profile
  Future<Map<String, dynamic>> getPatientProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");

    if (patientId == null) {
      print("❌ Patient ID not found in storage.");
      return {'error': 'Patient ID not found in storage'};
    }

    final url = Uri.parse("$baseUrl/get_patient_profile?patient_id=$patientId");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      print("🟢 API Response Code: ${response.statusCode}");
      print("🟢 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to fetch patient profile (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      print("❌ Error in getPatientProfile(): $e");
      return {'error': 'Server unreachable. Check your connection.'};
    }
  }

  Future<Map<String, dynamic>> updatePatientProfile(Map<String, String> updatedData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? patientId = prefs.getString("patient_id");

      if (patientId == null) {
        return {"error": "Patient ID not found in storage"};
      }

      final url = Uri.parse("$baseUrl/update_patient_profile");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "patient_id": patientId,
          "full_name": updatedData["full_name"],
          "gender": updatedData["gender"],
          "age": updatedData["age"],
          "email": updatedData["email"],
          "contact": updatedData["contact"],
          "weight": updatedData["weight"],
        }),
      );

      print("🟢 API Response Code: ${response.statusCode}");
      print("🟢 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"error": "Failed to update profile (HTTP ${response.statusCode})"};
      }
    } catch (e) {
      print("❌ Error in updatePatientProfile(): $e");
      return {"error": "Server unreachable. Check your connection."};
    }
  }

  // Specialist Profile
  Future<Map<String, dynamic>> getSpecialistProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? specialistId = prefs.getString("specialist_id");

    if (specialistId == null) {
      print("❌ Specialist ID not found in storage.");
      return {'error': 'Specialist ID not found in storage'};
    }

    final url = Uri.parse("$baseUrl/get_specialist_profile?specialist_id=$specialistId");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      print("🟢 API Response Code: ${response.statusCode}");
      print("🟢 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to fetch specialist profile (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      print("❌ Error in getSpecialistProfile(): $e");
      return {'error': 'Server unreachable. Check your connection.'};
    }
  }

  Future<Map<String, dynamic>> updateSpecialistProfile(Map<String, String> updatedData) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? specialistId = prefs.getString("specialist_id");

    if (specialistId == null) {
      return {"error": "Specialist ID not found in storage"};
    }

    final url = Uri.parse("$baseUrl/update_specialist_profile");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "specialist_id": specialistId,
        "full_name": updatedData["fullname"],
        "email": updatedData["email"],
        "profession": updatedData["profession"],
        "speciality": updatedData["speciality"],
      }),
    );

    print("🟢 API Response Code: ${response.statusCode}");
    print("🟢 API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {"error": "Failed to update profile (HTTP ${response.statusCode})"};
    }
  } catch (e) {
    print("❌ Error in updateSpecialistProfile(): $e");
    return {"error": "Server unreachable. Check your connection."};
  }
}

  // Trusted Contacts
  Future<List<Map<String, dynamic>>> getTrustedContacts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");

    if (patientId == null) {
      print("⚠ Patient ID is missing!");
      return [];
    }

    final url = Uri.parse("$baseUrl/get_trusted_contacts?patient_id=$patientId");
    
    try {
      final response = await http.get(url);

      print("🟢 API Response Code: ${response.statusCode}");
      print("🟢 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Ensure the response is always treated as a List
        if (data is Map<String, dynamic>) {
          return [data]; // Convert single object to a list
        } else if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          print("⚠ Unexpected response format: $data");
          return [];
        }
      } else {
        print("⚠ Failed to fetch contacts. HTTP ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching trusted contacts: $e");
      return [];
    }
  }

  Future<bool> addTrustedContact(String name, String number) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString("patient_id");

    if (patientId == null) return false;

    final url = Uri.parse("$baseUrl/add_trusted_contact");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patient_id": patientId,
        "contact_name": name,
        "contact_number": number,
      }),
    );

    return response.statusCode == 201;
  }

  Future<bool> updateTrustedContact(int contactId, String name, String number) async {
    final url = Uri.parse("$baseUrl/update_trusted_contact");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contact_id": contactId,
        "contact_name": name,
        "contact_number": number,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteTrustedContact(int contactId) async {
    final url = Uri.parse("$baseUrl/delete_trusted_contact");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"contact_id": contactId}),
    );

    return response.statusCode == 200;
  }

  // Specialist Patients
  static Future<Map<String, dynamic>> addPatientById(String patientShortId) async {
    try {
      // Get specialist_id from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? specialistId = prefs.getString("specialist_id");

      if (specialistId == null || specialistId.isEmpty) {
        return {'error': 'Specialist ID not found. Please login again.'};
      }

      final url = Uri.parse('${ApiClient.baseUrl}/specialist/add_patient');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'specialistid': specialistId,
          'patientid': patientShortId,
        }),
      );

      if (response.statusCode == 201) {
        return {'message': 'Patient successfully added.'};
      } else if (response.statusCode == 404) {
        final resBody = jsonDecode(response.body);
        return {'error': resBody['message'] ?? 'Patient not found.'};
      } else if (response.statusCode == 500) {
        final errorResponse = json.decode(response.body);
        return {'error': errorResponse['error'] ?? 'Server error. Please try again later.'};
      } else {
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSpecialistPatients() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? specialistId = prefs.getString("specialist_id");

      if (specialistId == null || specialistId.isEmpty) {
        throw Exception('Specialist ID not found. Please login again.');
      }

      final url = Uri.parse('${ApiClient.baseUrl}/specialist/patients/$specialistId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['patients']);
      } else {
        throw Exception('Failed to fetch patients: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠ Error fetching patients: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSpecificPatientInsights(String patientId) async {
  final response = await http.get(Uri.parse('$baseUrl/patient_insights/$patientId'));
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {'error': 'Failed to fetch patient insights'};
  }
}

  // Temperature
  Future<Map<String, dynamic>> classifyTemperature(double temperature) async {
    final url = Uri.parse('$baseUrl/classify_temp_status');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"temperature": temperature}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to classify temperature: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getTemperatureTrends(String range, {String? patientId}) async {
    // If patientId not passed, fallback to SharedPreferences
    if (patientId == null) {
      final prefs = await SharedPreferences.getInstance();
      patientId = prefs.getString("patient_id");
    }

    if (patientId == null) {
      print("❌ No patient ID provided");
      return [];
    }

    final url = Uri.parse('$_baseUrl/temperature_trends?patient_id=$patientId&range=$range');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        print("❌ Error fetching temperature trends: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }

    return [];
  }

  // Respiration
  Future<Map<String, dynamic>> classifyRespiration(double respiration) async {
    final url = Uri.parse('$baseUrl/classify_respiration_status');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"respiration": respiration}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to classify respiration: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getRespirationTrends(String range, {String? patientId}) async {
    // If patientId not passed, fallback to SharedPreferences
    if (patientId == null) {
      final prefs = await SharedPreferences.getInstance();
      patientId = prefs.getString("patient_id");
    }

    if (patientId == null) {
      print("❌ No patient ID provided");
      return [];
    }

    final url = Uri.parse('$_baseUrl/respiration_trends?patient_id=$patientId&range=$range');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        print("Error fetching respiration trends: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }

    return [];
  }

}
