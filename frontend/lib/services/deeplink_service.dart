import 'package:url_launcher/url_launcher.dart';

class DeeplinkService {
  static Future<bool> openUrl(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return false;
    final Uri? uri = Uri.tryParse(urlString.trim());
    if (uri == null) return false;

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openMapDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    return openUrl(url);
  }
}
