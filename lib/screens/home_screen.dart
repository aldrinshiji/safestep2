import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import '../services/location_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();
  final LocationService _locationService = LocationService();
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _shakeService.startListening(onShake: _handleEmergencyTrigger);
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    super.dispose();
  }

  Future<void> _handleEmergencyTrigger() async {
    setState(() {
      _isFetchingLocation = true;
    });

    String addressText = "Fetching location...";
    String coordsText = "";

    try {
      Map<String, String> locationData =
          await _locationService.getCurrentLocationAddress();
      addressText = locationData["address"] ?? "Unknown Area";
      coordsText = "Lat: ${locationData["lat"]}, Long: ${locationData["lng"]}";
    } catch (e) {
      addressText = "Error getting location";
      coordsText = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            size: 50, color: Colors.red),
        title: const Text("EMERGENCY TRIGGERED!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SafeStep captured your real-time location:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addressText,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  if (coordsText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      coordsText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("SEND SOS NOW",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeStep 2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              "System Active",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Shake your device to trigger an emergency SOS alert.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            if (_isFetchingLocation)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _handleEmergencyTrigger,
                icon: const Icon(Icons.sos, color: Colors.white),
                label: const Text("TEST SOS TRIGGER",
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
