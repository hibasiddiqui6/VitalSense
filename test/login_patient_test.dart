import 'package:flutter_test/flutter_test.dart';

bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

void main() {
  group('Email Validation Tests', () {
    test('Valid email: user@example.com', () {
      expect(isValidEmail('user@example.com'), true);
    });

    test('Invalid email: userexample.com (missing @)', () {
      expect(isValidEmail('userexample.com'), false);
    });

    test('Invalid email: user@domain.c (domain too short)', () {
      // ❌ Intentionally wrong expected value
      expect(isValidEmail('user@domain.c'), true); // This will fail
    });
  });

  group('Password Validation Tests', () {
    test('Valid password: 123456', () {
      expect(isValidPassword('123456'), true);
    });

    test('Invalid password: abc (too short)', () {
      expect(isValidPassword('abc'), false);
    });

    test('Invalid password: 12345 (too short)', () {
      // ❌ Intentionally wrong expected value
      expect(isValidPassword('12345'), true); // This will fail
    });
  });

  group('Combined Email & Password Tests', () {
    test('Valid email and password', () {
      expect(isValidEmail('user@example.com') && isValidPassword('123456'), true);
    });

    test('Invalid email and valid password', () {
      // ❌ Intentionally wrong expected value
      expect(isValidEmail('userexample.com') && isValidPassword('123456'), true); // This will fail
    });
  });
}
