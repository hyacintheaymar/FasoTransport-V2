import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SearchCard extends StatefulWidget {
  final String departureValue;
  final String destinationValue;
  final String dateValue;
  final VoidCallback? onSwap;
  final VoidCallback? onDeparturePressed;
  final VoidCallback? onDestinationPressed;
  final VoidCallback? onDatePressed;
  final VoidCallback? onSearchPressed;

  const SearchCard({
    super.key,
    required this.departureValue,
    required this.destinationValue,
    required this.dateValue,
    this.onSwap,
    this.onDeparturePressed,
    this.onDestinationPressed,
    this.onDatePressed,
    this.onSearchPressed,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(15, 255, 255, 255), // rgba(255,255,255,0.06)
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.25), // rgba(201,168,76,0.25)
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Departure Field
          _buildLocationField(
            label: 'DÉPART',
            value: widget.departureValue,
            dotColor: AppColors.orange,
            onPressed: widget.onDeparturePressed,
          ),
          const SizedBox(height: 16),
          // Divider with Swap Button
          _buildSwapDivider(),
          const SizedBox(height: 16),
          // Destination Field
          _buildLocationField(
            label: 'DESTINATION',
            value: widget.destinationValue,
            dotColor: AppColors.green,
            onPressed: widget.onDestinationPressed,
          ),
          const SizedBox(height: 16),
          // Date Field
          _buildDateField(),
          const SizedBox(height: 16),
          // Search Button
          _buildSearchButton(),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required String value,
    required Color dotColor,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Dot indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Label and Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chevron icon
          Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Divider line
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        // Swap button
        GestureDetector(
          onTap: widget.onSwap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.compare_arrows,
              size: 14,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: widget.onDatePressed,
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.dateValue,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: widget.onSearchPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.orange,
              Color(0xFFD86A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          'Rechercher',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
