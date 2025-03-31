// ignore: library_prefixes
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

Future<void> initializeTimeZone() async {
  if (!_initialized) {
    tzData.initializeTimeZones();
    _initialized = true;
  }
}

DateTime toPKT(DateTime utcTime) {
  final karachi = tz.getLocation('Asia/Karachi');
  return tz.TZDateTime.from(utcTime.toUtc(), karachi);
}
