import '../models/appointment_model.dart';
import '../models/notification_model.dart';
import '../utils/date_formatter.dart';
import 'appointment_service.dart';

/// Backend has no dedicated notifications API in RN (falls back to 0).
/// Derives reminders from upcoming appointments.
class NotificationService {
  NotificationService(this._appointments);

  final AppointmentService _appointments;

  Future<List<NotificationModel>> fetchAll() async {
    try {
      final upcoming = await _appointments.fetchAppointments(statusFilter: 'upcoming');
      return upcoming.map(_fromAppointment).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  static String _doctorLabel(String name) {
    final n = name.trim();
    if (n.toLowerCase().startsWith('dr.')) return n;
    if (n.toLowerCase().startsWith('dr ')) return n;
    return 'Dr. $n';
  }

  NotificationModel _fromAppointment(AppointmentModel a) {
    return NotificationModel(
      id: 'appt_${a.id}',
      title: 'Upcoming appointment',
      message:
          'With ${_doctorLabel(a.doctorName)} on ${DateFormatter.formatSlotDate(a.slotDate)} at ${DateFormatter.displayTime(a.slotTime)}',
      timestamp: DateTime.now(),
      type: NotificationType.appointment,
      appointmentId: a.id,
    );
  }
}
