import 'package:flutter_test/flutter_test.dart';

bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 8;
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
      // ❌ Intentionally failing
      expect(isValidEmail('user@domain.c'), true); // Should be false
    });

    test('Invalid email: @example.com (missing username)', () {
      expect(isValidEmail('@example.com'), false);
    });
  });

  group('Password Validation Tests', () {
    test('Valid password: abcdef', () {
      expect(isValidPassword('abcdef'), true);
    });

    test('Invalid password: abc (too short)', () {
      expect(isValidPassword('abc'), false);
    });

    test('Invalid password: empty string', () {
      // ❌ Intentionally failing
      expect(isValidPassword(''), true); // Should be false
    });

    test('Valid password: pass word (space included)', () {
      expect(isValidPassword('pass word'), true);
    });
  });

  group('Combined Email & Password Tests', () {
    test('Valid email and password', () {
      expect(isValidEmail('user@example.com') && isValidPassword('abcdef'), true);
    });

    test('Invalid email and valid password', () {
      // ❌ Intentionally failing
      expect(isValidEmail('userexample.com') && isValidPassword('abcdef'), true); // Should be false
    });

    test('Valid email and invalid password', () {
      expect(isValidEmail('user@example.com') && isValidPassword('123'), false);
    });
  });
}
