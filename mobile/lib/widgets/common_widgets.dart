import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final PillType type;
  const StatusPill({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = {
      PillType.green: [AppColors.greenLight, AppColors.green],
      PillType.orange: [AppColors.orangeLight, AppColors.orange],
      PillType.red: [AppColors.redLight, AppColors.red],
      PillType.blue: [AppColors.navy3, AppColors.navy2],
    }[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors[0],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors[1],
        ),
      ),
    );
  }
}

enum PillType { green, orange, red, blue }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final bool outlined;
  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg = AppColors.navy,
    this.fg = Colors.white,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : bg,
          border: outlined ? Border.all(color: AppColors.gray3) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: outlined ? AppColors.textMain : fg,
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSub,
          ),
        ),
      );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final double borderWidth;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? AppColors.gray2, width: borderWidth),
        ),
        child: child,
      );
}

class LabeledInput extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  const LabeledInput({
    super.key,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.controller,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
}

class TripCard extends StatelessWidget {
  final String from;
  final String to;
  final String duration;
  final String price;
  final VoidCallback? onTap;
  const TripCard({
    super.key,
    required this.from,
    required this.to,
    required this.duration,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Text(from, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle)),
                  Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 1, color: AppColors.gray3)),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(to, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(duration, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSub)),
                  Text(price, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
                ],
              ),
            ],
          ),
        ),
      );
}

class BusSeatMap extends StatelessWidget {
  final List<int> takenSeats;
  final int? selectedSeat;
  final Function(int)? onSeatTap;

  const BusSeatMap({super.key, required this.takenSeats, this.selectedSeat, this.onSeatTap});

  @override
  Widget build(BuildContext context) {
    final rows = <List<int?>>[];
    int n = 1;
    for (int r = 0; r < 10; r++) {
      rows.add([n, n + 1, null, n + 2, n + 3]);
      n += 4;
    }
    rows.add([n, n + 1, n + 2, n + 3, n + 4]);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.gray1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray2),
      ),
      child: Column(
        children: [
          Text('— AVANT —', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 1)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gray3, width: 2), color: Colors.white),
              child: Center(child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.gray3, shape: BoxShape.circle))),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(AppColors.gray2, AppColors.gray3, 'Libre'),
              const SizedBox(width: 10),
              _legendItem(AppColors.navy, AppColors.navy, 'Occupé'),
              const SizedBox(width: 10),
              _legendItem(AppColors.orange, AppColors.orange, 'Choisi'),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((seatNum) {
                  if (seatNum == null) return const SizedBox(width: 14);
                  return _buildSeat(seatNum, isLast);
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text('— ARRIÈRE —', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSub, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color border, String label) => Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3), border: Border.all(color: border))),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSub)),
        ],
      );

  Widget _buildSeat(int n, bool isBench) {
    final isTaken = takenSeats.contains(n);
    final isSelected = selectedSeat == n;
    Color bg;
    Color border;
    Color textColor;
    if (isSelected) {
      bg = AppColors.orange;
      border = const Color(0xFFC85A0A);
      textColor = Colors.white;
    } else if (isTaken) {
      bg = AppColors.navy;
      border = const Color(0xFF0A2F5A);
      textColor = Colors.white;
    } else {
      bg = AppColors.gray2;
      border = AppColors.gray3;
      textColor = AppColors.gray4;
    }

    return GestureDetector(
      onTap: isTaken ? null : () => onSeatTap?.call(n),
      child: Container(
        width: isBench ? 34 : 30,
        height: isBench ? 24 : 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: isBench
              ? const BorderRadius.vertical(bottom: Radius.circular(5))
              : const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6), bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: border, offset: const Offset(0, -3), blurRadius: 0, spreadRadius: 0)],
        ),
        child: Center(child: Text('$n', style: GoogleFonts.dmSans(fontSize: 7, fontWeight: FontWeight.w700, color: textColor))),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTap;
  const AppBottomNav({super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Accueil'},
      {'icon': Icons.search_rounded, 'label': 'Trajets'},
      {'icon': Icons.confirmation_num_outlined, 'label': 'Billets'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
    ];
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray2, width: 0.5))),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.asMap().entries.map((e) {
            final active = e.key == activeIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(e.key),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value['icon'] as IconData, size: 22, color: active ? AppColors.navy : AppColors.gray4),
                      const SizedBox(height: 3),
                      Text(
                        e.value['label'] as String,
                        style: GoogleFonts.dmSans(fontSize: 10, color: active ? AppColors.navy : AppColors.gray4, fontWeight: active ? FontWeight.w700 : FontWeight.w400),
                      ),
                      if (active) ...[
                        const SizedBox(height: 3),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
