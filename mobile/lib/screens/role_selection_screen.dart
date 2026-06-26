import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'FasoTransport',
                style: GoogleFonts.syne(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez votre profil',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 36),
              _RoleCard(
                title: 'Passager',
                subtitle: 'Rechercher un trajet, reserver et gerer vos billets',
                icon: Icons.person_outline,
                background: Colors.white,
                border: AppColors.gray3,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  '/passenger/onboarding',
                ),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Agent',
                subtitle: 'Consulter les voyages et scanner les billets',
                icon: Icons.qr_code_scanner_outlined,
                background: AppColors.orangeLight,
                border: AppColors.orange.withValues(alpha: 0.35),
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/agent/login'),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Les parcours passager et agent sont separes',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.border,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray4),
            ],
          ),
        ),
      ),
    );
  }
}
