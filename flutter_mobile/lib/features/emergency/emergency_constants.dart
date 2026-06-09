import '../../constants/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class EmergencyConstants {
  /// When true, ambulance/police/fire tel: calls are blocked (testing only).
  static const testingMode = true;

  static const ambulance = '108';
  static const police = '100';
  static const policeAlt = '112';
  static const fire = '101';

  static const defaultTimerSeconds = 30;

  static const criticalSymptoms = {
    'Chest Pain',
    'Breathing Difficulty',
    'Heavy Bleeding',
    'Accident',
    'Stroke Symptoms',
  };

  static const moderateSymptoms = {'Severe Pain', 'Fever'};

  static const minorSymptoms = {'Other'};

  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedDark = Color(0xFFB91C1C);
  static const Color emergencyBg = Color(0xFFFFF1F2);
  static const Color emergencyText = AppColors.textPrimary;
}
