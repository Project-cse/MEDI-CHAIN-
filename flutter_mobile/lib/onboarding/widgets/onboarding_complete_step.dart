import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/route_names.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingCompleteStep extends ConsumerWidget {
  const OnboardingCompleteStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PremiumHealthcareTheme.heroGradient,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to MEDCLUES',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text),
              ),
              const SizedBox(height: 20),
              _check('Tutorial Completed'),
              _check('Emergency Contact Added'),
              _check('Profile Completed'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).finishOnboarding();
                    context.go(RouteNames.dashboard);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumHealthcareTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Start Using MEDCLUES', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _check(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: PremiumHealthcareTheme.successGreen, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: PremiumHealthcareTheme.text)),
        ],
      ),
    );
  }
}
