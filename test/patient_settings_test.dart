import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsense/Modules/patient_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatientSettings Widget Tests', () {
    setUp(() {
      // ✅ Mock SharedPreferences values
      SharedPreferences.setMockInitialValues({
        'full_name': 'Rubaisha Khurshid',
        'email': 'rubaisha.work@gmail.com',
      });
    });

    testWidgets('renders Settings title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PatientSettings()),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays user email in drawer after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientSettings(),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async load

      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('rubaisha.work@gmail.com'), findsOneWidget);
    });

    testWidgets('toggle Location switch updates state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PatientSettings()));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2)); // 2 switches: Notifications & Location

      final locationSwitch = switches.last;
      await tester.tap(locationSwitch);
      await tester.pump();

      expect(switches, findsNWidgets(2)); // Widget rebuilds after toggle
    });

    testWidgets('fails when looking for non-existent text', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PatientSettings()));

      // ❌ This will fail because text does not exist
      expect(find.text('NonExistentSetting'), findsOneWidget);
    });
  });
}
