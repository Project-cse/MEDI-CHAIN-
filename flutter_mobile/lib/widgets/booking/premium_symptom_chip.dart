import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_booking_theme.dart';

class PremiumSymptomChip extends StatelessWidget {
  const PremiumSymptomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? PremiumBookingTheme.chipSelectedBg : PremiumBookingTheme.white,
          borderRadius: BorderRadius.circular(PremiumBookingTheme.chipRadius),
          border: Border.all(
            color: selected ? PremiumBookingTheme.accentBlue : PremiumBookingTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? PremiumBookingTheme.accentBlue : PremiumBookingTheme.text,
                  height: 1.2,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: PremiumBookingTheme.accentBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
