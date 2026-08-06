import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety & Help Center"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            const Text(
              "Emergency Helpline Hotlines",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHelplineTile(
              "Women Helpline (India)",
              AppConstants.helplineWomen,
              "24x7 Dedicated Women Safety Helpline",
              Icons.phone_in_talk_rounded,
            ),
            _buildHelplineTile(
              "National Emergency Number",
              AppConstants.helplineNational,
              "All-in-one Emergency Services (Police, Ambulance, Fire)",
              Icons.local_police_rounded,
            ),
            const SizedBox(height: 24),
            const Text(
              "SafeStep Emergency Triggers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildGuideTile(
              "1. Press SOS Button",
              "Tap the central SOS button on the home screen. A 3-second countdown will start before recording video & notifying your guardian.",
              Icons.touch_app_rounded,
            ),
            _buildGuideTile(
              "2. Shake Device",
              "In urgent situations where opening the app is difficult, vigorously shake your smartphone to instantly activate emergency recording.",
              Icons.vibration_rounded,
            ),
            _buildGuideTile(
              "3. Hold Volume Down Key",
              "Press and hold the Volume Down button for 3 seconds continuously to dispatch SOS silently.",
              Icons.volume_down_rounded,
            ),
            _buildGuideTile(
              "4. Automatic Evidence & Local Storage",
              "The app records video + audio, captures your precise GPS location, saves the file to your device Gallery, uploads to Supabase, and shares your live link.",
              Icons.cloud_upload_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.primaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
      String title, String number, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
          child: Icon(icon, color: AppTheme.primaryRed),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$number • $subtitle", style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.call_rounded, color: Colors.green),
          onPressed: () => _makeCall(number),
        ),
      ),
    );
  }

  Widget _buildGuideTile(String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
