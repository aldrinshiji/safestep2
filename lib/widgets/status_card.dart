import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final bool isActive;

  const StatusCard({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.shield_outlined : Icons.warning_amber_rounded,
            color: isActive ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            // ❌ Incorrect
            // ✅ Correct
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? "Protection Active" : "Protection Disabled",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green[800] : Colors.red[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isActive
                    ? "Shake & Volume triggers listening"
                    : "Tap to enable emergency services",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
