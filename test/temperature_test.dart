import 'package:flutter_test/flutter_test.dart';

class TemperatureService {
  Future<Map<String, dynamic>> getSensorData() async {
    await Future.delayed(Duration(milliseconds: 50));
    return {"temperature": 99.0};
  }

  Future<Map<String, dynamic>> classifyTemperature(double temp) async {
    await Future.delayed(Duration(milliseconds: 50));
    if (temp >= 100.4) {
      return {"status": "Fever", "disease": "High Fever"};
    } else if (temp < 95) {
      return {"status": "Hypothermia", "disease": "Severe Hypothermia"};
    } else {
      return {"status": "Normal", "disease": ""};
    }
  }
}

void main() {
  group('Temperature Logic Tests', () {
    final service = TemperatureService();

    test('Returns correct temperature from sensor (PASS)', () async {
      final data = await service.getSensorData();
      expect(data["temperature"], 99.0);
    });

    test('Classifies normal temperature correctly (PASS)', () async {
      final result = await service.classifyTemperature(98.6);
      expect(result["status"], "Normal");
      expect(result["disease"], "");
    });

    test('Classifies fever temperature correctly (PASS)', () async {
      final result = await service.classifyTemperature(101.0);
      expect(result["status"], "Fever");
      expect(result["disease"], "High Fever");
    });

    test('Classifies low temperature correctly (PASS)', () async {
      final result = await service.classifyTemperature(94.0);
      expect(result["status"], "Hypothermia");
      expect(result["disease"], "Severe Hypothermia");
    });

    test('Fails intentionally - Incorrect expectation (FAIL)', () async {
      final result = await service.classifyTemperature(98.6);
      expect(result["status"], "Fever"); // This will fail
    });
  });
}
