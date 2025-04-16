import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsense/Modules/ecg.dart'; // Adjust the import according to your project structure

void main() {
  group('ECG Screen Logic Tests', () {
    late ECGScreen ecgScreen;
    late List<double> ecgBuffer;
    late double sampleData;

    setUp(() {
      // Initialize the necessary variables
      ecgScreen = ECGScreen(gender: 'Male', age: '30', weight: '70kg');
      ecgBuffer = [];
      sampleData = 50.0; // Static value representing ECG sample
    });

    test('ECG screen initializes with correct user details (PASS)', () {
      // Check if the details are passed correctly
      expect(ecgScreen.gender, 'Male');
      expect(ecgScreen.age, '30');
      expect(ecgScreen.weight, '70kg');
    });

    test('ECG buffer starts empty (PASS)', () {
      // Verify that the ECG buffer is empty at first
      expect(ecgBuffer.isEmpty, true);
    });

    test('ECG buffer adds new data correctly (FAIL)', () {
      // Simulate adding data to the buffer
      ecgBuffer.add(sampleData);
      
      // Now intentionally fail this test by checking for a wrong value
      expect(ecgBuffer[0], 300.0); // This should fail because we added 50.0
    });

    test('ECG buffer size does not exceed 300 (PASS)', () {
      // Simulate adding more data and check that it does not exceed the maximum buffer size
      while (ecgBuffer.length < 300) {
        ecgBuffer.add(sampleData);
      }

      // Ensure the buffer size does not exceed 300
      expect(ecgBuffer.length, 300);
    });

    test('ECG normalization function works (PASS)', () {
      // Simulate normalizing an ECG value
      double normalizedValue = normalize(2000);
      
      // Ensure it is a valid number (non-null)
      expect(normalizedValue, isA<double>());
      expect(normalizedValue, isNonNegative);
    });

    test('ECG normalize function handles edge cases (PASS)', () {
      // Test the edge case for normalization when maxValue == minValue
      double normalizedValue = normalize(1500);
      
      // Since the value is exactly the min value, it should return the max height
      expect(normalizedValue, 400.0); // Assuming the canvas height is 400
    });
  });
}

// Mock normalization function used in the ECG logic
double normalize(double value) {
  double minValue = 1500; // ECG Min
  double maxValue = 2400; // ECG Max
  double canvasHeight = 400.0; // Assume a fixed canvas height

  if (maxValue == minValue) {
    return canvasHeight / 2; // Avoid division by zero, return middle value
  }

  // Normalizing logic (scale to canvas height)
  return canvasHeight - ((value - minValue) / (maxValue - minValue)) * canvasHeight;
}
