import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/device_utils.dart';
import '../models/emergency_model.dart';
import '../models/guardian_model.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  bool _isSyncing = false;

  /// Queue unsent emergency item locally
  Future<void> queueEmergencyLocally({
    required EmergencyModel emergency,
    required GuardianModel guardian,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(AppConstants.keyOfflineQueue) ?? [];

      final itemJson = jsonEncode({
        'emergency': emergency.toJson(),
        'guardian': guardian.toJson(),
      });

      queue.add(itemJson);
      await prefs.setStringList(AppConstants.keyOfflineQueue, queue);
      debugPrint("OfflineSyncService: Emergency queued locally. Total queued: ${queue.length}");
    } catch (e) {
      debugPrint("OfflineSyncService Error queuing emergency: $e");
    }
  }

  /// Start monitoring connectivity changes and auto-syncing queued items
  void initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = await DeviceUtils.isInternetAvailable();
      if (isOnline && !_isSyncing) {
        debugPrint("OfflineSyncService: Internet connection restored. Triggering sync...");
        await syncPendingQueue();
      }
    });
  }

  /// Sync all locally queued emergency events to Supabase cloud
  Future<void> syncPendingQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(AppConstants.keyOfflineQueue) ?? [];

      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint("OfflineSyncService: Starting sync for ${queue.length} pending emergencies...");
      List<String> remainingQueue = [];

      for (String jsonStr in queue) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          var emergency = EmergencyModel.fromJson(map['emergency']);
          final guardian = GuardianModel.fromJson(map['guardian']);

          // 1. Upload video if local video exists and hasn't been uploaded yet
          if (emergency.localVideoPath != null &&
              (emergency.publicVideoUrl == null || emergency.publicVideoUrl!.isEmpty)) {
            final file = File(emergency.localVideoPath!);
            if (await file.exists()) {
              final fileName = "sos_${emergency.id}.mp4";
              final publicUrl = await _supabaseService.uploadEmergencyVideo(file, fileName);
              if (publicUrl != null) {
                emergency = emergency.copyWith(
                  publicVideoUrl: publicUrl,
                  uploadStatus: 'uploaded',
                );
              }
            }
          }

          // 2. Save record to Supabase DB
          final dbSuccess = await _supabaseService.saveEmergencyRecord(
            emergency: emergency,
            guardian: guardian,
          );

          if (dbSuccess) {
            // 3. Re-try sending guardian notification
            await _notificationService.sendGuardianNotification(
              emergency: emergency,
              guardian: guardian,
              method: 'share',
            );
            debugPrint("OfflineSyncService: Successfully synced emergency ${emergency.id}");
          } else {
            remainingQueue.add(jsonStr);
          }
        } catch (e) {
          debugPrint("OfflineSyncService Error syncing item: $e");
          remainingQueue.add(jsonStr);
        }
      }

      await prefs.setStringList(AppConstants.keyOfflineQueue, remainingQueue);
    } catch (e) {
      debugPrint("OfflineSyncService Critical Error: $e");
    } finally {
      _isSyncing = false;
    }
  }
}
