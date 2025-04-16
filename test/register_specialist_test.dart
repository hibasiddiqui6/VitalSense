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
    // Passing test cases
    test('Full name is valid', () {
      expect(isValidFullName("Dr John Doe"), true); // ✅ Pass
    });

    test('Profession is selected', () {
      expect(isValidProfession("Doctor"), true); // ✅ Pass
    });

    test('Speciality is selected', () {
      expect(isValidSpeciality("Cardiology"), true); // ✅ Pass
    });

    test('Email format is valid', () {
      expect(isValidEmail("johndoe@gmail.com"), true); // ✅ Pass
    });

    test('Password is valid', () {
      expect(isValidPassword("StrongPass@123"), true); // ✅ Pass
    });

    // Failing test cases

    // Full name has a number, so it fails the regex
    test('Full name is invalid (contains number)', () {
      expect(isValidFullName("Dr John123 Doe"), true); // ❌ Fails because the name contains numbers
    });

    // Profession is empty, so it fails
    test('Profession is not selected (should fail)', () {
      expect(isValidProfession(""), true); // ❌ Fails because profession is empty
    });

    // Email is missing '@', so it fails
    test('Email format is invalid (missing @)', () {
      expect(isValidEmail("johndoegmail.com"), true); // ❌ Fails because email is missing '@'
    });

    // Password doesn't have an uppercase letter, so it fails
    test('Password is invalid (missing uppercase)', () {
      expect(isValidPassword("strongpass@123"), true); // ❌ Fails because the password is missing an uppercase letter
    });
  });
}
