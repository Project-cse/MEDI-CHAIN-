import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_booking_theme.dart';

class PremiumDateChip extends StatelessWidget {
  const PremiumDateChip({
    super.key,
    required this.weekdayLabel,
    required this.dayNum,
    required this.monthShort,
    required this.selected,
    required this.onTap,
  });

  final String weekdayLabel;
  final int dayNum;
  final String monthShort;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? PremiumBookingTheme.primaryBlue : PremiumBookingTheme.white,
          borderRadius: BorderRadius.circular(PremiumBookingTheme.dateCardRadius),
          border: selected ? null : Border.all(color: PremiumBookingTheme.border),
          boxShadow: selected ? PremiumBookingTheme.softShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white.withValues(alpha: 0.9) : PremiumBookingTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayNum',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1,
                color: selected ? Colors.white : PremiumBookingTheme.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthShort,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white.withValues(alpha: 0.85) : PremiumBookingTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumDateNavButton extends StatelessWidget {
  const PremiumDateNavButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: PremiumBookingTheme.white,
          shape: BoxShape.circle,
          border: Border.all(color: PremiumBookingTheme.border),
          boxShadow: PremiumBookingTheme.softShadow,
        ),
        child: const Icon(
          Icons.chevron_right_rounded,
          color: PremiumBookingTheme.primaryBlue,
          size: 26,
        ),
      ),
    );
  }
}
