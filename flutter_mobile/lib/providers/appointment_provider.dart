import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../models/slot_model.dart';
import '../services/consultation_service.dart';
import 'service_providers.dart';

final upcomingAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).upcoming();
});

final pastAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).past();
});

final cancelledAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) {
  return ref.watch(appointmentRepositoryProvider).cancelled();
});

final appointmentDetailProvider =
    FutureProvider.autoDispose.family<AppointmentModel, String>((ref, id) {
  return ref.watch(appointmentRepositoryProvider).getById(id);
});

final consultationSummaryProvider =
    FutureProvider.autoDispose.family<ConsultationSummary?, String>((ref, appointmentId) {
  return ref.watch(consultationServiceProvider).fetchConsultationSummary(appointmentId);
});

/// Full 5-day schedule — one API call per doctor + mode (reused when switching dates).
final doctorScheduleProvider = FutureProvider.autoDispose
    .family<Map<String, DaySlotsModel>, ({String doctorId, String mode})>((ref, params) {
  return ref
      .watch(appointmentRepositoryProvider)
      .doctorSchedule(params.doctorId, mode: params.mode);
});

/// Warm slot cache while user picks patient / navigates to booking.
void prefetchDoctorSchedule(WidgetRef ref, String doctorId, {String mode = 'offline'}) {
  ref.read(doctorScheduleProvider((doctorId: doctorId, mode: mode)).future);
}

final slotsProvider = FutureProvider.autoDispose
    .family<DaySlotsModel, ({String doctorId, String date, String mode})>((ref, params) async {
  final schedule = await ref.watch(
    doctorScheduleProvider((doctorId: params.doctorId, mode: params.mode)).future,
  );
  return schedule[params.date] ??
      DaySlotsModel(date: params.date, displayDate: params.date, slots: const []);
});

final bookingInProgressProvider = StateProvider<bool>((_) => false);

/// 0 = Upcoming, 1 = Completed, 2 = Cancelled (My Appointments tabs).
final appointmentsTabProvider = StateProvider<int>((_) => 0);

/// IDs the user just cancelled — hidden from the Upcoming list instantly while
/// the (slower) server call + refresh complete in the background.
final optimisticCancelledProvider = StateProvider<Set<String>>((_) => {});

/// Cancel on the server, then refresh the appointment lists. This is meant to
/// run in the background after the UI has already optimistically removed the
/// appointment, so the user never waits on the network.
Future<void> cancelAppointmentAndRefresh(WidgetRef ref, String appointmentId) async {
  try {
    await ref.read(appointmentRepositoryProvider).cancel(appointmentId);
  } finally {
    ref.invalidate(upcomingAppointmentsProvider);
    ref.invalidate(pastAppointmentsProvider);
    ref.invalidate(cancelledAppointmentsProvider);
    ref.invalidate(appointmentDetailProvider(appointmentId));
  }
}
