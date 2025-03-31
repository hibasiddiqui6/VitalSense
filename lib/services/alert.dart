import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> notifyTrustedContacts(String alertStatus, List<Map<String, dynamic>> contacts) async {
  try {
    final Location location = Location();

    // 1. Check if location services are enabled
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print("📵 Location services are turned off.");
        return;
      }
    }

    // 2. Check permissions
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    // 3. Abort if not granted
    if (permissionGranted != PermissionStatus.granted) {
      print("❌ Location permission denied.");
      return;
    }

    // 4. Get location
    LocationData position = await location.getLocation();

    String locationUrl = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
    String message = Uri.encodeComponent(
      "⚠️ Health Alert: $alertStatus detected.\n"
      "Patient’s location: $locationUrl"
    );

    // 5. Format contact list
    for (var contact in contacts) {
    final Uri smsUri = Uri.parse("sms:${contact['contactnumber']}?body=$message");

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print("❌ Could not launch SMS app for ${contact['contactnumber']}");
    }
    }

  } catch (e) {
    print("❌ Failed to notify contacts: $e");
  }
}
