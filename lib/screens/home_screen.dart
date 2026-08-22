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
import '../widgets/quick_action_cards.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_card.dart';
import '../widgets/trigger_instruction_bar.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'permissions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

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

  int _selectedTabIndex = 0;
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
          darkMode: prefs.getBool(AppConstants.keyDarkMode) ?? true,
          themePreset: prefs.getString(AppConstants.keyThemePreset) ?? 'cyber_dark',
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
          themePreset: _settings.themePreset,
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

    final colors = AppTheme.getColors(_settings.themePreset);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.check_circle_rounded, size: 54, color: Colors.green),
        title: Text(
          "EMERGENCY DISPATCHED",
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Evidence recorded & saved to Gallery.\nGuardian: ${_guardian.name} (${_guardian.mobileNumber})\n\nAlert Status: $methodDetail",
          style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: colors.primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(_settings.themePreset);

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
        backgroundColor: colors.background,
        body: SafeArea(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildHomeDashboard(colors),
              const HistoryScreen(),
              SettingsScreen(
                onSettingsChanged: () {
                  _loadLocalSettings();
                  widget.onThemeChanged?.call();
                },
                initialSection: 'guardian',
              ),
              SettingsScreen(
                onSettingsChanged: () {
                  _loadLocalSettings();
                  widget.onThemeChanged?.call();
                },
              ),
              const HelpScreen(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavbar(colors),
      ),
    );
  }

  Widget _buildHomeDashboard(SafeStepThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
      child: Column(
        children: [
          // 1. Status Card & Header Logo
          StatusCard(
            isSafe: _isSafe,
            gpsReady: _gpsReady,
            cameraReady: _cameraReady,
            micReady: _micReady,
            internetReady: _internetReady,
            themePreset: _settings.themePreset,
            onTapPermissions: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionsScreen()),
              );
              _checkSystemStatus();
            },
          ),
          const SizedBox(height: 16),

          // 2. Quick Feature Action Cards (Live Video, Voice, Live Location)
          QuickActionCards(
            themePreset: _settings.themePreset,
            onLiveVideoTap: _onSOSPressed,
            onVoiceRecorderTap: _onSOSPressed,
            onLiveLocationTap: () async {
              await _checkSystemStatus();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: colors.accentCyan,
                    content: Text(
                      _gpsReady
                          ? "GPS Ready! Live location tracking active."
                          : "Please grant GPS location permission.",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                );
              }
            },
          ),

          const Spacer(),

          // 3. Central Multi-Ring SOS Orb Button
          SOSButton(
            onTap: _onSOSPressed,
            isRecording: _isHandlingEmergency,
            themePreset: _settings.themePreset,
          ),

          const Spacer(),

          // 4. Trigger Instruction Bar
          TriggerInstructionBar(themePreset: _settings.themePreset),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBottomNavbar(SafeStepThemeColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.navBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, "Home", colors),
          _buildNavItem(1, Icons.access_time_rounded, "History", colors),
          _buildNavItem(2, Icons.supervisor_account_rounded, "Guardian", colors),
          _buildNavItem(3, Icons.settings_outlined, "Settings", colors),
          _buildNavItem(4, Icons.help_outline_rounded, "Help", colors),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, SafeStepThemeColors colors) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active Tab Indicator Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 3,
              width: isSelected ? 22 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colors.primaryRed,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primaryRed,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
            Icon(
              icon,
              color: isSelected ? colors.primaryRed : colors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}