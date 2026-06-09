import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/emergency_home_button.dart';

import '../../../widgets/common/app_snackbar.dart';
import '../emergency_constants.dart';
import '../models/emergency_contact_model.dart';
import '../models/emergency_settings_model.dart';
import '../providers/emergency_provider.dart';

class EmergencySettingsScreen extends ConsumerStatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  ConsumerState<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends ConsumerState<EmergencySettingsScreen> {
  final _c1Name = TextEditingController();
  final _c1Phone = TextEditingController();
  final _c1Relation = TextEditingController();
  final _c2Name = TextEditingController();
  final _c2Phone = TextEditingController();
  final _c2Relation = TextEditingController();
  final _bloodGroup = TextEditingController();
  final _allergies = TextEditingController();
  final _diseases = TextEditingController();
  final _medications = TextEditingController();

  int _timerSeconds = 30;
  bool _voiceSos = false;
  bool _tripleTap = false;
  bool _shakeSos = false;
  bool _autoLocation = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProvider());
  }

  @override
  void dispose() {
    _c1Name.dispose();
    _c1Phone.dispose();
    _c1Relation.dispose();
    _c2Name.dispose();
    _c2Phone.dispose();
    _c2Relation.dispose();
    _bloodGroup.dispose();
    _allergies.dispose();
    _diseases.dispose();
    _medications.dispose();
    super.dispose();
  }

  Future<void> _loadFromProvider() async {
    final settings = await ref.read(emergencySettingsProvider.future);
    if (!mounted) return;
    _applyToForm(settings);
  }

  void _applyToForm(EmergencySettingsModel s) {
    _c1Name.text = s.relativeContact1?.name ?? '';
    _c1Phone.text = s.relativeContact1?.phone ?? '';
    _c1Relation.text = s.relativeContact1?.relation ?? '';
    _c2Name.text = s.relativeContact2?.name ?? '';
    _c2Phone.text = s.relativeContact2?.phone ?? '';
    _c2Relation.text = s.relativeContact2?.relation ?? '';
    _bloodGroup.text = s.bloodGroup ?? '';
    _allergies.text = s.allergies ?? '';
    _diseases.text = s.existingDiseases ?? '';
    _medications.text = s.currentMedications ?? '';
    _timerSeconds = s.autoSosTimerSeconds;
    _voiceSos = s.voiceSosEnabled;
    _tripleTap = s.tripleTapSosEnabled;
    _shakeSos = s.shakeSosEnabled;
    _autoLocation = s.autoLocationSharing;
    setState(() {});
  }

  bool get _contact1Partial =>
      _c1Name.text.trim().isNotEmpty != _c1Phone.text.trim().isNotEmpty;

  bool get _contact2Partial =>
      _c2Name.text.trim().isNotEmpty != _c2Phone.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_contact1Partial) {
      AppSnackbar.show(context, 'Contact 1: enter both name and phone number');
      return;
    }
    if (_contact2Partial) {
      AppSnackbar.show(context, 'Contact 2: enter both name and phone number');
      return;
    }

    final storage = ref.read(emergencyStorageProvider);
    EmergencyContactModel? c1;
    EmergencyContactModel? c2;
    try {
      c1 = storage.parseContact(_c1Name.text, _c1Phone.text, _c1Relation.text);
      c2 = storage.parseContact(_c2Name.text, _c2Phone.text, _c2Relation.text);
    } on ArgumentError catch (e) {
      AppSnackbar.show(context, e.message?.toString() ?? 'Invalid contact details');
      return;
    }

    setState(() => _saving = true);
    try {
      final settings = EmergencySettingsModel(
        relativeContact1: c1,
        relativeContact2: c2,
        bloodGroup: _bloodGroup.text.trim().isEmpty ? null : _bloodGroup.text.trim(),
        allergies: _allergies.text.trim().isEmpty ? null : _allergies.text.trim(),
        existingDiseases: _diseases.text.trim().isEmpty ? null : _diseases.text.trim(),
        currentMedications: _medications.text.trim().isEmpty ? null : _medications.text.trim(),
        autoSosTimerSeconds: _timerSeconds,
        voiceSosEnabled: _voiceSos,
        tripleTapSosEnabled: _tripleTap,
        shakeSosEnabled: _shakeSos,
        autoLocationSharing: _autoLocation,
      );

      await ref.read(emergencySettingsProvider.notifier).save(settings);
      await ref.read(emergencySettingsProvider.notifier).reload();
      final verified = ref.read(emergencySettingsProvider).value ?? settings;

      if (!mounted) return;
      final count = verified.savedContacts.length;
      AppSnackbar.show(
        context,
        count == 0
            ? 'Settings saved (no relative contacts yet)'
            : 'Settings saved — $count relative contact${count == 1 ? '' : 's'} stored',
        success: true,
      );
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Could not save settings: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(emergencySettingsProvider);

    return Scaffold(
      backgroundColor: EmergencyConstants.emergencyBg,
      appBar: AppBar(
        backgroundColor: EmergencyConstants.emergencyRed,
        foregroundColor: Colors.white,
        title: const Text('Emergency Settings'),
        leading: const EmergencyHomeButton(clearSession: false),
      ),
      body: settingsAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Relative Contacts'),
                Text(
                  'Both name and phone are required for each contact.',
                  style: GoogleFonts.poppins(fontSize: 12, color: EmergencyConstants.emergencyText),
                ),
                const SizedBox(height: 8),
                _contactFields('Contact 1', _c1Name, _c1Phone, _c1Relation),
                _contactFields('Contact 2', _c2Name, _c2Phone, _c2Relation),
                _sectionTitle('Medical Info'),
                _field('Blood Group', _bloodGroup, hint: 'e.g. O+'),
                _field('Allergies', _allergies, maxLines: 2),
                _field('Existing Diseases', _diseases, maxLines: 2),
                _field('Current Medications', _medications, maxLines: 2),
                _sectionTitle('SOS Preferences'),
                _switchTile(
                  'Auto SOS Timer',
                  'Countdown before automatic SOS (${_timerSeconds}s)',
                  true,
                  onChanged: null,
                ),
                Slider(
                  value: _timerSeconds.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 11,
                  label: '${_timerSeconds}s',
                  activeColor: EmergencyConstants.emergencyRed,
                  onChanged: (v) => setState(() => _timerSeconds = v.round()),
                ),
                _switchTile('Voice SOS', 'Trigger SOS with voice command', _voiceSos,
                    onChanged: (v) => setState(() => _voiceSos = v)),
                _switchTile('Triple Tap SOS', 'Triple-tap power button pattern', _tripleTap,
                    onChanged: (v) => setState(() => _tripleTap = v)),
                _switchTile('Shake SOS', 'Shake device to trigger SOS', _shakeSos,
                    onChanged: (v) => setState(() => _shakeSos = v)),
                _switchTile('Auto Location Sharing', 'Share GPS when SOS activates', _autoLocation,
                    onChanged: (v) => setState(() => _autoLocation = v)),
                _sectionTitle('Default Emergency Numbers'),
                _numberTile('Ambulance', EmergencyConstants.ambulance),
                _numberTile('Police', '${EmergencyConstants.police} / ${EmergencyConstants.policeAlt}'),
                _numberTile('Fire', EmergencyConstants.fire),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: EmergencyConstants.emergencyRed,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save Settings',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: EmergencyConstants.emergencyRedDark),
      ),
    );
  }

  Widget _contactFields(String label, TextEditingController name, TextEditingController phone, TextEditingController relation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field('Name *', name),
            _field('Phone *', phone, keyboard: TextInputType.phone),
            _field('Relation', relation, hint: 'e.g. Spouse'),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint, int maxLines = 1, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, {required ValueChanged<bool>? onChanged}) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
      value: value,
      activeThumbColor: EmergencyConstants.emergencyRed,
      onChanged: onChanged,
    );
  }

  Widget _numberTile(String label, String number) {
    return ListTile(
      leading: const Icon(Icons.phone, color: EmergencyConstants.emergencyRed),
      title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      trailing: Text(number, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
    );
  }
}
