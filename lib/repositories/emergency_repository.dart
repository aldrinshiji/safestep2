import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_model.dart';
import '../models/guardian_model.dart';

class EmergencyRepository {
  static const String _keyHistory = 'emergency_history_logs';

  /// Load all local emergency logs sorted newest first
  Future<List<EmergencyModel>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_keyHistory) ?? [];
      final List<EmergencyModel> list = rawList
          .map((jsonStr) => EmergencyModel.fromJson(jsonDecode(jsonStr)))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      debugPrint("EmergencyRepository Error loading history: $e");
      return [];
    }
  }

  /// Save or update an emergency log in local history
  Future<void> saveEmergencyLog(EmergencyModel emergency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<EmergencyModel> history = await loadHistory();

      int existingIndex = history.indexWhere((item) => item.id == emergency.id);
      if (existingIndex >= 0) {
        history[existingIndex] = emergency;
      } else {
        history.insert(0, emergency);
      }

      final List<String> rawList =
          history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_keyHistory, rawList);
    } catch (e) {
      debugPrint("EmergencyRepository Error saving log: $e");
    }
  }

  /// Delete an emergency log from local history
  Future<void> deleteEmergencyLog(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<EmergencyModel> history = await loadHistory();
      history.removeWhere((item) => item.id == id);
      final List<String> rawList =
          history.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_keyHistory, rawList);
    } catch (e) {
      debugPrint("EmergencyRepository Error deleting log: $e");
    }
  }

  /// Load Guardian Information
  Future<GuardianModel> loadGuardian() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return GuardianModel(
        name: prefs.getString('guardian_name') ?? 'Guardian',
        email: prefs.getString('guardian_email') ?? '',
        mobileNumber: prefs.getString('guardian_mobile') ?? prefs.getString('emergency_contact') ?? '+919876543210',
      );
    } catch (_) {
      return GuardianModel.empty;
    }
  }

  /// Save Guardian Information
  Future<void> saveGuardian(GuardianModel guardian) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guardian_name', guardian.name);
    await prefs.setString('guardian_email', guardian.email);
    await prefs.setString('guardian_mobile', guardian.mobileNumber);
    // Backward compatibility
    await prefs.setString('emergency_contact', guardian.mobileNumber);
  }
}
