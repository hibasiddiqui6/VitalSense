// File: test/patient_trends_logic_test.dart

import 'package:flutter_test/flutter_test.dart';

class UserDetails {
  final String fullName;
  final String email;
  final String role;

  UserDetails({required this.fullName, required this.email, required this.role});
}

class PatientLogic {
  static UserDetails loadUserDetails(Map<String, String?> prefs) {
    return UserDetails(
      fullName: prefs['full_name'] ?? 'Unknown User',
      email: prefs['email'] ?? 'example@example.com',
      role: prefs['role'] ?? '-',
    );
  }

  static bool isValidNavigationTarget(String buttonLabel) {
    return [
      "ECG Trends / History",
      "Respiration Trends / History",
      "Temperature Trends / History"
    ].contains(buttonLabel);
  }

  static bool isValidEmail(String email) {
    return email.contains("@") && email.contains(".");
  }

  static bool isValidRole(String role) {
    return role == "patient" || role == "specialist";
  }

  static bool isValidButtonColor(int colorHex) {
    return colorHex == 0xFF5A9155; // Expected green color
  }
}

void main() {
  group('PatientTrends Logic Tests (4 Pass, 2 Fail)', () {
    
    // ✅ PASS
    test('Loads correct user details from preferences', () {
      final prefs = {
        'full_name': 'Rubaisha',
        'email': 'rubaisha@gmail.com',
        'role': 'patient',
      };
      final user = PatientLogic.loadUserDetails(prefs);
      expect(user.fullName, 'Rubaisha');
      expect(user.email, 'rubaisha@gmail.com');
      expect(user.role, 'patient');
    });

    // ✅ PASS
    test('Validates ECG label as a valid navigation target', () {
      expect(PatientLogic.isValidNavigationTarget("ECG Trends / History"), true);
    });

    // ✅ PASS
    test('Validates correct button color', () {
      expect(PatientLogic.isValidButtonColor(0xFF5A9155), true);
    });

    // ✅ PASS
    test('Checks valid email format', () {
      expect(PatientLogic.isValidEmail("user@example.com"), true);
    });

    // ❌ FAIL: label not allowed
    test('Fails on an invalid navigation target', () {
      expect(PatientLogic.isValidNavigationTarget("Heart History"), true); // Will fail
    });

    // ❌ FAIL: role not allowed
    test('Fails on unsupported role', () {
      expect(PatientLogic.isValidRole("admin"), true); // Will fail
    });
  });
}
