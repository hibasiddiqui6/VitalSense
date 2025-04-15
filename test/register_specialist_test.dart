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

    test('Confirm password matches', () {
      expect(doPasswordsMatch("StrongPass@123", "StrongPass@123"), true); // ✅ Pass
    });

    test('Profession is not selected (should fail)', () {
      expect(isValidProfession(""), true); // ❌ Fails because it's actually false
    });

    test('Password mismatch (should fail)', () {
      expect(doPasswordsMatch("StrongPass@123", "WrongPass@123"), true); // ❌ Fails because they don't match
    });
  });
}
