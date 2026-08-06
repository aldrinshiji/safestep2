import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

class GalleryService {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  /// Save video file to device gallery without deleting local file
  Future<bool> saveVideoToGallery(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("GalleryService: File does not exist at $filePath");
        return false;
      }

      // Check or request gallery permission
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          debugPrint("GalleryService: Gallery permission denied by user.");
          return false;
        }
      }

      await Gal.putVideo(filePath, album: "SafeStep Evidence");
      debugPrint("GalleryService: Video saved to device Gallery successfully!");
      return true;
    } catch (e) {
      debugPrint("GalleryService Error saving video to gallery: $e");
      return false;
    }
  }
}
