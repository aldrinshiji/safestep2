import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint("Supabase Initialization Note: Using local fallback mode until credentials are updated. ($e)");
  }

  runApp(const SafeStepApp());
}

class SafeStepApp extends StatefulWidget {
  const SafeStepApp({super.key});

  @override
  State<SafeStepApp> createState() => _SafeStepAppState();
}

class _SafeStepAppState extends State<SafeStepApp> {
  String _themePreset = 'cyber_dark';
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool(AppConstants.keyDarkMode) ?? true;
      _themePreset = prefs.getString(AppConstants.keyThemePreset) ?? 'cyber_dark';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getThemeByPreset(_themePreset, isDark: false),
      darkTheme: AppTheme.getThemeByPreset(_themePreset, isDark: true),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeChanged: _loadTheme),
    );
  }
}