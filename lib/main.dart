import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SafeStepApp());
}

class SafeStepApp extends StatelessWidget {
  const SafeStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeStep 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
