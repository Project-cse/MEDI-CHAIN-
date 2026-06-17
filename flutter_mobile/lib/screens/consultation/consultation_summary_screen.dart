import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../l10n/l10n_extension.dart';
import '../../providers/appointment_provider.dart';
import '../../routes/route_names.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_loader.dart';

class ConsultationSummaryScreen extends ConsumerStatefulWidget {
  const ConsultationSummaryScreen({
    super.key,
    required this.appointmentId,
    this.durationSeconds = 0,
    this.message,
  });

  final String appointmentId;
  final int durationSeconds;
  final String? message;

  @override
  ConsumerState<ConsultationSummaryScreen> createState() => _ConsultationSummaryScreenState();
}

class _ConsultationSummaryScreenState extends ConsumerState<ConsultationSummaryScreen> {
  Timer? _pollTimer;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSummary();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_pollCount >= 10) {
          _pollTimer?.cancel();
          return;
        }
        _pollCount++;
        _refreshSummary();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _refreshSummary() {
    ref.invalidate(consultationSummaryProvider(widget.appointmentId));
    ref.invalidate(appointmentDetailProvider(widget.appointmentId));
  }

  String _durationLabel() {
    final m = widget.durationSeconds ~/ 60;
    final s = widget.durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appt = ref.watch(appointmentDetailProvider(widget.appointmentId));
    final summary = ref.watch(consultationSummaryProvider(widget.appointmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Consultation summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSummary,
            tooltip: 'Refresh prescription',
          ),
        ],
      ),
      body: appt.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (a) => summary.when(
          loading: () => const AppLoader(),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (s) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle, color: AppColors.logoTeal, size: 72),
                const SizedBox(height: 16),
                Text(
                  l10n.videoEndCall,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message ?? 'Your video consultation has ended.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                _row(Icons.person_outline, 'Doctor', a.doctorName),
                _row(Icons.schedule, 'Duration', _durationLabel()),
                _row(Icons.calendar_today_outlined, 'Date', '${a.slotDate} · ${a.slotTime}'),
                if (s != null && s.hasContent) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Prescription & notes',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (s.diagnosis != null && s.diagnosis!.trim().isNotEmpty)
                    _summaryCard('Diagnosis', s.diagnosis!),
                  if (s.prescription != null && s.prescription!.trim().isNotEmpty)
                    _summaryCard('Prescription', s.prescription!),
                  if (s.notes != null && s.notes!.trim().isNotEmpty) _summaryCard('Notes', s.notes!),
                  if (s.advice != null && s.advice!.trim().isNotEmpty) _summaryCard('Advice', s.advice!),
                  if (s.followupDate != null && s.followupDate!.trim().isNotEmpty)
                    _row(Icons.event_outlined, 'Follow-up', s.followupDate!),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'Waiting for your doctor to send the prescription… This page refreshes automatically.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.amber.shade900),
                    ),
                  ),
                ],
                const Spacer(),
                AppButton(
                  label: 'View appointment',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push('/appointment-detail/${widget.appointmentId}'),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: l10n.commonDone,
                  onPressed: () => context.go(RouteNames.appointments),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.logoTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.logoTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.logoTeal),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.logoTeal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
