import 'package:flutter/material.dart';

/// 2026 corporate healthcare booking — Apple Health / Practo tier tokens.
abstract final class PremiumBookingTheme {
  static const Color primaryBlue = Color(0xFF003B8E);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color chipSelectedBg = Color(0xFFEFF6FF);
  static const Color securityBg = Color(0xFFF0F7FF);
  static const Color starGold = Color(0xFFF59E0B);

  static const double horizontalPadding = 24;
  static const double cardRadius = 24;
  static const double chipRadius = 14;
  static const double dateCardRadius = 20;
  static const double buttonRadius = 18;
  static const double buttonHeight = 60;
  static const double sectionGap = 28;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF003B8E), Color(0xFF002654)],
  );

  static List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.32),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
