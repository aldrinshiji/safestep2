import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VolumeService {
  static final VolumeService _instance = VolumeService._internal();
  factory VolumeService() => _instance;
  VolumeService._internal();

  Timer? _volumeDownTimer;
  bool _isVolumeDownPressed = false;
  Function()? onVolumeTriggered;

  /// Call this when Volume Down Key Down event is detected
  void handleKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.audioVolumeDown) {
      if (!_isVolumeDownPressed) {
        _isVolumeDownPressed = true;
        debugPrint("VolumeService: Volume Down pressed. Starting 3s timer...");
        _volumeDownTimer?.cancel();
        _volumeDownTimer = Timer(const Duration(seconds: 3), () {
          if (_isVolumeDownPressed) {
            debugPrint("VolumeService: Volume Down held for 3 seconds! SOS Triggered!");
            onVolumeTriggered?.call();
          }
        });
      }
    }
  }

  /// Call this when Volume Down Key Up event is detected
  void handleKeyUp(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.audioVolumeDown) {
      _isVolumeDownPressed = false;
      _volumeDownTimer?.cancel();
      _volumeDownTimer = null;
      debugPrint("VolumeService: Volume Down released before 3s.");
    }
  }

  void startListening({required Function() onTrigger}) {
    onVolumeTriggered = onTrigger;
  }

  void stopListening() {
    _volumeDownTimer?.cancel();
    _volumeDownTimer = null;
    _isVolumeDownPressed = false;
  }
}
