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
  final String? initialSection;

  const SettingsScreen({
    super.key,
    this.onSettingsChanged,
    this.initialSection,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmergencyRepository _repository = EmergencyRepository();
  final SupabaseService _supabaseService = SupabaseService();
  final ScrollController _scrollController = ScrollController();

  // User Details Controllers
  final TextEditingController _myNameController = TextEditingController();
  final TextEditingController _myEmailController = TextEditingController();
  final TextEditingController _myMobileController = TextEditingController();

  // Guardian Details Controllers
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianEmailController = TextEditingController();
  final TextEditingController _guardianMobileController = TextEditingController();

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
      // Load User Details
      _myNameController.text = prefs.getString('my_name') ?? '';
      _myEmailController.text = prefs.getString('my_email') ?? '';
      _myMobileController.text = prefs.getString('my_phone') ?? '';

      // Load Guardian Details
      _guardianNameController.text = guardian.name;
      _guardianEmailController.text = guardian.email;
      _guardianMobileController.text = guardian.mobileNumber;

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
      _isLoading = false;
    });

    if (widget.initialSection == 'guardian') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          180,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _saveAllSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    // Save User Details
    await prefs.setString('my_name', _myNameController.text.trim());
    await prefs.setString('my_email', _myEmailController.text.trim());
    await prefs.setString('my_phone', _myMobileController.text.trim());

    // Save Guardian Details
    final guardian = GuardianModel(
      name: _guardianNameController.text.trim(),
      email: _guardianEmailController.text.trim(),
      mobileNumber: _guardianMobileController.text.trim(),
    );

    await _repository.saveGuardian(guardian);
    await _supabaseService.saveGuardianInfo(guardian);

    // Save App Settings
    await prefs.setInt(AppConstants.keyVideoDuration, _settings.videoDuration);
    await prefs.setBool(AppConstants.keyEnableShake, _settings.enableShake);
    await prefs.setBool(AppConstants.keyEnableVolume, _settings.enableVolume);
    await prefs.setBool(AppConstants.keyAutoUpload, _settings.autoUpload);
    await prefs.setBool(AppConstants.keySaveToGallery, _settings.saveToGallery);
    await prefs.setBool(AppConstants.keyDarkMode, _settings.darkMode);
    await prefs.setString(AppConstants.keyThemePreset, _settings.themePreset);
    await prefs.setString(AppConstants.keyLanguage, _settings.language);
    await prefs.setBool(AppConstants.keyEnableCountdown, _settings.enableCountdown);
    await prefs.setString(AppConstants.keyAlertMethod, _settings.alertMethod);

    widget.onSettingsChanged?.call();

    if (!mounted) return;
    final colors = AppTheme.getColors(_settings.themePreset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Profile & Theme Settings saved successfully!"),
        backgroundColor: colors.safeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(_settings.themePreset);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(widget.initialSection == 'guardian' ? "Guardian Setup" : "Settings"),
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
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- FEATURED THEME SELECTION ---
                    _buildSectionTitle("Featured Theme Preset", Icons.palette_outlined, colors),
                    const SizedBox(height: 12),
                    Card(
                      color: colors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors.cardBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _settings.themePreset,
                              dropdownColor: colors.cardBg,
                              decoration: InputDecoration(
                                labelText: "Select Theme Preset",
                                prefixIcon: Icon(Icons.color_lens_outlined, color: colors.primaryRed),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'cyber_dark',
                                  child: Text('Cyber Dark (Default Screenshot UI)'),
                                ),
                                DropdownMenuItem(
                                  value: 'midnight_blue',
                                  child: Text('Midnight Sapphire'),
                                ),
                                DropdownMenuItem(
                                  value: 'sunset_crimson',
                                  child: Text('Sunset Crimson'),
                                ),
                                DropdownMenuItem(
                                  value: 'light_modern',
                                  child: Text('Light Modern'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      themePreset: val,
                                      darkMode: val != 'light_modern',
                                    );
                                  });
                                  _saveAllSettings();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- MY DETAILS SECTION ---
                    _buildSectionTitle("My Personal Details", Icons.badge_outlined, colors),
                    const SizedBox(height: 12),
                    Card(
                      color: colors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors.cardBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _myNameController,
                              decoration: InputDecoration(
                                labelText: "My Full Name",
                                prefixIcon: Icon(Icons.person_rounded, color: colors.primaryRed),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter your name" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _myEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "My Email",
                                prefixIcon: Icon(Icons.email_rounded, color: colors.primaryRed),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter your email" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _myMobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "My Mobile Number",
                                prefixIcon: Icon(Icons.phone_rounded, color: colors.primaryRed),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter your mobile number" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- GUARDIAN INFORMATION SECTION ---
                    _buildSectionTitle("Guardian Information", Icons.supervisor_account_rounded, colors),
                    const SizedBox(height: 12),
                    Card(
                      color: colors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors.cardBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _guardianNameController,
                              decoration: InputDecoration(
                                labelText: "Guardian Full Name",
                                prefixIcon: Icon(Icons.person_outline_rounded, color: colors.accentPurple),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter guardian name" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _guardianEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Guardian Email",
                                prefixIcon: Icon(Icons.email_outlined, color: colors.accentPurple),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter guardian email" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _guardianMobileController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Guardian Mobile Number",
                                prefixIcon: Icon(Icons.phone_outlined, color: colors.accentPurple),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter guardian mobile number" : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- EMERGENCY SETTINGS SECTION ---
                    _buildSectionTitle("Emergency Settings", Icons.bolt_rounded, colors),
                    const SizedBox(height: 12),
                    Card(
                      color: colors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colors.cardBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              value: _settings.videoDuration,
                              dropdownColor: colors.cardBg,
                              decoration: InputDecoration(
                                labelText: "Evidence Video Duration",
                                prefixIcon: Icon(Icons.videocam_outlined, color: colors.primaryRed),
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
                              dropdownColor: colors.cardBg,
                              decoration: InputDecoration(
                                labelText: "Preferred Alert Dispatch Method",
                                prefixIcon: Icon(Icons.send_rounded, color: colors.accentCyan),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'sms', child: Text('Automatic SMS (No Tap Required)')),
                                DropdownMenuItem(value: 'email', child: Text('Email Alert (Pre-filled 1-Tap)')),
                                DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp Direct (Pre-filled 1-Tap)')),
                                DropdownMenuItem(value: 'share', child: Text('Native System Share Sheet')),
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
                              activeColor: colors.primaryRed,
                              title: const Text("Enable Shake Detection"),
                              subtitle: const Text("Trigger SOS by shaking phone"),
                              value: _settings.enableShake,
                              onChanged: (val) => setState(() => _settings = _settings.copyWith(enableShake: val)),
                            ),
                            SwitchListTile(
                              activeColor: colors.primaryRed,
                              title: const Text("Volume Down Button Trigger"),
                              subtitle: const Text("Hold Volume Down for 3 seconds"),
                              value: _settings.enableVolume,
                              onChanged: (val) => setState(() => _settings = _settings.copyWith(enableVolume: val)),
                            ),
                            SwitchListTile(
                              activeColor: colors.primaryRed,
                              title: const Text("Emergency Countdown"),
                              subtitle: const Text("3-second cancelable countdown"),
                              value: _settings.enableCountdown,
                              onChanged: (val) => setState(() => _settings = _settings.copyWith(enableCountdown: val)),
                            ),
                            SwitchListTile(
                              activeColor: colors.primaryRed,
                              title: const Text("Auto Upload to Cloud"),
                              subtitle: const Text("Upload evidence to Supabase Storage"),
                              value: _settings.autoUpload,
                              onChanged: (val) => setState(() => _settings = _settings.copyWith(autoUpload: val)),
                            ),
                            SwitchListTile(
                              activeColor: colors.primaryRed,
                              title: const Text("Save to Device Gallery"),
                              subtitle: const Text("Save evidence video locally in Gallery"),
                              value: _settings.saveToGallery,
                              onChanged: (val) => setState(() => _settings = _settings.copyWith(saveToGallery: val)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: colors.accentCyan.withOpacity(0.12),
                      leading: Icon(Icons.security_rounded, color: colors.accentCyan),
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
                          backgroundColor: colors.primaryRed,
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

  Widget _buildSectionTitle(String title, IconData icon, SafeStepThemeColors colors) {
    return Row(
      children: [
        Icon(icon, color: colors.primaryRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
      ],
    );
  }
}
