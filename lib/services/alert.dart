import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> notifyContacts(String alertStatus, List<Map<String, dynamic>> contacts) async {
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

    // 2. Check location permissions
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    // 3. Abort if location permission not granted
    if (permissionGranted != PermissionStatus.granted) {
      print("❌ Location permission denied.");
      return;
    }

    // 4. Get current location
    LocationData position = await location.getLocation();
    String locationUrl = "https://maps.google.com/?q=${position.latitude},${position.longitude}";

    // 5. Build the message
    String message = Uri.encodeComponent(
      "⚠️ Health Alert: $alertStatus detected.\n"
      "Patient’s location: $locationUrl"
    );

    // 6. Combine contact numbers
    String contactNumbers = contacts.map((c) => c['contactnumber']).join(',');

    // 7. Create SMS URI
    final Uri smsUri = Uri.parse("sms:$contactNumbers?body=$message");

    // 8. Launch SMS app
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print("❌ Could not launch SMS app");
    }

  } catch (e) {
    print("❌ Failed to notify contacts: $e");
  }
}
