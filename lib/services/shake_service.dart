import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  static final ShakeService _instance = ShakeService._internal();
  factory ShakeService() => _instance;
  ShakeService._internal();

  StreamSubscription<AccelerometerEvent>? _subscription;
  Function()? onShakeDetected;

  // Threshold tuning parameters
  static const double _shakeThreshold = 2.7; // G-force sensitivity
  static const int _shakeCooldownMs = 1500; // Delay between triggers
  int _lastShakeTimestamp = 0;

  void startListening({required Function() onShake}) {
    onShakeDetected = onShake;

    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Calculate total acceleration magnitude divided by Earth's gravity (~9.81)
      double gX = event.x / 9.80665;
      double gY = event.y / 9.80665;
      double gZ = event.z / 9.80665;

      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > _shakeThreshold) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTimestamp > _shakeCooldownMs) {
          _lastShakeTimestamp = now;
          if (onShakeDetected != null) {
            onShakeDetected!();
          }
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}