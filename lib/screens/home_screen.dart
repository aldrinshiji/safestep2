import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_sms/background_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/shake_service.dart';
import '../services/location_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();
  final LocationService _locationService = LocationService();
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _shakeService.startListening(onShake: _handleEmergencyTrigger);
  }

  Future<void> _requestPermissions() async {
    await Permission.sms.request();
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    super.dispose();
  }

  Future<Map<String, String>> _getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'contact': prefs.getString('emergency_contact') ?? "+919876543210",
      'mode': prefs.getString('alert_mode') ?? 'whatsapp',
    };
  }

  Future<void> _handleEmergencyTrigger() async {
    setState(() {
      _isFetchingLocation = true;
    });

    String addressText = "Fetching location...";
    String coordsText = "";

    try {
      Map<String, String> locationData =
          await _locationService.getCurrentLocationAddress();
      addressText = locationData["address"] ?? "Unknown Area";
      coordsText = "Lat: ${locationData["lat"]}, Long: ${locationData["lng"]}";
    } catch (e) {
      addressText = "Error getting location";
      coordsText = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }

    if (!mounted) return;

    // Fetch settings
    Map<String, String> settings = await _getSettings();
    String emergencyContact = settings['contact']!;
    String alertMode = settings['mode']!;

    String messageText =
        "EMERGENCY! I need help. My current location is: $addressText ($coordsText). Please track me!";

    if (alertMode == 'sms') {
      // Send Automated Background SMS using BackgroundSms
      try {
        SmsStatus result = await BackgroundSms.sendMessage(
          phoneNumber: emergencyContact,
          message: messageText,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == SmsStatus.sent
                    ? "Emergency SMS sent automatically!"
                    : "Failed to send automatic SMS.",
              ),
              backgroundColor:
                  result == SmsStatus.sent ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (error) {
        debugPrint("Error sending background SMS: $error");
      }
    } else {
      // Open WhatsApp Automatically
      String formattedNumber =
          emergencyContact.replaceAll(RegExp(r'[^0-9]'), '');
      String encodedMessage = Uri.encodeComponent(messageText);
      final Uri whatsappUri =
          Uri.parse("https://wa.me/$formattedNumber?text=$encodedMessage");

      try {
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint("Could not launch WhatsApp");
        }
      } catch (error) {
        debugPrint("Error launching WhatsApp: $error");
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            size: 50, color: Colors.red),
        title: const Text("SOS TRIGGERED!"),
        content: Text(
            "Emergency alert dispatched via ${alertMode.toUpperCase()} to $emergencyContact."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeStep 2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "System Active",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Shake your device to trigger an emergency SOS alert.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            if (_isFetchingLocation)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _handleEmergencyTrigger,
                icon: const Icon(Icons.sos, color: Colors.white),
                label: const Text("TEST SOS TRIGGER",
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
