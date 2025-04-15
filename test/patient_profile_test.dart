import 'package:flutter_test/flutter_test.dart';

class PatientProfileValidator {
  static bool isValidGender(String gender) {
    return gender == 'Male' || gender == 'Female' || gender == 'Other';
  }

  static bool isValidAge(int age) {
    return age > 0 && age < 120;
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidContact(String contact) {
    final phoneRegex = RegExp(r'^\d{3}-\d{3}-\d{4}$');
    return phoneRegex.hasMatch(contact);
  }

  static bool isValidWeight(String weight) {
    final weightVal = double.tryParse(weight);
    return weightVal != null && weightVal > 0 && weightVal < 300;
  }

  static bool isValidPatientId(int id) {
    return id > 0;
  }
}

void main() {
  group('PatientProfileValidator Tests', () {
    // ✅ Test 1: Valid gender
    test('Valid gender should return true', () {
      expect(PatientProfileValidator.isValidGender('Male'), true);
    });

    // ❌ Test 2: Invalid gender (INTENTIONAL FAIL)
    test('Invalid gender should return false', () {
      expect(PatientProfileValidator.isValidGender('Alien'), true); // Should be false
    });

    // ✅ Test 3: Valid email
    test('Valid email should return true', () {
      expect(PatientProfileValidator.isValidEmail('user@example.com'), true);
    });

    // ❌ Test 4: Invalid email (INTENTIONAL FAIL)
    test('Invalid email should return false', () {
      expect(PatientProfileValidator.isValidEmail('userexample.com'), true); // Should be false
    });

    // ✅ Test 5: Valid contact format
    test('Valid contact should return true', () {
      expect(PatientProfileValidator.isValidContact('123-456-7890'), true);
    });

    // ✅ Test 6: Valid weight
    test('Valid weight should return true', () {
      expect(PatientProfileValidator.isValidWeight('75'), true);
    });
  });
}
