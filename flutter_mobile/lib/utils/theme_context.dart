import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Theme-aware semantic colors — use instead of hardcoded [AppColors] in widgets.
extension MedcluesThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => theme.colorScheme;
  bool get isDark => theme.brightness == Brightness.dark;

  Color get cardColor => cs.surface;
  Color get scaffoldBg => theme.scaffoldBackgroundColor;
  Color get primaryText => cs.onSurface;
  Color get secondaryText => cs.onSurfaceVariant;
  Color get hintText => isDark ? const Color(0xFF64748B) : AppColors.textHint;
  Color get borderColor => cs.outline;
  Color get highlightBg =>
      isDark ? const Color(0xFF0C4A6E) : AppColors.brandBlueLight;
  Color get chipSelectedBg =>
      isDark ? const Color(0xFF0C4A6E) : AppColors.brandBlueLight;
  Color get chipUnselectedBg => isDark ? cs.surface : AppColors.white;
  Color get iconMuted => secondaryText;
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.brandNavy.withValues(alpha: 0.08);

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  BoxDecoration cardDecoration({double radius = 16, BorderSide? side}) =>
      BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: side != null ? Border.fromBorderSide(side) : Border.all(color: borderColor),
        boxShadow: cardShadow,
      );
}
