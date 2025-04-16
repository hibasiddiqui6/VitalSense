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
  return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 8 &&
      !password.contains(' ') && // no spaces allowed
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
    test('✅ Full name is valid', () {
      expect(isValidFullName("Dr John Doe"), true);
    });

    test('✅ Profession is selected', () {
      expect(isValidProfession("Doctor"), true);
    });

    test('✅ Speciality is selected', () {
      expect(isValidSpeciality("Cardiology"), true);
    });

    test('❌ Invalid email format: missing @', () {
      expect(isValidEmail("johndoe.com"), true); // ❌ Should be false – Failing test
    });

    test('❌ Invalid password: too short', () {
      expect(isValidPassword("Abc@1"), true); // ❌ Should be false – Failing test
    });

    test('✅ Valid email format', () {
      expect(isValidEmail("john@doe.com"), true);
    });

    test('❌ Invalid email format: short domain', () {
      expect(isValidEmail("john@doe.c"), false); // Correctly fails
    });

    test('❌ Invalid password: missing uppercase', () {
      expect(isValidPassword("password@123"), false);
    });

    test('❌ Invalid password: contains space', () {
      expect(isValidPassword("Pass word@123"), false);
    });

    test('✅ Valid password: StrongPass@123', () {
      expect(isValidPassword("StrongPass@123"), true);
    });

    test('✅ Passwords match', () {
      expect(doPasswordsMatch("StrongPass@123", "StrongPass@123"), true);
    });

    test('❌ Passwords do not match', () {
      expect(doPasswordsMatch("StrongPass@123", "WrongPass@123"), false);
    });
  });
}
