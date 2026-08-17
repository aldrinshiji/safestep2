import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/device_utils.dart';
import '../models/emergency_model.dart';
import '../models/guardian_model.dart';
import '../models/settings_model.dart';
import '../repositories/emergency_repository.dart';
import '../services/camera_service.dart';
import '../services/gallery_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/offline_sync_service.dart';
import '../services/shake_service.dart';
import '../services/supabase_service.dart';
import '../services/volume_service.dart';
import '../widgets/emergency_countdown_dialog.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_card.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'permissions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();
  final VolumeService _volumeService = VolumeService();
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();
  final GalleryService _galleryService = GalleryService();
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final EmergencyRepository _repository = EmergencyRepository();

  bool _isHandlingEmergency = false;
  bool _isSafe = true;

  // Real-time Status Indicators
  bool _gpsReady = false;
  bool _cameraReady = false;
  bool _micReady = false;
  bool _internetReady = false;

  SettingsModel _settings = const SettingsModel();
  GuardianModel _guardian = GuardianModel.empty;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkSystemStatus();
    await _loadLocalSettings();

    // Start background listeners
    if (_settings.enableShake) {
      _shakeService.startListening(onShake: _triggerSOSFlow);
    }

    if (_settings.enableVolume) {
      _volumeService.startListening(onTrigger: _triggerSOSFlow);
    }

    _offlineSyncService.initConnectivityListener();
  }

  Future<void> _checkSystemStatus() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    final locationStatus = await Permission.location.status;
    final internet = await DeviceUtils.isInternetAvailable();

    if (mounted) {
      setState(() {
        _cameraReady = cameraStatus.isGranted;
        _micReady = micStatus.isGranted;
        _gpsReady = locationStatus.isGranted;
        _internetReady = internet;
      });
    }
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final guardian = await _repository.loadGuardian();

    if (mounted) {
      setState(() {
        _guardian = guardian;
        _settings = SettingsModel(
          videoDuration: prefs.getInt(AppConstants.keyVideoDuration) ?? 10,
          enableShake: prefs.getBool(AppConstants.keyEnableShake) ?? true,
          enableVolume: prefs.getBool(AppConstants.keyEnableVolume) ?? true,
          autoUpload: prefs.getBool(AppConstants.keyAutoUpload) ?? true,
          saveToGallery: prefs.getBool(AppConstants.keySaveToGallery) ?? true,
          darkMode: prefs.getBool(AppConstants.keyDarkMode) ?? false,
          language: prefs.getString(AppConstants.keyLanguage) ?? 'English',
          enableCountdown: prefs.getBool(AppConstants.keyEnableCountdown) ?? true,
          alertMethod: prefs.getString(AppConstants.keyAlertMethod) ?? 'whatsapp',
        );
      });
    }
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    _volumeService.stopListening();
    super.dispose();
  }

  /// Entry point when SOS button, shake, or volume button triggers
  void _onSOSPressed() {
    if (_isHandlingEmergency) return;

    if (_settings.enableCountdown) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => EmergencyCountdownDialog(
          onCountdownComplete: _executeEmergencyProcess,
          onCancel: () {
            debugPrint("SOS Trigger Canceled by user.");
          },
        ),
      );
    } else {
      _executeEmergencyProcess();
    }
  }

  void _triggerSOSFlow() {
    if (!_isHandlingEmergency) {
      _onSOSPressed();
    }
  }

  /// Core Emergency Execution Workflow
  Future<void> _executeEmergencyProcess() async {
    if (_isHandlingEmergency) return;

    setState(() {
      _isHandlingEmergency = true;
      _isSafe = false;
    });

    final String emergencyId = DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime timestamp = DateTime.now();
    final int batteryLevel = await DeviceUtils.getBatteryLevel();
    final String deviceModel = await DeviceUtils.getDeviceModel();
    final bool isOnline = await DeviceUtils.isInternetAvailable();
    final String internetStatusStr = isOnline ? "Online" : "Offline";

    // 1. Fetch GPS Location
    double lat = 0.0;
    double lng = 0.0;
    String address = "Fetching location...";
    String googleMapsUrl = "";

    try {
      final locData = await _locationService.getCurrentLocationAddress();
      address = locData["address"] ?? "Unknown Location";
      lat = double.tryParse(locData["lat"] ?? "0") ?? 0.0;
      lng = double.tryParse(locData["lng"] ?? "0") ?? 0.0;
      googleMapsUrl = DeviceUtils.buildGoogleMapsUrl(lat, lng);
    } catch (e) {
      address = "GPS Location Unavailable";
      googleMapsUrl = "https://maps.google.com";
    }

    // 2. Record Video & Audio Evidence
    File? videoFile = await _cameraService.recordVideo(
      durationSeconds: _settings.videoDuration,
    );

    // 3. Save Video to Local Device Gallery
    if (videoFile != null && _settings.saveToGallery) {
      await _galleryService.saveVideoToGallery(videoFile.path);
    }

    // 4. Upload to Supabase Storage if Online & Enabled
    String? publicVideoUrl;
    String uploadStatus = 'pending';

    if (videoFile != null && isOnline && _settings.autoUpload) {
      final fileName = "sos_$emergencyId.mp4";
      publicVideoUrl = await _supabaseService.uploadEmergencyVideo(
        videoFile,
        fileName,
      );
      uploadStatus = publicVideoUrl != null ? 'uploaded' : 'failed';
    }

    // 5. Construct Emergency Model
    var emergency = EmergencyModel(
      id: emergencyId,
      timestamp: timestamp,
      localVideoPath: videoFile?.path,
      publicVideoUrl: publicVideoUrl,
      latitude: lat,
      longitude: lng,
      address: address,
      googleMapsUrl: googleMapsUrl,
      deviceModel: deviceModel,
      batteryPercentage: batteryLevel,
      internetStatus: internetStatusStr,
      uploadStatus: uploadStatus,
      guardianStatus: 'sent',
    );

    // 6. Save Emergency to Local History Repository
    await _repository.saveEmergencyLog(emergency);

    // 7. Save to Supabase DB or Queue Offline
    bool alertDispatched = false;
    if (isOnline) {
      await _supabaseService.saveEmergencyRecord(
        emergency: emergency,
        guardian: _guardian,
      );
      alertDispatched = await _notificationService.sendGuardianNotification(
        emergency: emergency,
        guardian: _guardian,
        method: _settings.alertMethod,
      );
    } else {
      // Queue offline for automatic sync when network is restored
      await _offlineSyncService.queueEmergencyLocally(
        emergency: emergency,
        guardian: _guardian,
      );
      // Attempt local SMS or share sheet fallback
      alertDispatched = await _notificationService.sendGuardianNotification(
        emergency: emergency,
        guardian: _guardian,
        method: _settings.alertMethod == 'sms' ? 'sms' : 'share',
      );
    }

    if (!mounted) return;

    setState(() {
      _isHandlingEmergency = false;
      _isSafe = true;
    });

    _showSOSDispatchedDialog(emergency, alertDispatched);
  }

  void _showSOSDispatchedDialog(EmergencyModel emergency, bool alertDispatched) {
    String methodDetail = "";
    switch (_settings.alertMethod.toLowerCase()) {
      case 'sms':
        methodDetail = alertDispatched
            ? "Automatic SMS sent silently to guardian!"
            : "SMS app opened with pre-filled alert.";
        break;
      case 'email':
        methodDetail = alertDispatched
            ? "Automatic Background Email dispatched to guardian!"
            : "Mail app opened with pre-filled alert.";
        break;
      case 'whatsapp':
        methodDetail = "WhatsApp launched with pre-filled emergency message (1-Tap Send).";
        break;
      case 'share':
      default:
        methodDetail = "Native share sheet opened for dispatch.";
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded, size: 50, color: Colors.green),
        title: const Text("EMERGENCY DISPATCHED"),
        content: Text(
          "Evidence recorded & saved to Gallery.\nGuardian: ${_guardian.name} (${_guardian.mobileNumber})\n\nAlert Status: $methodDetail",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          _volumeService.handleKeyDown(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _volumeService.handleKeyUp(event.logicalKey);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppTheme.primaryRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "SafeStep",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: "Safety Help",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                // Top Status Card
                StatusCard(
                  isSafe: _isSafe,
                  gpsReady: _gpsReady,
                  cameraReady: _cameraReady,
                  micReady: _micReady,
                  internetReady: _internetReady,
                  onTapPermissions: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PermissionsScreen()),
                    );
                    _checkSystemStatus();
                  },
                ),
                const Spacer(),
                // Center SOS Button
                SOSButton(
                  onTap: _onSOSPressed,
                  isRecording: _isHandlingEmergency,
                ),
                const SizedBox(height: 20),
                Text(
                  _isHandlingEmergency
                      ? "Recording Evidence & Dispatching SOS..."
                      : "Shake Phone • Hold Vol Down 3s • Tap SOS",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isHandlingEmergency ? AppTheme.primaryRed : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                // Bottom Shortcuts Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomShortcut(
                        icon: Icons.person_pin_rounded,
                        label: "Guardian",
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                onSettingsChanged: _loadLocalSettings,
                              ),
                            ),
                          );
                          _loadLocalSettings();
                        },
                      ),
                      _buildBottomShortcut(
                        icon: Icons.history_rounded,
                        label: "History",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildBottomShortcut(
                        icon: Icons.settings_rounded,
                        label: "Settings",
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                onSettingsChanged: _loadLocalSettings,
                              ),
                            ),
                          );
                          _loadLocalSettings();
                        },
                      ),
                      _buildBottomShortcut(
                        icon: Icons.health_and_safety_rounded,
                        label: "Help",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomShortcut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryRed, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}