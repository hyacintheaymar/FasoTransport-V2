import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';

class StartupRouterScreen extends StatefulWidget {
  const StartupRouterScreen({super.key});

  @override
  State<StartupRouterScreen> createState() => _StartupRouterScreenState();
}

class _StartupRouterScreenState extends State<StartupRouterScreen> {
  final SessionStore _sessionStore = SessionStore();

  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    final token = await _sessionStore.getToken();
    final user = await _sessionStore.getUser();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/role');
      return;
    }

    final role = user?['role']?.toString().toUpperCase() ?? '';
    if (role == 'AGENT' || role == 'ADMIN') {
      Navigator.pushReplacementNamed(context, '/agent/trips');
      return;
    }

    if (role == 'PASSENGER') {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    Navigator.pushReplacementNamed(context, '/role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FasoTransport',
              style: GoogleFonts.syne(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
