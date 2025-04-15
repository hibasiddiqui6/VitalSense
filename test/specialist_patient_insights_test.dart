import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsense/Modules/specialist_patient_insights.dart';
import 'package:mockito/mockito.dart';
import 'mock_api_client.dart';

void main() {
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  testWidgets('displays patient data correctly', (WidgetTester tester) async {
    // Arrange: Mock data returned from ApiClient
    when(mockApiClient.getSpecificPatientInsights("any")).thenAnswer(
      (_) async => {
        'fullname': 'Test Patient',
        'respiration_rate': 16,
        'temperature': 98.6,
        'gender': 'Female',
        'age': 30,
        'weight': 55,
        'last_updated': DateTime.now().toIso8601String(),
      },
    );

    when(mockApiClient.getSpecialistProfile()).thenAnswer(
      (_) async => {
        'email': 'test@doc.com',
        'fullname': 'Dr. Smith',
      },
    );

    // Act: Pump the widget
    await tester.pumpWidget(
      MaterialApp(
        home: PatientInsightsScreen(patientId: '123'),
      ),
    );

    // Wait for async operations
    await tester.pumpAndSettle();

    // Assert: Check if patient data is shown
    expect(find.text('Test Patient'), findsOneWidget);
    expect(find.text('16 BPM'), findsOneWidget);
    expect(find.text('98.6 °F'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('55'), findsOneWidget);
  });
}
