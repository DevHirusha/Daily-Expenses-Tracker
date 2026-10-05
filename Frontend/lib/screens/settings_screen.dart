import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final String email;

  const SettingsScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECFA),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Color(0xFF172C57), fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Text('Settings for $email', style: const TextStyle(color: Color(0xFF7890B8))),
      ),
    );
  }
}
