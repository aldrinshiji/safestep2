class AppConstants {
  static const String appName = 'SafeStep';
  static const String supabaseUrl = 'https://dymqyrpnaoqsnucytklo.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_rvy7tO2y1-ndNk91Ld3ohA_nzt0Rcnk';
  static const String emergencyVideosBucket = 'emergency_videos';

  // Settings Keys
  static const String keyGuardianName = 'guardian_name';
  static const String keyGuardianEmail = 'guardian_email';
  static const String keyGuardianMobile = 'guardian_mobile';
  static const String keyAlertMethod =
      'alert_method'; // 'whatsapp', 'sms', 'email', 'share'
  static const String keyVideoDuration = 'video_duration'; // 10, 20, 30, 60
  static const String keyEnableShake = 'enable_shake';
  static const String keyEnableVolume = 'enable_volume';
  static const String keyAutoUpload = 'auto_upload';
  static const String keySaveToGallery = 'save_to_gallery';
  static const String keyDarkMode = 'dark_mode';
  static const String keyThemePreset = 'theme_preset'; // 'cyber_dark', 'midnight_blue', 'sunset_crimson', 'light_modern'
  static const String keyLanguage = 'language';
  static const String keyEnableCountdown = 'enable_countdown';
  static const String keyOfflineQueue = 'offline_emergencies_queue';

  // National Helpline Numbers
  static const String helplineWomen = '1091';
  static const String helplineNational = '112';
}
