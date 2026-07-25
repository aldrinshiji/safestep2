import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _primaryEmailController = TextEditingController();
  final TextEditingController _secondaryEmailController = TextEditingController();

  bool _shakeDetectionEnabled = true;
  bool _volumeTriggerEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _primaryEmailController.text = prefs.getString('primary_email') ?? '';
      _secondaryEmailController.text = prefs.getString('secondary_email') ?? '';
      _shakeDetectionEnabled = prefs.getBool('shake_enabled') ?? true;
      _volumeTriggerEnabled = prefs.getBool('volume_enabled') ?? true;
    });
  }

  // Save updated preferences
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('primary_email', _primaryEmailController.text.trim());
    await prefs.setString('secondary_email', _secondaryEmailController.text.trim());
    await prefs.setBool('shake_enabled', _shakeDetectionEnabled);
    await prefs.setBool('volume_enabled', _volumeTriggerEnabled);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _primaryEmailController.dispose();
    _secondaryEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings & Guardians"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Guardian Contacts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "SOS alerts, live location, and recorded video evidence will be emailed here.",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Primary Email
              TextField(
                controller: _primaryEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Primary Guardian Email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Email
              TextField(
                controller: _secondaryEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Secondary Guardian Email (Optional)",
                  prefixIcon: Icon(Icons.mark_email_read_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const Divider(height: 40),

              const Text(
                "Emergency Triggers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Shake Switch
              SwitchListTile(
                title: const Text("Shake Detection"),
                subtitle: const Text("Trigger SOS by shaking phone hard"),
                value: _shakeDetectionEnabled,
                onChanged: (val) => setState(() => _shakeDetectionEnabled = val),
              ),

              // Volume Press Switch
              SwitchListTile(
                title: const Text("Volume Button Hold"),
                subtitle: const Text("Trigger SOS by holding volume button for 3 seconds"),
                value: _volumeTriggerEnabled,
                onChanged: (val) => setState(() => _volumeTriggerEnabled = val),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "SAVING..." : "SAVE SETTINGS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}