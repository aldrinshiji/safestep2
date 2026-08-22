class SettingsModel {
  final int videoDuration; // seconds: 10, 20, 30, 60
  final bool enableShake;
  final bool enableVolume;
  final bool autoUpload;
  final bool saveToGallery;
  final bool darkMode;
  final String themePreset; // 'cyber_dark', 'midnight_blue', 'sunset_crimson', 'light_modern'
  final String language;
  final bool enableCountdown;
  final String alertMethod; // 'whatsapp', 'sms', 'email', 'share'

  const SettingsModel({
    this.videoDuration = 10,
    this.enableShake = true,
    this.enableVolume = true,
    this.autoUpload = true,
    this.saveToGallery = true,
    this.darkMode = true,
    this.themePreset = 'cyber_dark',
    this.language = 'English',
    this.enableCountdown = true,
    this.alertMethod = 'whatsapp',
  });

  Map<String, dynamic> toJson() {
    return {
      'video_duration': videoDuration,
      'enable_shake': enableShake,
      'enable_volume': enableVolume,
      'auto_upload': autoUpload,
      'save_to_gallery': saveToGallery,
      'dark_mode': darkMode,
      'theme_preset': themePreset,
      'language': language,
      'enable_countdown': enableCountdown,
      'alert_method': alertMethod,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      videoDuration: (json['video_duration'] as num?)?.toInt() ?? 10,
      enableShake: json['enable_shake'] as bool? ?? true,
      enableVolume: json['enable_volume'] as bool? ?? true,
      autoUpload: json['auto_upload'] as bool? ?? true,
      saveToGallery: json['save_to_gallery'] as bool? ?? true,
      darkMode: json['dark_mode'] as bool? ?? true,
      themePreset: json['theme_preset'] as String? ?? 'cyber_dark',
      language: json['language'] as String? ?? 'English',
      enableCountdown: json['enable_countdown'] as bool? ?? true,
      alertMethod: json['alert_method'] as String? ?? 'whatsapp',
    );
  }

  SettingsModel copyWith({
    int? videoDuration,
    bool? enableShake,
    bool? enableVolume,
    bool? autoUpload,
    bool? saveToGallery,
    bool? darkMode,
    String? themePreset,
    String? language,
    bool? enableCountdown,
    String? alertMethod,
  }) {
    return SettingsModel(
      videoDuration: videoDuration ?? this.videoDuration,
      enableShake: enableShake ?? this.enableShake,
      enableVolume: enableVolume ?? this.enableVolume,
      autoUpload: autoUpload ?? this.autoUpload,
      saveToGallery: saveToGallery ?? this.saveToGallery,
      darkMode: darkMode ?? this.darkMode,
      themePreset: themePreset ?? this.themePreset,
      language: language ?? this.language,
      enableCountdown: enableCountdown ?? this.enableCountdown,
      alertMethod: alertMethod ?? this.alertMethod,
    );
  }
}
