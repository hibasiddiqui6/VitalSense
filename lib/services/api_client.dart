import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  /// **Base URL based on Platform (Android, Emulator, iOS, Web)**
  static final String _baseUrl = Platform.isAndroid
      ? "http://192.168.0.188:5000" // For Real Android Device
      : Platform.isIOS
          ? "http://127.0.0.1:5000" // For iOS Simulator
          : "http://localhost:5000"; // For Web Debugging (Chrome)

  /// **Get Base URL**
  static String get baseUrl => _baseUrl;

  /// **Fetch Sensor Data**
  Future<Map<String, dynamic>> getSensorData() async {
    final url = Uri.parse('$baseUrl/get_sensor');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Failed to fetch sensor data (HTTP ${response.statusCode})'};
      }
    } catch (e) {
      return {'error': 'Server unreachable. Check your connection.'};
    }
  }

  static Future<void> fetchAndSavePatientId(String email) async { 
    try {
        final url = Uri.parse("${ApiClient.baseUrl}/get_patient_id?email=$email");
        final response = await http.get(url).timeout(const Duration(seconds: 10)); // ⏳ Increased timeout

        if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data != null && data.containsKey("patient_id")) {
                String patientId = data["patient_id"].toString();

                if (patientId.isNotEmpty) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString("patient_id", patientId);
                    print("✅ Patient ID saved: $patientId");
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
      String fullName, String gender, int age, String email, String password, String contact) async {

      final url = Uri.parse('${ApiClient.baseUrl}/register/patient');
      final data = {
          'FullName': fullName,
          'Gender': gender,
          'Age': age,
          'Email': email,
          'Password': password,
          'Contact': contact
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
              await prefs.setString("email", email);
              // 🔹 **Ensure DB commit before fetching patient ID**
              await Future.delayed(const Duration(seconds: 1));
              await fetchAndSavePatientId(email);

              return json.decode(response.body);
          } else if (response.statusCode == 400) {
              return {'error': 'Invalid input data. Please check your details.'};
          } else if (response.statusCode == 500) {
              final responseBody = json.decode(response.body);
              if (responseBody['error'] != null && responseBody['error'].contains('Duplicate entry')) {
                  return {'error': 'A patient with this email already exists.'};
              }
              return {'error': 'Server error. Please try again later.'};
          } else {
              return {'error': 'Unexpected error: ${response.statusCode}'}; 
          }
      } catch (e) {
          return {'error': 'An error occurred: $e'};
      }
  }

  /// **Login a Patient**
  Future<Map<String, dynamic>> loginPatient(String email, String password) async {
      final url = Uri.parse('$baseUrl/login/patient');
      final data = {'Email': email, 'Password': password};

      try {
          final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
          );

          if (response.statusCode == 200) {
              final responseData = json.decode(response.body);
              
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("email", email);

              // **Fetch and Save patient_id**
              await Future.delayed(const Duration(seconds: 1));
              await fetchAndSavePatientId(email);

              return responseData;
          } else if (response.statusCode == 401) {
              return {'error': 'Invalid email or password.'};
          } else if (response.statusCode == 500) {
              return {'error': 'Server error. Please try again later.'};
          } else {
              return {'error': 'Unexpected error: ${response.statusCode}'}; 
          }
      } catch (e) {
          return {'error': 'An error occurred: $e'};
      }
  }

  /// **Register a Specialist**
  Future<Map<String, dynamic>> registerSpecialist(
      String fullName, String email, String password, String profession, String speciality) async {
    final url = Uri.parse('$baseUrl/register/specialist');

    final data = {
      'FullName': fullName,
      'Email': email,
      'Password': password,
      'Profession': profession,
      'Speciality': speciality
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        return {'error': 'Invalid input data. Please check your details.'};
      } else if (response.statusCode == 409) {
        return {'error': 'A health specialist with this email already exists.'};
      } else if (response.statusCode == 500) {
        final responseBody = json.decode(response.body);
        if (responseBody['error'] != null && responseBody['error'].contains('Duplicate entry')) {
          return {'error': 'A Specialist with this email already exists.'};
        }
        return {'error': 'Server error. Please try again later.'};
      } else {
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  /// **Login a Specialist**
  Future<Map<String, dynamic>> loginSpecialist(String email, String password) async {
    final url = Uri.parse('$baseUrl/login/specialist');

    final data = {'Email': email, 'Password': password};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        return {'error': 'Invalid email or password.'};
      } else if (response.statusCode == 500) {
        return {'error': 'Server error. Please try again later.'};
      } else {
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  /// **Check if SmartShirt is Registered**
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

  /// **Register SmartShirt for a Patient**
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

  /// **Fetch SmartShirts Linked to a Patient**
  Future<Map<String, dynamic>> getSmartShirts(String patientId) async {
    final url = Uri.parse('$baseUrl/get_smartshirts?patient_id=$patientId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'No SmartShirts found for this patient.'};
      }
    } catch (e) {
      return {'error': 'Failed to fetch SmartShirts: $e'};
    }
  }

}