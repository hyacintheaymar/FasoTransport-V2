import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _pages = const [
    {
      'icon': '🚌',
      'title': 'FasoTransport',
      'sub': 'Réservez vos billets de bus\npartout au Burkina Faso',
    },
    {
      'icon': '🎫',
      'title': 'Billets QR Code',
      'sub': 'Recevez votre billet numérique\navec QR Code instantanément',
    },
    {
      'icon': '💺',
      'title': 'Choisissez votre siège',
      'sub': 'Sélectionnez votre siège préféré\nsur le plan du bus',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: Container(
            color: AppColors.navy,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(child: Text(_pages[_page]['icon']!, style: const TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 20),
                Text(
                  _pages[_page]['title']!,
                  style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  _pages[_page]['sub']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.55), height: 1.6),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            AppButton(
              label: _page < _pages.length - 1 ? 'Suivant' : 'Commencer',
              bg: AppColors.navy,
              onTap: () {
                if (_page < _pages.length - 1) {
                  setState(() => _page++);
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: "J'ai déjà un compte",
              outlined: true,
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
          ]),
        ),
      ]),
    );
  }
}
