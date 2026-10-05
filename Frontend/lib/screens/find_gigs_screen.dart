import 'package:flutter/material.dart';

class FindGigsScreen extends StatelessWidget {
  const FindGigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EmptyDestination(
      title: 'Find gigs',
      icon: Icons.work_outline,
    );
  }
}

class _EmptyDestination extends StatelessWidget {
  final String title;
  final IconData icon;

  const _EmptyDestination({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECFA),
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Color(0xFF172C57), fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF7890B8)),
            const SizedBox(height: 12),
            Text('$title coming soon', style: const TextStyle(color: Color(0xFF7890B8))),
          ],
        ),
      ),
    );
  }
}
