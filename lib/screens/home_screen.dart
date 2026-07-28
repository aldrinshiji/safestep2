import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_sms/background_sms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isHandlingEmergency = false;
  String _statusText = "System Active";

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
    _shakeService.startListening(onShake: _handleEmergencyTrigger);
  }

  Future<void> _requestAllPermissions() async {
    await [
      Permission.sms,
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
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

  // Record 10-second background video, save to gallery, and upload to Firebase
  Future<String?> _recordAndUploadEmergencyVideo() async {
    try {
      // 1. Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      // Select back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final CameraController cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await cameraController.initialize();

      // Start recording
      await cameraController.startVideoRecording();

      // Keep recording for 10 seconds
      await Future.delayed(const Duration(seconds: 10));

      // Stop recording and get file
      XFile videoFile = await cameraController.stopVideoRecording();
      await cameraController.dispose();

      File file = File(videoFile.path);

      // 2. Save a copy directly to the phone's Gallery
      try {
        await Gal.putVideo(file.path);
        debugPrint("Video saved to gallery successfully.");
      } catch (e) {
        debugPrint("Error saving to gallery: $e");
      }

      // 3. Upload to Firebase Storage
      setState(() {
        _statusText = "Uploading emergency evidence...";
      });

      String fileName =
          "sos_video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      Reference storageRef =
          FirebaseStorage.instance.ref().child("emergency_videos/$fileName");

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint("Error in video recording/upload process: $e");
      return null;
    }
  }

  Future<void> _handleEmergencyTrigger() async {
    if (_isHandlingEmergency) return;

    setState(() {
      _isHandlingEmergency = true;
      _statusText = "EMERGENCY TRIGGERED!";
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
    }

    // Record video, save to gallery, and upload to Firebase
    setState(() {
      _statusText = "Recording 10s emergency video...";
    });
    String? videoUrl = await _recordAndUploadEmergencyVideo();

    if (!mounted) return;

    // Fetch settings
    Map<String, String> settings = await _getSettings();
    String emergencyContact = settings['contact']!;
    String alertMode = settings['mode']!;

    String messageText =
        "EMERGENCY! I need help. Location: $addressText ($coordsText).";
    if (videoUrl != null) {
      messageText += " Watch 10s emergency video footage here: $videoUrl";
    }

    if (alertMode == 'sms') {
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
                    ? "Emergency SMS & Video link sent!"
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

    setState(() {
      _isHandlingEmergency = false;
      _statusText = "System Active";
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            size: 50, color: Colors.red),
        title: const Text("SOS DISPATCHED!"),
        content: Text(
            "10s video recorded, saved to gallery, uploaded to cloud, and sent via ${alertMode.toUpperCase()} to $emergencyContact."),
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
            Text(
              _statusText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Shake device or tap below to record 10s video, save to gallery, and alert guardian.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            if (_isHandlingEmergency)
              const CircularProgressIndicator(color: Colors.red)
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
