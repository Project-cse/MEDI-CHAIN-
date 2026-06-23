import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/profile_options.dart';
import '../../features/emergency/models/emergency_contact_model.dart';
import '../../features/emergency/providers/emergency_provider.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../routes/route_names.dart';
import '../../utils/validators.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../providers/onboarding_provider.dart';

/// Single, robust "Finish your setup" screen that replaces the two fragile
/// onboarding overlay steps (Emergency + Profile). It renders instantly from
/// cached data, validates everything once, and saves locally + in the
/// background so a slow/cold backend can never freeze the flow.
class OnboardingSetupStep extends ConsumerStatefulWidget {
  const OnboardingSetupStep({super.key});

  @override
  ConsumerState<OnboardingSetupStep> createState() => _OnboardingSetupStepState();
}

class _OnboardingSetupStepState extends ConsumerState<OnboardingSetupStep> {
  // Profile
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  bool _emailVerified = false;
  bool _sendingEmailOtp = false;

  // Emergency contact
  final _ecName = TextEditingController();
  final _ecRelation = TextEditingController();
  final _ecPhone = TextEditingController();

  bool _saving = false;
  String? _error;

  static final _inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  @override
  void initState() {
    super.initState();
    final authUser = ref.read(authProvider).user;
    final cached = ref.read(patientProfileProvider).valueOrNull;
    _applyPrefill(cached, authUser);
    // Prefill an existing emergency contact if we already have one locally.
    final saved = ref.read(emergencySettingsProvider).valueOrNull?.savedContacts;
    if (saved != null && saved.isNotEmpty) {
      final c = saved.first;
      _ecName.text = c.name;
      _ecPhone.text = c.phone;
      _ecRelation.text = c.relation ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _applyPrefill(PatientModel? p, dynamic authUser) {
    _name.text = (p?.name.trim().isNotEmpty == true ? p!.name : authUser?.name) ?? '';
    _email.text = p?.email ?? authUser?.email ?? '';
    _emailVerified = p?.emailVerified ?? _emailVerified;
    _phone.text = ProfileOptions.sanitize(p?.phone) ?? ProfileOptions.sanitize(authUser?.phone) ?? '';
    _gender = ProfileOptions.normalizeGender(p?.gender);
    _bloodGroup = ProfileOptions.normalizeBloodGroup(p?.bloodGroup);
    _address.text = p?.address ?? '';
    final dobRaw = ProfileOptions.sanitize(p?.dob);
    if (dobRaw != null) _dob = DateTime.tryParse(dobRaw) ?? _tryParseDob(dobRaw);
  }

  DateTime? _tryParseDob(String raw) {
    for (final pattern in ['yyyy-MM-dd', 'dd-MM-yyyy', 'dd/MM/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  /// Background refresh — fills missing fields + the verified flag, never blocks.
  Future<void> _bootstrap() async {
    try {
      final p = await ref.read(patientProfileProvider.future).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        if (p.emailVerified) _emailVerified = true;
        if (_email.text.trim().isEmpty && p.email.trim().isNotEmpty) _email.text = p.email;
        if (_name.text.trim().isEmpty && p.name.trim().isNotEmpty) _name.text = p.name;
        if (_phone.text.trim().isEmpty) _phone.text = ProfileOptions.sanitize(p.phone) ?? _phone.text;
        _gender ??= ProfileOptions.normalizeGender(p.gender);
        _bloodGroup ??= ProfileOptions.normalizeBloodGroup(p.bloodGroup);
        if (_address.text.trim().isEmpty) _address.text = p.address ?? _address.text;
        if (_dob == null) {
          final dobRaw = ProfileOptions.sanitize(p.dob);
          if (dobRaw != null) _dob = DateTime.tryParse(dobRaw) ?? _tryParseDob(dobRaw);
        }
      });
    } catch (_) {
      // Offline / slow backend — form already usable.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    _ecName.dispose();
    _ecRelation.dispose();
    _ecPhone.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: PremiumHealthcareTheme.white(context),
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: PremiumHealthcareTheme.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: PremiumHealthcareTheme.primaryBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: PremiumHealthcareTheme.text(context),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _error = null);

    // 1. Profile validation
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _gender == null ||
        _bloodGroup == null ||
        _dob == null) {
      setState(() => _error = 'Please complete all required profile fields (marked *).');
      return;
    }

    // 2. Emergency contact validation
    final nameErr = Validators.emergencyContactName(_ecName.text, l10n);
    final phoneErr = Validators.emergencyContactPhone(_ecPhone.text, l10n);
    if (nameErr != null || phoneErr != null) {
      setState(() => _error = nameErr ?? phoneErr);
      return;
    }
    if (_ecRelation.text.trim().isEmpty) {
      setState(() => _error = 'Please add the emergency contact\'s relationship.');
      return;
    }

    // 3. Email must be verified (Google sign-in is auto-verified).
    if (!_emailVerified) {
      await _sendEmailOtp();
      if (!mounted || !_emailVerified) {
        if (mounted) setState(() => _error ??= 'Please verify your email to continue.');
        return;
      }
    }

    setState(() => _saving = true);

    // Build profile from in-memory data — never block on a network fetch.
    final user = ref.read(authProvider).user;
    final base = ref.read(patientProfileProvider).valueOrNull ??
        PatientModel(
          id: user?.id ?? '',
          name: _name.text.trim(),
          email: user?.email ?? _email.text,
          phone: _phone.text.trim(),
        );
    final updatedProfile = base.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      bloodGroup: _bloodGroup,
      dob: DateFormat('yyyy-MM-dd').format(_dob!),
      address: _address.text.trim().isEmpty ? base.address : _address.text.trim(),
    );

    final contact = EmergencyContactModel(
      name: _ecName.text.trim(),
      phone: _ecPhone.text.trim(),
      relation: _ecRelation.text.trim(),
    );

    final service = ref.read(onboardingServiceProvider);

    // Save the emergency contact locally first (with a guard so it can't hang),
    // then sync everything to the server in the background.
    try {
      await ref
          .read(emergencySettingsProvider.notifier)
          .upsertPrimaryContact(contact)
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    unawaited(service
        .addEmergencyContact(name: contact.name, phone: contact.phone, relation: contact.relation ?? '')
        .catchError((_) {}));
    unawaited(service.updateProfile(updatedProfile).then((_) {
      ref.invalidate(patientProfileProvider);
    }).catchError((e) {
      debugPrint('Onboarding profile sync: $e');
    }));

    // Finish onboarding and go straight to the home screen. This never blocks
    // on the network, so "Complete Setup" always lands on the dashboard.
    await ref.read(onboardingProvider.notifier).finishOnboarding();
    if (!mounted) return;
    context.go(RouteNames.dashboard);
  }

  Future<void> _sendEmailOtp() async {
    setState(() {
      _sendingEmailOtp = true;
      _error = null;
    });
    String? devOtp;
    try {
      devOtp = await ref.read(onboardingServiceProvider).sendEmailVerification();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      return;
    } finally {
      if (mounted) setState(() => _sendingEmailOtp = false);
    }
    if (!mounted) return;
    final verified = await _promptEmailOtp(devOtp: devOtp);
    if (verified == true && mounted) {
      setState(() {
        _emailVerified = true;
        _error = null;
      });
    }
  }

  Future<bool?> _promptEmailOtp({String? devOtp}) {
    final controller = TextEditingController(text: devOtp ?? '');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumHealthcareTheme.white(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        bool verifying = false;
        String? error;
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> submit() async {
              final code = controller.text.trim();
              if (code.length < 6) {
                setSheet(() => error = 'Enter the 6-digit code');
                return;
              }
              setSheet(() {
                verifying = true;
                error = null;
              });
              try {
                await ref.read(onboardingServiceProvider).verifyEmail(code);
                if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(true);
              } catch (e) {
                setSheet(() {
                  verifying = false;
                  error = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Verify your email', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: PremiumHealthcareTheme.text(sheetCtx))),
                  const SizedBox(height: 6),
                  Text('Enter the 6-digit code sent to ${_email.text}', style: GoogleFonts.inter(fontSize: 13, color: PremiumHealthcareTheme.textSecondary(sheetCtx))),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(sheetCtx)),
                    decoration: InputDecoration(counterText: '', hintText: '------', errorText: error, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: verifying ? null : submit,
                      style: ElevatedButton.styleFrom(backgroundColor: PremiumHealthcareTheme.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: verifying
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text('Verify', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Final step', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.secondaryBlue)),
              const SizedBox(height: 8),
              Text('Finish Your Setup', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(context))),
              const SizedBox(height: 8),
              Text(
                'Add your details and one emergency contact so doctors can serve you better. You can edit these anytime in Settings.',
                style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: PremiumHealthcareTheme.textSecondary(context)),
              ),
              const SizedBox(height: 22),

              _sectionTitle('Your Profile'),
              const SizedBox(height: 12),
              _field('${l10n.authFullName} *', _name),
              const SizedBox(height: 12),
              _emailField(),
              const SizedBox(height: 12),
              _field('${l10n.authPhone} *', _phone, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _genderDropdown(),
              const SizedBox(height: 12),
              _dobField(),
              const SizedBox(height: 12),
              _bloodDropdown(),
              const SizedBox(height: 12),
              _field(l10n.profileAddress, _address),

              const SizedBox(height: 26),
              _sectionTitle('Emergency Contact'),
              const SizedBox(height: 4),
              Text(
                'One person we can alert in an emergency.',
                style: GoogleFonts.inter(fontSize: 13, color: PremiumHealthcareTheme.textSecondary(context)),
              ),
              const SizedBox(height: 12),
              _field('${l10n.authFullName} *', _ecName),
              const SizedBox(height: 12),
              _field('${l10n.bookingRelationship} *', _ecRelation, hint: l10n.emergencyRelationHint),
              const SizedBox(height: 12),
              _field('${l10n.authPhone} *', _ecPhone, keyboard: TextInputType.phone),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
                  child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB91C1C))),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumHealthcareTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.onboardingCompleteSetup, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: PremiumHealthcareTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(context))),
        ],
      );

  Widget _emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _field(context.l10n.authEmail, _email, readOnly: true)),
            const SizedBox(width: 10),
            if (_emailVerified)
              const _VerifiedChip()
            else
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _sendingEmailOtp ? null : _sendEmailOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumHealthcareTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sendingEmailOtp
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Verify', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
          ],
        ),
        if (!_emailVerified)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text("We'll email you a 6-digit code to confirm your address.", style: GoogleFonts.inter(fontSize: 12, color: PremiumHealthcareTheme.textSecondary(context))),
          ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c, {TextInputType? keyboard, bool readOnly = false, String? hint}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: _decoration(label, hint: hint),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('gender-$_gender'),
      initialValue: _gender,
      isExpanded: true,
      menuMaxHeight: 220,
      decoration: _decoration('${context.l10n.authGender} *', hint: context.l10n.authGender),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: PremiumHealthcareTheme.white(context),
      items: ProfileOptions.genderItems
          .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2, style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)))))
          .toList(),
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _bloodDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('blood-$_bloodGroup'),
      initialValue: _bloodGroup,
      isExpanded: true,
      menuMaxHeight: 220,
      decoration: _decoration('${context.l10n.profileBloodGroup} *', hint: context.l10n.profileBloodGroup),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: PremiumHealthcareTheme.white(context),
      items: ProfileOptions.bloodGroups
          .map((g) => DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)))))
          .toList(),
      onChanged: (v) => setState(() => _bloodGroup = v),
    );
  }

  Widget _dobField() {
    final label = _dob == null ? context.l10n.authSelectDob : DateFormat('dd MMM yyyy').format(_dob!);
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration('${context.l10n.authDateOfBirth} *').copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20)),
        child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: _dob == null ? PremiumHealthcareTheme.textSecondary(context) : PremiumHealthcareTheme.text(context))),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 6),
          Text('Verified', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
        ],
      ),
    );
  }
}
