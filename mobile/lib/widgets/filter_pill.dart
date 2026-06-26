import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.navy : AppColors.gray2,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSub,
          ),
        ),
      ),
    );
  }
}

class FilterPillRow extends StatefulWidget {
  final List<String> labels;
  final ValueChanged<int>? onFilterChanged;
  final int initialIndex;

  const FilterPillRow({
    super.key,
    required this.labels,
    this.onFilterChanged,
    this.initialIndex = 0,
  });

  @override
  State<FilterPillRow> createState() => _FilterPillRowState();
}

class _FilterPillRowState extends State<FilterPillRow> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _selectPill(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onFilterChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          widget.labels.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              right: index < widget.labels.length - 1 ? 8 : 0,
              left: index == 0 ? 0 : 0,
            ),
            child: FilterPill(
              label: widget.labels[index],
              isActive: index == _selectedIndex,
              onTap: () => _selectPill(index),
            ),
          ),
        ),
      ),
    );
  }
}
