import 'package:url_launcher/url_launcher.dart';

Future<void> openMap(String place) async {
  final query = Uri.encodeComponent(place);
  final url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> startNavigation(String place) async {
  final query = Uri.encodeComponent(place);
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$query',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
