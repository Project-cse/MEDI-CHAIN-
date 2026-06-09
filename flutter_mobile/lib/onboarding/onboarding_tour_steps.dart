import 'package:flutter/material.dart';

import '../routes/route_names.dart';

/// Where the coach-mark tooltip should prefer to appear relative to the anchor.
enum TooltipPlacement { auto, above, below, left, right }

class OnboardingTarget {
  const OnboardingTarget({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.placement = TooltipPlacement.auto,
  });

  /// Fractions of screen size (0–1) — keep small (nav tab, search bar, etc.).
  final double top;
  final double left;
  final double width;
  final double height;
  final double borderRadius;
  final TooltipPlacement placement;

  Rect rectFor(Size screen) {
    return Rect.fromLTWH(
      screen.width * left,
      screen.height * top,
      screen.width * width,
      screen.height * height,
    );
  }
}

class OnboardingTourStep {
  const OnboardingTourStep({
    required this.index,
    required this.route,
    required this.title,
    required this.message,
    required this.icon,
    required this.target,
  });

  final int index;
  final String route;
  final String title;
  final String message;
  final IconData icon;
  final OnboardingTarget target;
}

const onboardingTourSteps = <OnboardingTourStep>[
  OnboardingTourStep(
    index: 1,
    route: RouteNames.dashboard,
    title: 'Home',
    message:
        'Welcome to MEDCLUES. Your dashboard gives quick access to appointments, hospitals, doctors, records, and emergency services.',
    icon: Icons.home_rounded,
    target: OnboardingTarget(
      top: 0.9,
      left: 0.02,
      width: 0.22,
      height: 0.08,
      placement: TooltipPlacement.above,
    ),
  ),
  OnboardingTourStep(
    index: 2,
    route: RouteNames.hospitals,
    title: 'Hospitals',
    message: 'Search hospitals, explore specialties, and find healthcare facilities near you.',
    icon: Icons.local_hospital_rounded,
    target: OnboardingTarget(
      top: 0.16,
      left: 0.06,
      width: 0.88,
      height: 0.055,
      placement: TooltipPlacement.below,
    ),
  ),
  OnboardingTourStep(
    index: 3,
    route: RouteNames.doctors,
    title: 'Doctors',
    message: 'Find experienced doctors, view profiles, and book online or in-clinic consultations.',
    icon: Icons.medical_services_rounded,
    target: OnboardingTarget(
      top: 0.1,
      left: 0.06,
      width: 0.88,
      height: 0.055,
      placement: TooltipPlacement.below,
    ),
  ),
  OnboardingTourStep(
    index: 4,
    route: RouteNames.appointments,
    title: 'Appointments',
    message: 'Track upcoming, completed, and cancelled appointments in one place.',
    icon: Icons.calendar_today_rounded,
    target: OnboardingTarget(
      top: 0.9,
      left: 0.26,
      width: 0.22,
      height: 0.08,
      placement: TooltipPlacement.above,
    ),
  ),
  OnboardingTourStep(
    index: 5,
    route: '/records',
    title: 'Medical Records',
    message: 'Upload, view, and securely share prescriptions, lab reports, and medical documents.',
    icon: Icons.folder_open_rounded,
    target: OnboardingTarget(
      top: 0.9,
      left: 0.5,
      width: 0.22,
      height: 0.08,
      placement: TooltipPlacement.above,
    ),
  ),
  OnboardingTourStep(
    index: 6,
    route: RouteNames.emergency,
    title: 'Emergency',
    message:
        'In emergencies, MEDCLUES helps you access SOS assistance and notify trusted contacts quickly.',
    icon: Icons.emergency_rounded,
    target: OnboardingTarget(
      top: 0.34,
      left: 0.12,
      width: 0.76,
      height: 0.09,
      placement: TooltipPlacement.below,
    ),
  ),
];
