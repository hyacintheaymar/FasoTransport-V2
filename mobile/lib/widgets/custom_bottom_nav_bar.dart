import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;
  final List<IconData> icons;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.labels = const ['Accueil', 'Trajets', 'Billets', 'Profil'],
    this.icons = const [
      Icons.home,
      Icons.search,
      Icons.confirmation_number,
      Icons.person,
    ],
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.gray2,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56 + MediaQuery.of(context).padding.bottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.icons.length,
              (index) => _buildNavItem(
                icon: widget.icons[index],
                label: widget.labels[index],
                isActive: index == widget.currentIndex,
                onTap: () => widget.onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors.navy
                : AppColors.gray4,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? AppColors.navy
                  : AppColors.gray4,
            ),
          ),
          const SizedBox(height: 4),
          // Active indicator dot
          if (isActive)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 4, height: 4), // Placeholder for alignment
        ],
      ),
    );
  }
}
