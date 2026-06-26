import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RouteCard extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final String price;
  final String departureTime;
  final String journeyDuration;
  final VoidCallback? onTap;

  const RouteCard({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.price,
    required this.departureTime,
    required this.journeyDuration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.gray2,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Cities and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Departure City
                      Text(
                        departureCity,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      // Arrow Icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppColors.orange,
                        ),
                      ),
                      // Arrival City
                      Expanded(
                        child: Text(
                          arrivalCity,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price Badge
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    '$price F',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom Row: Times and Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Circle separator
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Departure Time
                      Text(
                        'Départ $departureTime',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSub,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Circle separator
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Journey Duration
                      Expanded(
                        child: Text(
                          '~$journeyDuration de trajet',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSub,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron Icon
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
