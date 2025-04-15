import 'package:flutter_test/flutter_test.dart';

bool isValidFullName(String fullName) {
  return fullName.isNotEmpty && RegExp(r"^[a-zA-Z\s]+$").hasMatch(fullName);
}

bool isValidProfession(String? profession) {
  return profession != null && profession.isNotEmpty;
}

bool isValidSpeciality(String? speciality) {
  return speciality != null && speciality.isNotEmpty;
}

bool isValidEmail(String email) {
  return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[!@#\$&*~_]').hasMatch(password);
}

bool doPasswordsMatch(String password, String confirmPassword) {
  return password == confirmPassword;
}

void main() {
  group('Logical Validation Tests', () {
    test('Full name is valid', () {
      expect(isValidFullName("Dr John Doe"), true);
    });

    test('Profession is selected', () {
      expect(isValidProfession("Doctor"), true);
    });

    test('Speciality is selected', () {
      expect(isValidSpeciality("Cardiology"), true);
    });

    test('Email format is valid', () {
      // ❌ Intentionally failing this test
      expect(isValidEmail("johndoe.com"), true); // should be false
    });

    test('Password is valid', () {
      // ❌ Intentionally failing this test
      expect(isValidPassword("weakpass"), true); // should be false
    });

    test('Confirm password matches', () {
      expect(doPasswordsMatch("StrongPass@123", "StrongPass@123"), true);
    });
  });
}
