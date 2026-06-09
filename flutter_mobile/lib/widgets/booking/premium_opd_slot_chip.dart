import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_booking_theme.dart';

/// Full-width OPD / video slot selector — navy selected state + green check.
class PremiumOpdSlotChip extends StatelessWidget {
  const PremiumOpdSlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? PremiumBookingTheme.textSecondary
        : selected
            ? Colors.white
            : PremiumBookingTheme.text;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: !enabled
              ? PremiumBookingTheme.background
              : selected
                  ? PremiumBookingTheme.primaryBlue
                  : PremiumBookingTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? PremiumBookingTheme.primaryBlue : PremiumBookingTheme.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? PremiumBookingTheme.softShadow : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 20,
              color: selected ? Colors.white.withValues(alpha: 0.9) : PremiumBookingTheme.accentBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: PremiumBookingTheme.successGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
