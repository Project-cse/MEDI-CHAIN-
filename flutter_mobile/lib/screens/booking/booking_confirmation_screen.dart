import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/booking_state_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/appointment_receipt_actions.dart';
import '../../utils/appointment_receipt_pdf.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/animations/receipt_unroll.dart';
import '../../widgets/booking/appointment_receipt_card.dart';
import '../../widgets/common/app_snackbar.dart';

/// Post-booking receipt screen (mockup style).
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  bool _busy = false;

  AppointmentReceiptData? _receiptData(BookingDraft draft) {
    final id = draft.bookingId;
    if (id == null || id.isEmpty) return null;
    return AppointmentReceiptData(
      bookingId: id,
      tokenNumber: draft.tokenNumber,
      patientName: draft.patient.name,
      doctorName: draft.doctor.name,
      specialization: draft.doctor.specialization,
      hospitalName: draft.hospitalName ?? draft.doctor.hospitalName,
      location: draft.location,
      roomNo: draft.roomNo,
      appointmentDate: DateFormatter.formatSlotDate(draft.date),
      appointmentTime: draft.time,
      visitType: draft.visitType,
      status: 'Confirmed',
      amount: draft.doctor.consultationFee,
    );
  }

  Future<void> _runReceiptAction(Future<void> Function(AppointmentReceiptData) action) async {
    final draft = ref.read(bookingDraftProvider);
    final receipt = draft == null ? null : _receiptData(draft);
    if (receipt == null) {
      AppSnackbar.show(context, 'Booking ID required for PDF/share. Restart backend from fastapi_back on port 5000.');
      return;
    }
    setState(() => _busy = true);
    try {
      await action(receipt);
      if (mounted) AppSnackbar.show(context, 'Done', success: true);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'Could not process receipt');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    if (draft == null) {
      return Scaffold(
          body: Center(
          child: TextButton(onPressed: () => context.go(RouteNames.dashboard), child: const Text('Go Home')),
        ),
      );
    }

    final hasBookingId = draft.bookingId != null && draft.bookingId!.isNotEmpty;
    final isOnline = draft.visitType.toLowerCase().contains('online');
    final apptId = draft.appointmentId ?? '';

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Text(
          'Appointment Receipt',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          if (hasBookingId)
            IconButton(
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              onPressed: _busy ? null : () => _runReceiptAction(AppointmentReceiptActions.downloadOrSharePdf),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            ReceiptUnroll(
              child: AppointmentReceiptCard(
              bookingId: draft.bookingId,
              tokenNumber: draft.tokenNumber,
              patientName: draft.patient.name,
              doctorName: draft.doctor.name,
              specialization: draft.doctor.specialization,
              hospitalName: draft.hospitalName ?? draft.doctor.hospitalName,
              location: draft.location,
              roomNo: draft.roomNo,
              appointmentDate: DateFormatter.formatSlotDate(draft.date),
              appointmentTime: draft.time,
              visitType: draft.visitType,
              status: 'Confirmed',
              amountLabel: CurrencyFormatter.format(draft.doctor.consultationFee),
              showConfirmationBanner: true,
              onWhatsApp: hasBookingId && !_busy
                  ? () => _runReceiptAction(AppointmentReceiptActions.shareWhatsApp)
                  : null,
              onEmail: hasBookingId && !_busy
                  ? () => _runReceiptAction(AppointmentReceiptActions.shareEmail)
                  : null,
              onPrint: hasBookingId && !_busy
                  ? () => _runReceiptAction(AppointmentReceiptActions.printReceipt)
                  : null,
            ),
            ),
            if (!hasBookingId)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'QR code appears when the server returns a Booking ID (BK…). Ensure fastapi_back is running on port 5000.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            if (isOnline && apptId.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/video-consult/$apptId'),
                  icon: const Icon(Icons.videocam),
                  label: Text('Join Video Consult', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.specCircleFill,
                    foregroundColor: AppColors.brandNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(RouteNames.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Go to Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.appointments),
              child: Text(
                'View Appointments',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.logoTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
