import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/profile_options.dart';
import '../../l10n/l10n_extension.dart';
import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/healthcare/premium_healthcare_theme.dart';
import '../providers/onboarding_provider.dart';

class OnboardingProfileStep extends ConsumerStatefulWidget {
  const OnboardingProfileStep({super.key});

  @override
  ConsumerState<OnboardingProfileStep> createState() => _OnboardingProfileStepState();
}

class _OnboardingProfileStepState extends ConsumerState<OnboardingProfileStep> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  bool _saving = false;
  bool _ready = false;
  String? _error;
  bool _emailVerified = false;
  bool _sendingEmailOtp = false;

  static final _inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
  static const _menuMaxHeight = 220.0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  void _applyPrefill(PatientModel? p, dynamic authUser) {
    final name = (p?.name.trim().isNotEmpty == true ? p!.name : authUser?.name) ?? '';
    _name.text = name;
    _email.text = p?.email ?? authUser?.email ?? '';
    _emailVerified = p?.emailVerified ?? _emailVerified;
    _phone.text = ProfileOptions.sanitize(p?.phone) ?? ProfileOptions.sanitize(authUser?.phone) ?? '';
    _gender = ProfileOptions.normalizeGender(p?.gender);
    _bloodGroup = ProfileOptions.normalizeBloodGroup(p?.bloodGroup);
    _address.text = p?.address ?? '';
    final dobRaw = ProfileOptions.sanitize(p?.dob);
    if (dobRaw != null) {
      _dob = DateTime.tryParse(dobRaw) ?? _tryParseDob(dobRaw);
    }
  }

  DateTime? _tryParseDob(String raw) {
    for (final pattern in ['yyyy-MM-dd', 'dd-MM-yyyy', 'dd/MM/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    return null;
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
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
  }

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
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _gender == null ||
        _bloodGroup == null ||
        _dob == null) {
      setState(() => _error = l10n.commonError);
      return;
    }
    if (!_emailVerified) {
      // Don't silently block — actively guide the user through OTP verification.
      await _sendEmailOtp();
      if (!mounted || !_emailVerified) {
        if (mounted) {
          setState(() => _error ??= 'Please verify your email to continue');
        }
        return;
      }
    }

    setState(() => _saving = true);

    PatientModel profile;
    try {
      profile = await ref.read(patientProfileProvider.future);
    } catch (_) {
      final user = ref.read(authProvider).user;
      profile = PatientModel(
        id: user?.id ?? '',
        name: _name.text.trim(),
        email: user?.email ?? _email.text,
        phone: _phone.text.trim(),
      );
    }

    final updated = profile.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      bloodGroup: _bloodGroup,
      dob: DateFormat('yyyy-MM-dd').format(_dob!),
      address: _address.text.trim().isEmpty ? profile.address : _address.text.trim(),
    );

    // Advance to welcome screen immediately.
    await ref.read(onboardingProvider.notifier).completeProfile();

    try {
      await ref.read(onboardingServiceProvider).updateProfile(updated);
      ref.invalidate(patientProfileProvider);
    } catch (e) {
      // Profile saved on server may fail; user still continues — log for support.
      debugPrint('Onboarding profile sync: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Render the form instantly using whatever we already have (auth user +
    // any cached profile) so step 7 -> 8 is never blocked by a network call.
    final authUser = ref.read(authProvider).user;
    final cached = ref.read(patientProfileProvider).valueOrNull;
    _applyPrefill(cached, authUser);
    _ready = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Background refresh — fills any missing fields and the email-verified flag
  /// without ever blocking the UI.
  Future<void> _bootstrap() async {
    try {
      final p = await ref
          .read(patientProfileProvider.future)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        if (p.emailVerified) _emailVerified = true;
        if (_email.text.trim().isEmpty) _email.text = p.email ?? _email.text;
        if (_name.text.trim().isEmpty && p.name.trim().isNotEmpty) _name.text = p.name;
        _phone.text = _phone.text.trim().isEmpty
            ? (ProfileOptions.sanitize(p.phone) ?? _phone.text)
            : _phone.text;
        _gender ??= ProfileOptions.normalizeGender(p.gender);
        _bloodGroup ??= ProfileOptions.normalizeBloodGroup(p.bloodGroup);
        if (_address.text.trim().isEmpty) _address.text = p.address ?? _address.text;
        if (_dob == null) {
          final dobRaw = ProfileOptions.sanitize(p.dob);
          if (dobRaw != null) _dob = DateTime.tryParse(dobRaw) ?? _tryParseDob(dobRaw);
        }
      });
    } catch (_) {
      // Offline / slow backend — the form is already usable, so just continue.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumHealthcareTheme.background(context),
      body: SafeArea(
        child: _ready
            ? _form()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _form() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingStep8of8, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.secondaryBlue)),
          const SizedBox(height: 8),
          Text(l10n.onboardingCompleteProfile, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(context))),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingCompleteProfileDesc,
            style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: PremiumHealthcareTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
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
    );
  }

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
            child: Text(
              'We\'ll email you a 6-digit code to confirm your address.',
              style: GoogleFonts.inter(fontSize: 12, color: PremiumHealthcareTheme.textSecondary(context)),
            ),
          ),
      ],
    );
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Verify your email', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: PremiumHealthcareTheme.text(sheetCtx))),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the 6-digit code sent to ${_email.text}',
                    style: GoogleFonts.inter(fontSize: 13, color: PremiumHealthcareTheme.textSecondary(sheetCtx)),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w700, color: PremiumHealthcareTheme.text(sheetCtx)),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '------',
                      errorText: error,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: verifying ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumHealthcareTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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

  Widget _field(String label, TextEditingController c, {TextInputType? keyboard, bool readOnly = false}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: _decoration(label),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('gender-$_gender'),
      initialValue: _gender,
      isExpanded: true,
      menuMaxHeight: _menuMaxHeight,
      decoration: _decoration('${context.l10n.authGender} *', hint: context.l10n.authGender),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: PremiumHealthcareTheme.white(context),
      iconEnabledColor: PremiumHealthcareTheme.textSecondary(context),
      items: ProfileOptions.genderItems
          .map((e) => DropdownMenuItem(
                value: e.$1,
                child: Text(e.$2, style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context))),
              ))
          .toList(),
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _bloodDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('blood-$_bloodGroup'),
      initialValue: _bloodGroup,
      isExpanded: true,
      menuMaxHeight: _menuMaxHeight,
      decoration: _decoration('${context.l10n.profileBloodGroup} *', hint: context.l10n.profileBloodGroup),
      style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context)),
      borderRadius: BorderRadius.circular(12),
      dropdownColor: PremiumHealthcareTheme.white(context),
      iconEnabledColor: PremiumHealthcareTheme.textSecondary(context),
      items: ProfileOptions.bloodGroups
          .map((g) => DropdownMenuItem(
                value: g,
                child: Text(g, style: GoogleFonts.inter(fontSize: 14, color: PremiumHealthcareTheme.text(context))),
              ))
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
        decoration: _decoration('${context.l10n.authDateOfBirth} *').copyWith(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _dob == null ? PremiumHealthcareTheme.textSecondary(context) : PremiumHealthcareTheme.text(context),
          ),
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 6),
          Text(
            'Verified',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
          ),
        ],
      ),
    );
  }
}
