import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_model.dart';
import '../models/guardian_model.dart';
import 'mail_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _smsChannel =
      MethodChannel('com.example.safestep2/sms');

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

  /// Formats compact emergency SMS tailored for carrier text delivery limits
  static Future<String> formatCompactSmsMessage({
    required EmergencyModel emergency,
    required GuardianModel guardian,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final myName = prefs.getString('my_name') ?? 'User';
    final myPhone = prefs.getString('my_phone') ?? '';

    final buffer = StringBuffer();
    buffer.write("EMERGENCY SOS - SAFESTEP!\n");
    buffer.write("From: $myName${myPhone.isNotEmpty ? ' ($myPhone)' : ''}\n");
    final cleanAddress = emergency.address.replaceAll('\n', ' ');
    final shortAddress = cleanAddress.length > 45 ? '${cleanAddress.substring(0, 42)}...' : cleanAddress;
    buffer.write("Loc: $shortAddress\n");
    buffer.write("Map: ${emergency.googleMapsUrl}\n");

    if (emergency.publicVideoUrl != null &&
        emergency.publicVideoUrl!.isNotEmpty) {
      buffer.write("Video: ${emergency.publicVideoUrl}");
    } else {
      buffer.write("Video: Saved on device");
    }

    return buffer.toString();
  }

  /// Dispatch alert based on method ('whatsapp', 'sms', 'email', 'share')
  Future<bool> sendGuardianNotification({
    required EmergencyModel emergency,
    required GuardianModel guardian,
    required String method,
  }) async {
    final fullMessage =
        await formatEmergencyMessage(emergency: emergency, guardian: guardian);

    // Clean phone number (removes spaces, dashes, keeping + and digits)
    final cleanPhone = guardian.mobileNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final cleanEmail = guardian.email.trim();

    try {
      switch (method.toLowerCase()) {
        case 'sms':
          // Compact SMS for carrier delivery limits
          final smsMessage = await formatCompactSmsMessage(
            emergency: emergency,
            guardian: guardian,
          );
          return await _sendSmsAutomatically(cleanPhone, smsMessage);

        case 'whatsapp':
          return await _sendWhatsAppDirect(cleanPhone, fullMessage);

        case 'email':
          return await MailService().sendMailtoLauncher(
            cleanEmail,
            "EMERGENCY SOS ALERT - SafeStep",
            fullMessage,
          );

        case 'share':
        default:
          return await _sendShareSheet(fullMessage);
      }
    } catch (e) {
      debugPrint("NotificationService Error: $e");
      return await _sendShareSheet(fullMessage);
    }
  }

  // 1. Silent Background SMS Dispatch via Native Android SmsManager
  Future<bool> _sendSmsAutomatically(String phone, String message) async {
    try {
      // Check & request SMS permission explicitly before sending
      var smsPermission = await Permission.sms.status;
      if (!smsPermission.isGranted) {
        smsPermission = await Permission.sms.request();
      }

      if (smsPermission.isGranted) {
        final bool? success = await _smsChannel.invokeMethod<bool>('sendSms', {
          'phone': phone,
          'message': message,
        });

        if (success == true) {
          debugPrint("Native Background SMS dispatched successfully via SmsManager!");
          return true;
        } else {
          debugPrint("Native SMS failed. Falling back to direct SMS launcher.");
          return await _sendSmsDirectFallback(phone, message);
        }
      } else {
        debugPrint("SMS permission denied by user. Falling back to direct SMS launcher.");
        return await _sendSmsDirectFallback(phone, message);
      }
    } catch (e) {
      debugPrint("Native Background SMS Error: $e. Falling back to direct SMS launcher.");
      return await _sendSmsDirectFallback(phone, message);
    }
  }

  // Fallback SMS launcher if background transmission fails or permission is denied
  Future<bool> _sendSmsDirectFallback(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse("sms:$phone?body=$encoded");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  // 2. Direct WhatsApp Intent
  Future<bool> _sendWhatsAppDirect(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse("whatsapp://send?phone=$phone&text=$encoded");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }

    final fallbackUri =
        Uri.parse("https://api.whatsapp.com/send?phone=$phone&text=$encoded");
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }

  // 3. Fallback Native Share Sheet
  Future<bool> _sendShareSheet(String text) async {
    final result =
        await Share.share(text, subject: "EMERGENCY SOS ALERT - SafeStep");
    return result.status == ShareResultStatus.success;
  }
}

