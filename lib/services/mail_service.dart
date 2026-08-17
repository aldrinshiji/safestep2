import 'package:url_launcher/url_launcher.dart';

class MailService {
  static final MailService _instance = MailService._internal();
  factory MailService() => _instance;
  MailService._internal();

  /// Direct mailto launcher for 1-tap pre-filled emergency email dispatch
  Future<bool> sendMailtoLauncher(
      String email, String subject, String body) async {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final uri =
        Uri.parse("mailto:$email?subject=$encodedSubject&body=$encodedBody");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
