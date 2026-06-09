import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/route_names.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../emergency_constants.dart';
import '../models/emergency_case_model.dart';
import '../providers/emergency_provider.dart';
import '../services/emergency_notification_service.dart';
import '../widgets/emergency_action_button.dart';
import '../widgets/emergency_home_button.dart';
import '../widgets/emergency_whatsapp_contacts_panel.dart';

/// Post-SOS screen with calls, location, hospitals, and contacts.
class EmergencyActiveScreen extends ConsumerWidget {
  const EmergencyActiveScreen({super.key});

  Future<void> _serviceCall(BuildContext context, String number, String label) async {
    if (EmergencyConstants.testingMode) {
      AppSnackbar.show(
        context,
        'Testing mode: $label ($number) call disabled',
      );
      return;
    }
    final ok = await launchEmergencyServiceCall(number: number, label: label);
    if (!ok && context.mounted) {
      AppSnackbar.show(context, 'Could not place $label call');
    }
  }

  Future<void> _shareAlertWhatsApp(BuildContext context, WidgetRef ref) async {
    final settings = await ref.read(emergencySettingsProvider.future);
    final session = ref.read(emergencySessionProvider);
    final notify = ref.read(emergencyNotificationProvider);
    final msg = notify.buildAlertMessage(
      settings: settings,
      location: session.location,
      extraNote: session.activeCase?.symptoms.isNotEmpty == true
          ? 'Symptoms: ${session.activeCase!.symptoms.join(', ')}'
          : null,
    );
    final contacts = settings.savedContacts;
    if (contacts.isEmpty) {
      await notify.manualShare(msg);
      if (context.mounted) {
        AppSnackbar.show(context, 'No relatives saved — shared via system sheet');
      }
    } else {
      await notify.openWhatsAppMessage(phone: contacts.first.phone, message: msg);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(emergencySessionProvider);
    final caseModel = session.activeCase;
    final severity = caseModel?.severity ?? EmergencySeverity.critical;
    final settingsAsync = ref.watch(emergencySettingsProvider);
    final hasContacts = settingsAsync.value?.savedContacts.isNotEmpty == true;

    return Scaffold(
      backgroundColor: EmergencyConstants.emergencyBg,
      appBar: AppBar(
        backgroundColor: EmergencyConstants.emergencyRed,
        foregroundColor: Colors.white,
        title: const Text('Emergency Active'),
        leading: const EmergencyHomeButton(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (EmergencyConstants.testingMode) _testingBanner(),
            _statusHeader(severity),
            const SizedBox(height: 16),
            const EmergencyWhatsappContactsPanel(),
            if (hasContacts) const SizedBox(height: 8),
            if (severity == EmergencySeverity.critical) ..._criticalActions(context, ref),
            if (severity == EmergencySeverity.moderate) ..._moderateActions(context, ref),
            if (severity == EmergencySeverity.minor) ..._minorActions(context),
            const SizedBox(height: 8),
            EmergencyActionButton(
              label: 'WhatsApp Location Alert',
              subtitle: hasContacts
                  ? 'Send live location link to relatives'
                  : 'No relatives saved — use share sheet',
              icon: Icons.share_location,
              filled: false,
              onTap: () => _shareAlertWhatsApp(context, ref),
            ),
            if (session.location != null)
              EmergencyActionButton(
                label: 'Open My Location',
                subtitle: session.location!.mapsLink,
                icon: Icons.map,
                filled: false,
                onTap: () => ref.read(emergencyLocationProvider).openMapsLink(session.location!.mapsLink),
              ),
            EmergencyActionButton(
              label: 'Emergency Settings',
              icon: Icons.settings,
              filled: false,
              onTap: () => context.push(RouteNames.emergencySettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testingBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEA580C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Color(0xFFEA580C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Testing mode: Ambulance, police & fire calls disabled. WhatsApp messages, location & relative phone calls work.',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusHeader(EmergencySeverity severity) {
    final (title, color) = switch (severity) {
      EmergencySeverity.critical => ('CRITICAL — Help is needed now', EmergencyConstants.emergencyRed),
      EmergencySeverity.moderate => ('MODERATE — Seek medical attention', const Color(0xFFEA580C)),
      EmergencySeverity.minor => ('MINOR — Monitor or book consultation', const Color(0xFF2563EB)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Icon(Icons.emergency, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _criticalActions(BuildContext context, WidgetRef ref) {
    return [
      EmergencyActionButton(
        label: 'Call Ambulance',
        subtitle: EmergencyConstants.testingMode
            ? '${EmergencyConstants.ambulance} (disabled in testing)'
            : EmergencyConstants.ambulance,
        icon: Icons.local_hospital,
        onTap: () => _serviceCall(context, EmergencyConstants.ambulance, 'Ambulance'),
      ),
      EmergencyActionButton(
        label: 'Call Police',
        subtitle: EmergencyConstants.testingMode
            ? 'Disabled in testing'
            : '${EmergencyConstants.police} / ${EmergencyConstants.policeAlt}',
        icon: Icons.local_police,
        onTap: () => _serviceCall(context, EmergencyConstants.police, 'Police'),
      ),
      EmergencyActionButton(
        label: 'Call Fire',
        subtitle: EmergencyConstants.testingMode
            ? '${EmergencyConstants.fire} (disabled in testing)'
            : EmergencyConstants.fire,
        icon: Icons.local_fire_department,
        filled: false,
        onTap: () => _serviceCall(context, EmergencyConstants.fire, 'Fire'),
      ),
      EmergencyActionButton(
        label: 'Nearby Hospitals',
        icon: Icons.place,
        filled: false,
        onTap: () => ref.read(emergencyLocationProvider).openNearbyHospitals(
              location: ref.read(emergencySessionProvider).location,
            ),
      ),
    ];
  }

  List<Widget> _moderateActions(BuildContext context, WidgetRef ref) {
    return [
      EmergencyActionButton(
        label: 'Emergency Video Doctor',
        subtitle: 'Connect to available doctors',
        icon: Icons.video_call,
        onTap: () => context.push('${RouteNames.doctors}?visit=online'),
      ),
      EmergencyActionButton(
        label: 'Nearby Hospitals',
        icon: Icons.place,
        filled: false,
        onTap: () => ref.read(emergencyLocationProvider).openNearbyHospitals(
              location: ref.read(emergencySessionProvider).location,
            ),
      ),
      EmergencyActionButton(
        label: 'WhatsApp Message + Location',
        subtitle: 'Send alert & live location link via WhatsApp',
        icon: Icons.chat,
        filled: false,
        onTap: () => _shareAlertWhatsApp(context, ref),
      ),
      EmergencyActionButton(
        label: 'Call Ambulance',
        subtitle: EmergencyConstants.testingMode
            ? '${EmergencyConstants.ambulance} (disabled in testing)'
            : EmergencyConstants.ambulance,
        icon: Icons.local_hospital,
        filled: false,
        onTap: () => _serviceCall(context, EmergencyConstants.ambulance, 'Ambulance'),
      ),
    ];
  }

  List<Widget> _minorActions(BuildContext context) {
    return [
      EmergencyActionButton(
        label: 'Book Normal Consultation',
        subtitle: 'Schedule a non-emergency visit',
        icon: Icons.calendar_month,
        onTap: () => context.push(RouteNames.doctors),
      ),
      EmergencyActionButton(
        label: 'Call Ambulance',
        subtitle: EmergencyConstants.testingMode
            ? 'Disabled in testing'
            : 'If condition worsens',
        icon: Icons.local_hospital,
        filled: false,
        onTap: () => _serviceCall(context, EmergencyConstants.ambulance, 'Ambulance'),
      ),
    ];
  }
}
