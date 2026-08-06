import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/emergency_model.dart';
import '../models/guardian_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Check if Supabase client is initialized with real credentials
  bool get isConfigured {
    try {
      const url = AppConstants.supabaseUrl;
      return url.isNotEmpty && !url.contains('YOUR_SUPABASE_PROJECT_URL');
    } catch (_) {
      return false;
    }
  }

  /// Ensure user is logged in (anonymously or via auth)
  Future<User?> signInAnonymouslyIfNeeded() async {
    if (!isConfigured) return null;
    try {
      if (_client.auth.currentSession == null) {
        final response = await _client.auth.signInAnonymously();
        return response.user;
      }
      return _client.auth.currentUser;
    } catch (e) {
      debugPrint("Supabase Auth Error: $e");
      return null;
    }
  }

  /// Upload emergency video file to 'emergency-videos' bucket
  Future<String?> uploadEmergencyVideo(File file, String fileName) async {
    if (!isConfigured) {
      debugPrint("Supabase not fully configured. Video upload skipped.");
      return null;
    }

    try {
      await signInAnonymouslyIfNeeded();
      final storageResponse = await _client.storage
          .from(AppConstants.emergencyVideosBucket)
          .upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      if (storageResponse.isNotEmpty) {
        final publicUrl = _client.storage
            .from(AppConstants.emergencyVideosBucket)
            .getPublicUrl(fileName);
        debugPrint("Supabase Video Upload Successful: $publicUrl");
        return publicUrl;
      }
    } catch (e) {
      debugPrint("Error uploading video to Supabase Storage: $e");
    }
    return null;
  }

  /// Save complete emergency record to Supabase DB tables
  Future<bool> saveEmergencyRecord({
    required EmergencyModel emergency,
    required GuardianModel guardian,
  }) async {
    if (!isConfigured) return false;

    try {
      final user = await signInAnonymouslyIfNeeded();
      final userId = user?.id;

      // 1. Insert into 'emergencies' table
      await _client.from('emergencies').insert({
        'id': emergency.id,
        'user_id': userId,
        'timestamp': emergency.timestamp.toIso8601String(),
        'device_model': emergency.deviceModel,
        'battery_percentage': emergency.batteryPercentage,
        'internet_status': emergency.internetStatus,
        'upload_status': emergency.uploadStatus,
        'guardian_status': emergency.guardianStatus,
      });

      // 2. Insert into 'locations' table
      await _client.from('locations').insert({
        'emergency_id': emergency.id,
        'latitude': emergency.latitude,
        'longitude': emergency.longitude,
        'address': emergency.address,
        'google_maps_url': emergency.googleMapsUrl,
      });

      // 3. Insert into 'videos' table if URL exists
      if (emergency.publicVideoUrl != null && emergency.publicVideoUrl!.isNotEmpty) {
        await _client.from('videos').insert({
          'emergency_id': emergency.id,
          'public_url': emergency.publicVideoUrl,
          'local_path': emergency.localVideoPath,
          'created_at': emergency.timestamp.toIso8601String(),
        });
      }

      // 4. Insert into 'notification_logs' table
      await _client.from('notification_logs').insert({
        'emergency_id': emergency.id,
        'guardian_name': guardian.name,
        'guardian_email': guardian.email,
        'guardian_mobile': guardian.mobileNumber,
        'status': emergency.guardianStatus,
        'sent_at': DateTime.now().toIso8601String(),
      });

      debugPrint("Emergency record saved to Supabase DB successfully.");
      return true;
    } catch (e) {
      debugPrint("Error inserting emergency record into Supabase: $e");
      return false;
    }
  }

  /// Save or update guardian info in Supabase 'guardians' table
  Future<bool> saveGuardianInfo(GuardianModel guardian) async {
    if (!isConfigured) return false;
    try {
      final user = await signInAnonymouslyIfNeeded();
      if (user == null) return false;

      await _client.from('guardians').upsert({
        'user_id': user.id,
        'name': guardian.name,
        'email': guardian.email,
        'mobile_number': guardian.mobileNumber,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Error saving guardian info to Supabase: $e");
      return false;
    }
  }
}
