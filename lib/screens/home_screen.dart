import 'package:flutter/material.dart';
import 'package:safestep2/screens/settings_screen.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isProtectionActive = true;

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🚨 Emergency Triggered"),
        content: const Text("Recording video, fetching location, and sending alert to contacts..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: const Text(
          "SafeStep 2",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // System Protection Status Indicator
              StatusCard(isActive: isProtectionActive),

              // SOS Trigger Button
              Center(
                child: SOSButton(onTap: _triggerSOS),
              ),

              // Quick Information Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      "Shake hard or long-press volume button anywhere",
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}