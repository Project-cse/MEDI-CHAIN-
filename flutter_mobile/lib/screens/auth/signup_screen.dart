import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../services/google_auth_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/validators.dart';
import '../../widgets/animations/healthcare_motion.dart';
import '../../widgets/animations/morph_action_button.dart';
import '../../widgets/animations/morphing_button.dart';
import '../../widgets/animations/validation_shake.dart';
import '../../widgets/animations/success_celebration.dart';
import '../../widgets/animations/wizard_progress_bar.dart';
import '../../widgets/auth/auth_input.dart';
import '../../widgets/auth/brand_logo_mark.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/auth/login_screen_shell.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../widgets/common/app_snackbar.dart';

/// Multi-step registration wizard — 4 steps with horizontal slide animations.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _terms = false;
  int _step = 0;
  MorphButtonState _btnState = MorphButtonState.idle;
  bool _googleLoading = false;
  bool _showSuccess = false;
  bool _shakeFields = false;

  static const _stepLabels = [
    'Personal Information',
    'Contact Information',
    'Security & Verification',
    'Success',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (Validators.requiredField(_name.text, 'Name') != null) {
          AppSnackbar.show(context, 'Enter your full name');
          return false;
        }
        if (_dob == null) {
          AppSnackbar.show(context, 'Select date of birth');
          return false;
        }
        if (_gender == null) {
          AppSnackbar.show(context, 'Select gender');
          return false;
        }
        return true;
      case 1:
        if (Validators.email(_email.text) != null) {
          AppSnackbar.show(context, 'Enter a valid email');
          return false;
        }
        if (Validators.phone(_phone.text) != null) {
          AppSnackbar.show(context, 'Enter a valid phone number');
          return false;
        }
        return true;
      case 2:
        if (Validators.password(_password.text) != null) {
          AppSnackbar.show(context, 'Password must be at least 6 characters');
          return false;
        }
        if (Validators.confirmPassword(_confirm.text, _password.text) != null) {
          AppSnackbar.show(context, 'Passwords do not match');
          return false;
        }
        if (!_terms) {
          AppSnackbar.show(context, 'Please accept Terms & Conditions');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    _submit();
  }

  void _back() {
    if (_step == 0) {
      context.go(RouteNames.login);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _btnState = MorphButtonState.loading);
    await ref.read(authProvider.notifier).signup(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          gender: _gender,
          dob: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
        );
    final state = ref.read(authProvider);
    if (!mounted) return;
    if (state.status == AuthStatus.authenticated) {
      setState(() {
        _btnState = MorphButtonState.success;
        _showSuccess = true;
        _step = 3;
      });
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (mounted) context.go(RouteNames.dashboard);
    } else {
      setState(() => _btnState = MorphButtonState.idle);
      if (state.error != null) AppSnackbar.show(context, state.error!);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final ok = await ref.read(authProvider.notifier).loginWithGoogle();
      if (!mounted || !ok) return;
      context.go(RouteNames.dashboard);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppException ? e.message : e.toString();
      if (msg != 'Sign-in cancelled') AppSnackbar.show(context, msg);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginScreenShell(
      child: Column(
        children: [
          const BrandLogoMark(),
          WizardProgressBar(step: _step, totalSteps: 4, labels: _stepLabels),
          const SizedBox(height: 8),
          SizedBox(
            height: _showSuccess ? 380 : 420,
            child: PageTransitionSwitcher(
              duration: HealthcareMotion.standard,
              reverse: false,
              transitionBuilder: (child, animation, secondaryAnimation) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_step),
                child: _showSuccess
                    ? _successStep()
                    : ValidationShake(
                        shake: _shakeFields,
                        onComplete: () {
                          if (mounted) setState(() => _shakeFields = false);
                        },
                        child: _stepCard(_currentStepBody()),
                      ),
              ),
            ),
          ),
          if (!_showSuccess) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _back,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: MorphingButton(
                      label: _step == 2 ? 'Create Account' : 'Next',
                      state: _btnState,
                      onPressed: _btnState == MorphButtonState.idle ? _next : null,
                    ),
                  ),
                ],
              ),
            ).authFormEnter(index: 4),
            if (_step == 0 && GoogleAuthService.setupHint == null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GoogleSignInButton(
                  loading: _googleLoading,
                  onPressed: _googleLoading ? null : _googleSignIn,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (!_showSuccess) const EmergencyHelpButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _currentStepBody() {
    switch (_step) {
      case 0:
        return _personalStep();
      case 1:
        return _contactStep();
      case 2:
        return _securityStep();
      default:
        return _personalStep();
    }
  }

  Widget _stepCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.loginCard,
      ),
      child: SingleChildScrollView(child: child),
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tell us about yourself', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        AuthInput(label: 'Full Name', icon: Icons.person_outline, controller: _name),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _dob == null ? 'Date of Birth' : DateFormat('dd MMM yyyy').format(_dob!),
            style: GoogleFonts.poppins(),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDob,
        ),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  Widget _contactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How can we reach you?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        AuthInput(label: 'Email', icon: Icons.mail_outline, controller: _email, keyboardType: TextInputType.emailAddress),
        AuthInput(label: 'Phone', icon: Icons.phone_outlined, controller: _phone, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _securityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Secure your account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 16),
        AuthInput(label: 'Password', icon: Icons.lock_outline, controller: _password, obscureText: true),
        AuthInput(label: 'Confirm Password', icon: Icons.lock_outline, controller: _confirm, obscureText: true),
        CheckboxListTile(
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          title: Text('I agree to Terms & Conditions', style: GoogleFonts.poppins(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _successStep() {
    return Center(
      child: SuccessCelebration(
        title: 'Welcome to MEDCLUES',
        subtitle: 'Your account is ready. Taking you to your dashboard…',
      ),
    );
  }
}
