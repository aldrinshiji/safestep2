import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;
  String _themePreset = 'cyber_dark';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final permissions = [
      Permission.sms,
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    for (var perm in permissions) {
      statuses[perm] = await perm.status;
    }

    setState(() {
      _permissionStatuses = statuses;
      _themePreset = prefs.getString(AppConstants.keyThemePreset) ?? 'cyber_dark';
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission perm) async {
    final status = await perm.request();
    setState(() {
      _permissionStatuses[perm] = status;
    });
  }

  Future<void> _requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();

    setState(() {
      _permissionStatuses = statuses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(_themePreset);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Permissions Status"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "SafeStep requires system permissions to capture emergency evidence and notify your guardian.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  _buildPermissionTile(
                    "Automatic SMS Dispatch",
                    "Required for sending direct background emergency SMS without tapping send",
                    Icons.textsms_rounded,
                    Permission.sms,
                    colors,
                  ),
                  _buildPermissionTile(
                    "Camera Access",
                    "Required for emergency video recording",
                    Icons.videocam_rounded,
                    Permission.camera,
                    colors,
                  ),
                  _buildPermissionTile(
                    "Microphone Access",
                    "Required for recording emergency audio",
                    Icons.mic_rounded,
                    Permission.microphone,
                    colors,
                  ),
                  _buildPermissionTile(
                    "GPS Location Access",
                    "Required for capturing live coordinates & Google Maps link",
                    Icons.location_on_rounded,
                    Permission.location,
                    colors,
                  ),
                  _buildPermissionTile(
                    "Storage / Photos & Videos",
                    "Required for saving evidence locally in Gallery",
                    Icons.photo_library_rounded,
                    Permission.photos,
                    colors,
                  ),
                  _buildPermissionTile(
                    "Notifications",
                    "Required for background service alerts & emergency status",
                    Icons.notifications_active_rounded,
                    Permission.notification,
                    colors,
                  ),
                  _buildPermissionTile(
                    "Battery Optimization Bypass",
                    "Ensures emergency triggers operate continuously in background",
                    Icons.battery_saver_rounded,
                    Permission.ignoreBatteryOptimizations,
                    colors,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _requestAllPermissions,
                      icon: const Icon(Icons.verified_user_rounded, color: Colors.white),
                      label: const Text(
                        "GRANT ALL PERMISSIONS",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionTile(
      String title, String subtitle, IconData icon, Permission perm, SafeStepThemeColors colors) {
    final status = _permissionStatuses[perm] ?? PermissionStatus.denied;
    final isGranted = status.isGranted;

    return Card(
      color: colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.cardBorder),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isGranted ? colors.safeGreen : colors.accentCyan).withOpacity(0.15),
          child: Icon(icon, color: isGranted ? colors.safeGreen : colors.accentCyan),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        trailing: isGranted
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.safeGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.safeGreen.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: colors.safeGreen, size: 14),
                    const SizedBox(width: 4),
                    Text("Granted", style: TextStyle(color: colors.safeGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _requestPermission(perm),
                child: const Text("Request", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }
}
