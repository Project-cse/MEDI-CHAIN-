import 'package:flutter/material.dart';

/// 2026 MEDCLUES corporate healthcare — patient booking + hospital flows.
abstract final class PremiumHealthcareTheme {
  static const Color primaryBlue = Color(0xFF003B8E);
  static const Color secondaryBlue = Color(0xFF2563EB);
  static const Color heroEndBlue = Color(0xFF1D4ED8);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color navyButton = Color(0xFF003B8E);

  static const double horizontalPadding = 24;
  static const double sheetTopRadius = 28;
  static const double cardRadius = 24;
  static const double doctorCardRadius = 20;
  static const double fieldRadius = 14;
  static const double fieldHeight = 56;
  static const double ctaRadius = 16;
  static const double ctaHeight = 56;
  static const double bookBtnHeight = 40;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryBlue],
  );

  static const LinearGradient hospitalHeroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, secondaryBlue],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryBlue],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get fieldShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get ctaShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
