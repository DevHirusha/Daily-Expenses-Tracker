import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _openInitialScreen();
  }

  Future<void> _openInitialScreen() async {
    StoredSession? session;
    try {
      session = await AuthStorage.readSession();
    } catch (_) {
      // A storage/plugin failure should still leave the user at login rather
      // than keeping the splash screen open indefinitely.
      session = null;
    }
    await Future<void>.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final nextScreen = session == null
        ? const OnboardingScreen()
        : AppShell(email: session.email, token: session.token);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),

            const SizedBox(height: 20),

            const Text(
              'Pocket Crew',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                minHeight: 5,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF97316),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
