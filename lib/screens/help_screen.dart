import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _themePreset = 'cyber_dark';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themePreset = prefs.getString(AppConstants.keyThemePreset) ?? 'cyber_dark';
    });
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(_themePreset);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text("Safety & Help Center"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(colors),
            const SizedBox(height: 24),
            Text(
              "Emergency Helpline Hotlines",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildHelplineTile(
              "Women Helpline (India)",
              AppConstants.helplineWomen,
              "24x7 Dedicated Women Safety Helpline",
              Icons.phone_in_talk_rounded,
              colors,
            ),
            _buildHelplineTile(
              "National Emergency Number",
              AppConstants.helplineNational,
              "All-in-one Emergency Services (Police, Ambulance, Fire)",
              Icons.local_police_rounded,
              colors,
            ),
            const SizedBox(height: 24),
            Text(
              "SafeStep Emergency Triggers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildGuideTile(
              "1. Press SOS Button",
              "Tap the central SOS button on the home screen. A 3-second countdown will start before recording video & notifying your guardian.",
              Icons.touch_app_rounded,
              colors,
            ),
            _buildGuideTile(
              "2. Shake Device",
              "In urgent situations where opening the app is difficult, vigorously shake your smartphone to instantly activate emergency recording.",
              Icons.vibration_rounded,
              colors,
            ),
            _buildGuideTile(
              "3. Hold Volume Down Key",
              "Press and hold the Volume Down button for 3 seconds continuously to dispatch SOS silently.",
              Icons.volume_down_rounded,
              colors,
            ),
            _buildGuideTile(
              "4. Automatic Evidence & Local Storage",
              "The app records video + audio, captures your precise GPS location, saves the file to your device Gallery, uploads to Supabase, and shares your live link.",
              Icons.cloud_upload_rounded,
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(SafeStepThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryRed, colors.accentPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primaryRed.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.health_and_safety_rounded, size: 50, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Safety is Priority",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "SafeStep continuously monitors and secures your evidence during critical emergencies.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineTile(
      String title, String number, String subtitle, IconData icon, SafeStepThemeColors colors) {
    return Card(
      color: colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.cardBorder),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryRed.withOpacity(0.15),
          child: Icon(icon, color: colors.primaryRed),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
        subtitle: Text("$number • $subtitle", style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        trailing: IconButton(
          icon: Icon(Icons.call_rounded, color: colors.safeGreen),
          onPressed: () => _makeCall(number),
        ),
      ),
    );
  }

  Widget _buildGuideTile(String title, String description, IconData icon, SafeStepThemeColors colors) {
    return Card(
      color: colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.cardBorder),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.accentPurple, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
