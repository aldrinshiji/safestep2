import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_model.dart';
import '../models/guardian_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Formats complete emergency alert message using user's personal details
  static Future<String> formatEmergencyMessage({
    required EmergencyModel emergency,
    required GuardianModel guardian,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve YOUR personal details from SharedPreferences
    final myName = prefs.getString('my_name') ?? 'User';
    final myPhone = prefs.getString('my_phone') ?? 'N/A';
    final myEmail = prefs.getString('my_email') ?? 'N/A';

    final buffer = StringBuffer();
    buffer.writeln("🚨 EMERGENCY ALERT - SAFESTEP 🚨");
    buffer.writeln("Emergency ID: ${emergency.id}");
    buffer.writeln("Time: ${emergency.timestamp.toString().substring(0, 19)}");
    buffer.writeln("\n--- My Details ---");
    buffer.writeln("Name: $myName");
    buffer.writeln("Mobile: $myPhone");
    buffer.writeln("Email: $myEmail");
    buffer.writeln("\n--- Location & Device ---");
    buffer.writeln("Location: ${emergency.address}");
    buffer.writeln(
        "Coordinates: Lat ${emergency.latitude}, Lng ${emergency.longitude}");
    buffer.writeln("Google Maps Link: ${emergency.googleMapsUrl}");
    buffer.writeln("Device Model: ${emergency.deviceModel}");
    buffer.writeln("Battery Level: ${emergency.batteryPercentage}%");

    if (emergency.publicVideoUrl != null &&
        emergency.publicVideoUrl!.isNotEmpty) {
      buffer.writeln("🎥 Emergency Video Link: ${emergency.publicVideoUrl}");
    } else {
      buffer.writeln("🎥 Emergency Video: Recorded locally on device.");
    }

    return buffer.toString();
  }

  /// Dispatch alert based on method ('whatsapp', 'sms', 'email', 'share')
  Future<bool> sendGuardianNotification({
    required EmergencyModel emergency,
    required GuardianModel guardian,
    required String method,
  }) async {
    final message =
        await formatEmergencyMessage(emergency: emergency, guardian: guardian);
    final cleanPhone = guardian.mobileNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    try {
      switch (method.toLowerCase()) {
        case 'whatsapp':
          return await _sendWhatsApp(cleanPhone, message);

        case 'sms':
          return await _sendSMS(cleanPhone, message);

        case 'email':
          return await _sendEmail(
              guardian.email, "EMERGENCY SOS ALERT - SafeStep", message);

        case 'share':
        default:
          return await _sendShareSheet(message);
      }
    } catch (e) {
      debugPrint("NotificationService Error: $e");
      // Fallback to native share sheet
      return await _sendShareSheet(message);
    }
  }

  Future<bool> _sendWhatsApp(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse("https://wa.me/$phone?text=$encoded");
    if (await canLaunchUrl(whatsappUri)) {
      return await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
    return await _sendShareSheet(message);
  }

  Future<bool> _sendSMS(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final smsUri = Uri.parse("sms:$phone?body=$encoded");
    if (await canLaunchUrl(smsUri)) {
      return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    }
    return await _sendShareSheet(message);
  }

  Future<bool> _sendEmail(String email, String subject, String body) async {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final mailUri =
        Uri.parse("mailto:$email?subject=$encodedSubject&body=$encodedBody");
    if (await canLaunchUrl(mailUri)) {
      return await launchUrl(mailUri, mode: LaunchMode.externalApplication);
    }
    return await _sendShareSheet(body);
  }

  Future<bool> _sendShareSheet(String text) async {
    final result =
        await Share.share(text, subject: "EMERGENCY SOS ALERT - SafeStep");
    return result.status == ShareResultStatus.success;
  }
}
