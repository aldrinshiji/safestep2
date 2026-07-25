import 'package:flutter/material.dart';
import '../services/shake_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ShakeService _shakeService = ShakeService();

  @override
  void initState() {
    super.initState();
    // Start monitoring accelerometer for emergency shake gestures
    _shakeService.startListening(onShake: _handleEmergencyTrigger);
  }

  @override
  void dispose() {
    _shakeService.stopListening();
    super.dispose();
  }

  void _handleEmergencyTrigger() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.red),
        title: const Text("EMERGENCY TRIGGERED!"),
        content: const Text(
          "Shake gesture detected! SafeStep is preparing to broadcast your location and start evidence capture.",
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
              // Future location & camera logic will hook in here
            },
            child: const Text("SEND SOS NOW", style: TextStyle(color: Colors.white)),
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 100, color: Colors.redAccent),
            SizedBox(height: 20),
            Text(
              "System Active",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Shake your device to trigger an emergency SOS alert.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}