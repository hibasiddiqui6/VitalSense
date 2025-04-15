// File: test/report_logic_test.dart

import 'package:flutter_test/flutter_test.dart';

// Simulated logic file
class ReportLogic {
  // Simulate patient report generation
  static String generateReportTitle(int index) {
    return "#PID-${index + 1} (Patient Name) Report";
  }

  // Simulate search filter logic
  static List<String> searchReports(String query, List<String> reports) {
    return reports.where((report) => report.toLowerCase().contains(query.toLowerCase())).toList();
  }

  // Check if report ID is valid (starts with #PID- and a number)
  static bool isValidReportId(String title) {
    final regex = RegExp(r"#PID-\d+");
    return regex.hasMatch(title);
  }
}

void main() {
  group('ReportLogic Tests', () {
    test('generateReportTitle returns correct format', () {
      expect(ReportLogic.generateReportTitle(0), "#PID-1 (Patient Name) Report");
      expect(ReportLogic.generateReportTitle(3), "#PID-4 (Patient Name) Report");
    });

    test('isValidReportId returns true for valid IDs', () {
      expect(ReportLogic.isValidReportId("#PID-10 (Patient Name) Report"), true);
      expect(ReportLogic.isValidReportId("#PID-1 Something else"), true);
    });

    test('isValidReportId returns false for invalid IDs', () {
      expect(ReportLogic.isValidReportId("Patient Name Report"), false); // ❌ Fail
      expect(ReportLogic.isValidReportId("#pid-5 report"), false);       // ❌ Fail
    });

    test('searchReports filters correctly', () {
      List<String> reports = [
        "#PID-1 (Ali) Report",
        "#PID-2 (Sara) Report",
        "#PID-3 (Zain) Report"
      ];
      expect(ReportLogic.searchReports("Ali", reports).length, 1);
      expect(ReportLogic.searchReports("report", reports).length, 3);
      expect(ReportLogic.searchReports("xyz", reports).length, 1); // ❌ Fail (expected 0 but giving 1 to fail)
    });

    test('searchReports is case insensitive', () {
      List<String> reports = ["#PID-4 (Ahmed) Report"];
      expect(ReportLogic.searchReports("ahmed", reports).length, 1);
    });

    test('generateReportTitle handles high indexes', () {
      expect(ReportLogic.generateReportTitle(99), "#PID-100 (Patient Name) Report");
    });
  });
}
