import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'http://localhost:5000'; // Use localhost as it's the same machine

  // Function to register a patient
  Future<Map<String, dynamic>> registerPatient(String fullName, String gender, int age, String email, String password, String contact) async {
    final url = Uri.parse('$_baseUrl/register/patient');
    
    // Prepare the data to be sent in the request
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
        body: json.encode(data), // Encode data to JSON format
      );

      // Handle different status codes
      if (response.statusCode == 201) {
        // Successful registration
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        // Bad request, e.g., validation errors
        return {'error': 'Invalid input data. Please check your details.'};
      } else if (response.statusCode == 409) {
        // Conflict, e.g., duplicate email or data
        return {'error': 'A patient with this email already exists.'};
      } else if (response.statusCode == 500) {
        // Server error
        return {'error': 'Server error. Please try again later.'};
      } else {
        // Unexpected status code
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  // Function to login a patient
  Future<Map<String, dynamic>> loginPatient(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login/patient');
    
    // Prepare the data to be sent in the request
    final data = {
      'Email': email,
      'Password': password
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data), // Encode data to JSON format
      );

      // Handle different status codes
      if (response.statusCode == 200) {
        // Successful login
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Unauthorized, e.g., incorrect credentials
        return {'error': 'Invalid email or password.'};
      } else if (response.statusCode == 500) {
        // Server error
        return {'error': 'Server error. Please try again later.'};
      } else {
        // Unexpected status code
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  // Function to register a health specialist
  Future<Map<String, dynamic>> registerSpecialist(String fullName, String email, String password, String profession, String speciality) async {
    final url = Uri.parse('$_baseUrl/register/specialist');
    
    // Prepare the data to be sent in the request
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
        body: json.encode(data), // Encode data to JSON format
      );

      // Handle different status codes
      if (response.statusCode == 201) {
        // Successful registration
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        // Bad request, e.g., validation errors
        return {'error': 'Invalid input data. Please check your details.'};
      } else if (response.statusCode == 409) {
        // Conflict, e.g., duplicate email or data
        return {'error': 'A health specialist with this email already exists.'};
      } else if (response.statusCode == 500) {
        // Server error
        return {'error': 'Server error. Please try again later.'};
      } else {
        // Unexpected status code
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }

  // Function to login a health specialist
  Future<Map<String, dynamic>> loginSpecialist(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login/specialist');
    
    // Prepare the data to be sent in the request
    final data = {
      'Email': email,
      'Password': password
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data), // Encode data to JSON format
      );

      // Handle different status codes
      if (response.statusCode == 200) {
        // Successful login
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Unauthorized, e.g., incorrect credentials
        return {'error': 'Invalid email or password.'};
      } else if (response.statusCode == 500) {
        // Server error
        return {'error': 'Server error. Please try again later.'};
      } else {
        // Unexpected status code
        return {'error': 'Unexpected error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'An error occurred: $e'};
    }
  }
}
