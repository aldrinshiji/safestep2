import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Gets real-time GPS coordinates and translates them into an address string.
  Future<Map<String, String>> getCurrentLocationAddress() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled on your device.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions were denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied. Enable them in settings.');
    }

    // 1. Get raw GPS coordinates
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      // 2. Reverse geocode coordinates to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String locality = place.locality ?? place.subLocality ?? "";
        String area = place.subAdministrativeArea ?? place.administrativeArea ?? "";
        String street = place.street ?? "";

        String readableAddress = "$street, $locality, $area".replaceAll(RegExp(r'^,\s*|,\s*$'), '');

        return {
          "address": readableAddress.isEmpty ? "$locality, $area" : readableAddress,
          "lat": position.latitude.toStringAsFixed(5),
          "lng": position.longitude.toStringAsFixed(5),
        };
      }
    } catch (_) {
      // Fallback if network lookup fails
    }

    return {
      "address": "Coordinates Captured",
      "lat": position.latitude.toStringAsFixed(5),
      "lng": position.longitude.toStringAsFixed(5),
    };
  }
}