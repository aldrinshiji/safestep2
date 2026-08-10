import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;

  /// Record video with audio for specified duration in seconds
  Future<File?> recordVideo({int durationSeconds = 10}) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("CameraService: No camera available on device.");
        return null;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium, // Keeps file size lightweight (~2.5MB)
        enableAudio: true,
      );

      await _controller!.initialize();
      await _controller!.startVideoRecording();
      debugPrint(
          "CameraService: Started recording video for $durationSeconds seconds...");

      await Future.delayed(Duration(seconds: durationSeconds));

      // Stop recording and safely extract file path
      final XFile videoXFile = await _controller!.stopVideoRecording();

      // Dispose controller immediately to free up hardware resources
      await _controller!.dispose();
      _controller = null;

      final File videoFile = File(videoXFile.path);
      if (await videoFile.exists()) {
        debugPrint(
            "CameraService: Video recording finished. Path: ${videoFile.path}");
        return videoFile;
      }
    } catch (e) {
      debugPrint("CameraService Error recording video: $e");
      try {
        await _controller?.dispose();
        _controller = null;
      } catch (_) {}
    }
    return null;
  }
}
