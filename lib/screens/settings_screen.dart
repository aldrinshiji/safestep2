import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/guardian_model.dart';
import '../models/settings_model.dart';
import '../repositories/emergency_repository.dart';
import '../services/supabase_service.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({super.key, this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmergencyRepository _repository = EmergencyRepository();
  final SupabaseService _supabaseService = SupabaseService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  SettingsModel _settings = const SettingsModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    final guardian = await _repository.loadGuardian();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _nameController.text = guardian.name;
      _emailController.text = guardian.email;
      _mobileController.text = guardian.mobileNumber;

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
      _isLoading = false;
    });
  }

  Future<void> _saveAllSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final guardian = GuardianModel(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
    );

    await _repository.saveGuardian(guardian);
    await _supabaseService.saveGuardianInfo(guardian);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyVideoDuration, _settings.videoDuration);
    await prefs.setBool(AppConstants.keyEnableShake, _settings.enableShake);
    await prefs.setBool(AppConstants.keyEnableVolume, _settings.enableVolume);
    await prefs.setBool(AppConstants.keyAutoUpload, _settings.autoUpload);
    await prefs.setBool(AppConstants.keySaveToGallery, _settings.saveToGallery);
    await prefs.setBool(AppConstants.keyDarkMode, _settings.darkMode);
    await prefs.setString(AppConstants.keyLanguage, _settings.language);
    await prefs.setBool(AppConstants.keyEnableCountdown, _settings.enableCountdown);
    await prefs.setString(AppConstants.keyAlertMethod, _settings.alertMethod);

    widget.onSettingsChanged?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Guardian & Emergency Settings saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.security_rounded),
            tooltip: "Permissions",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Guardian Information", Icons.person_rounded),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "Guardian Full Name",
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? "Please enter guardian name" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: "Guardian Email",
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? "Please enter guardian email" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Guardian Mobile Number",
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? "Please enter mobile number" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Emergency Settings", Icons.bolt_rounded),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              value: _settings.videoDuration,
                              decoration: const InputDecoration(
                                labelText: "Evidence Video Duration",
                                prefixIcon: Icon(Icons.videocam_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 10, child: Text("10 Seconds")),
                                DropdownMenuItem(value: 20, child: Text("20 Seconds")),
                                DropdownMenuItem(value: 30, child: Text("30 Seconds")),
                                DropdownMenuItem(value: 60, child: Text("60 Seconds")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _settings = _settings.copyWith(videoDuration: val);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _settings.alertMethod,
                              decoration: const InputDecoration(
                                labelText: "Preferred Alert Dispatch Method",
                                prefixIcon: Icon(Icons.send_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp Direct Alert')),
                                DropdownMenuItem(value: 'sms', child: Text('SMS Message')),
                                DropdownMenuItem(value: 'email', child: Text('Email Alert')),
                                DropdownMenuItem(value: 'share', child: Text('Android Native Share Sheet')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _settings = _settings.copyWith(alertMethod: val);
                                  });
                                }
                              },
                            ),
                            const Divider(height: 24),
                            SwitchListTile(
                              title: const Text("Enable Shake Detection"),
                              subtitle: const Text("Trigger SOS by shaking phone"),
                              value: _settings.enableShake,
                              onChanged: (val) =>
                                  setState(() => _settings = _settings.copyWith(enableShake: val)),
                            ),
                            SwitchListTile(
                              title: const Text("Volume Down Button Trigger"),
                              subtitle: const Text("Hold Volume Down for 3 seconds"),
                              value: _settings.enableVolume,
                              onChanged: (val) =>
                                  setState(() => _settings = _settings.copyWith(enableVolume: val)),
                            ),
                            SwitchListTile(
                              title: const Text("Emergency Countdown"),
                              subtitle: const Text("3-second cancelable countdown"),
                              value: _settings.enableCountdown,
                              onChanged: (val) => setState(
                                  () => _settings = _settings.copyWith(enableCountdown: val)),
                            ),
                            SwitchListTile(
                              title: const Text("Auto Upload to Cloud"),
                              subtitle: const Text("Upload evidence to Supabase Storage"),
                              value: _settings.autoUpload,
                              onChanged: (val) =>
                                  setState(() => _settings = _settings.copyWith(autoUpload: val)),
                            ),
                            SwitchListTile(
                              title: const Text("Save to Device Gallery"),
                              subtitle: const Text("Save evidence video locally in Gallery"),
                              value: _settings.saveToGallery,
                              onChanged: (val) => setState(
                                  () => _settings = _settings.copyWith(saveToGallery: val)),
                            ),
                            SwitchListTile(
                              title: const Text("Dark Theme Mode"),
                              value: _settings.darkMode,
                              onChanged: (val) =>
                                  setState(() => _settings = _settings.copyWith(darkMode: val)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: AppTheme.primaryOrange.withOpacity(0.15),
                      leading: const Icon(Icons.security_rounded, color: AppTheme.primaryOrange),
                      title: const Text("Permissions Management", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Check & grant system permissions"),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PermissionsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saveAllSettings,
                        icon: const Icon(Icons.save_rounded, color: Colors.white),
                        label: const Text(
                          "SAVE ALL SETTINGS",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
