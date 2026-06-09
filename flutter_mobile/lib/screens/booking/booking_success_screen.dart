import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/booking_state_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/animations/success_celebration.dart';
import '../../widgets/common/app_button.dart' show AppButton, AppButtonVariant;

class BookingSuccessScreen extends ConsumerWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(bookingDraftProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              SuccessCelebration(
                title: 'Payment Successful',
                subtitle: draft != null
                    ? 'Appointment with Dr. ${draft.doctor.name} confirmed'
                    : 'Your appointment is confirmed',
                child: draft == null
                    ? null
                    : Column(
                        children: [
                          if (draft.bookingId != null)
                            Text(
                              draft.bookingId!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.logoTeal,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormatter.formatSlotDate(draft.date)} • ${draft.time}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
              ),
              const Spacer(),
              AppButton(
                label: 'View Receipt',
                onPressed: () {
                  final id = draft?.appointmentId;
                  if (id != null && id.isNotEmpty) {
                    context.push('/booking/receipt/$id');
                  } else {
                    context.go(RouteNames.bookingConfirmation);
                  }
                },
              ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 12),
              AppButton(
                label: 'Go to Home',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(RouteNames.dashboard),
              ).animate(delay: 800.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
