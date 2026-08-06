import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  static final Battery _battery = Battery();
  static final Connectivity _connectivity = Connectivity();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get current battery percentage
  static Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return 100;
    }
  }

  /// Check if internet is available
  static Future<bool> isInternetAvailable() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      // Double check real connection with socket lookup
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get connectivity string summary
  static Future<String> getInternetStatusString() async {
    final available = await isInternetAvailable();
    return available ? "Online" : "Offline";
  }

  /// Get human-readable device model
  static Future<String> getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return "${androidInfo.manufacturer} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return "${iosInfo.name} ${iosInfo.model}";
      }
    } catch (_) {}
    return "Mobile Device";
  }

  /// Generate standard Google Maps URL from lat, lng
  static String buildGoogleMapsUrl(double lat, double lng) {
    return "https://maps.google.com/?q=$lat,$lng";
  }
}
