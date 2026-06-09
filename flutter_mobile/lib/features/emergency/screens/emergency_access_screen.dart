import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../onboarding/onboarding_tour_steps.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../routes/route_names.dart';
import '../emergency_constants.dart';
import '../models/emergency_case_model.dart';
import '../providers/emergency_provider.dart';
import '../services/emergency_sos_timer_service.dart';
import '../utils/emergency_symptom_utils.dart';
import '../widgets/emergency_action_button.dart';
import '../widgets/emergency_home_button.dart';

enum _AccessPhase { initial, symptoms, helper }

/// Entry screen — works without login. Starts auto-SOS countdown.
class EmergencyAccessScreen extends ConsumerStatefulWidget {
  const EmergencyAccessScreen({super.key});

  @override
  ConsumerState<EmergencyAccessScreen> createState() => _EmergencyAccessScreenState();
}

class _EmergencyAccessScreenState extends ConsumerState<EmergencyAccessScreen> {
  final _timer = EmergencySosTimerService();
  int _secondsLeft = EmergencyConstants.defaultTimerSeconds;
  _AccessPhase _phase = _AccessPhase.initial;
  bool _busy = false;
  bool _timerActive = true;

  bool get _inOnboardingTour {
    final ob = ref.read(onboardingProvider);
    return ob.phase == OnboardingPhase.tour &&
        ob.tourIndex == onboardingTourSteps.length - 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inOnboardingTour) return;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    if (!_timerActive) return;
    final settings = await ref.read(emergencySettingsProvider.future);
    final secs = settings.autoSosTimerSeconds;
    if (!mounted || !_timerActive) return;
    setState(() => _secondsLeft = secs);
    _timer.start(
      seconds: secs,
      onTick: (s) {
        if (mounted && _timerActive) setState(() => _secondsLeft = s);
      },
      onComplete: _onTimerAutoSos,
    );
  }

  void _stopTimer() {
    if (!_timerActive) return;
    _timer.cancel();
    _timerActive = false;
    if (mounted) setState(() {});
  }

  Future<void> _onTimerAutoSos() async {
    if (!mounted || _busy || !_timerActive) return;
    await _activateAndGo(
      triggerType: EmergencyTriggerType.timerAutoSos,
      severity: EmergencySeverity.critical,
    );
  }

  Future<void> _activateAndGo({
    required EmergencyTriggerType triggerType,
    required EmergencySeverity severity,
    List<String> symptoms = const [],
    bool isHelperFlow = false,
  }) async {
    if (_busy) return;
    _stopTimer();
    setState(() => _busy = true);
    try {
      await ref.read(emergencySessionProvider.notifier).activateSos(
            triggerType: triggerType,
            severity: severity,
            symptoms: symptoms,
            isHelperFlow: isHelperFlow,
          );
      if (!mounted) return;
      context.push(RouteNames.emergencyActive);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onCritical() async {
    _stopTimer();
    await _activateAndGo(
      triggerType: EmergencyTriggerType.criticalButton,
      severity: EmergencySeverity.critical,
    );
  }

  void _onCanRespond() {
    _stopTimer();
    setState(() => _phase = _AccessPhase.symptoms);
  }

  void _onHelpSomeoneElse() {
    _stopTimer();
    setState(() => _phase = _AccessPhase.helper);
  }

  void _openSettings() {
    _stopTimer();
    context.push(RouteNames.emergencySettings);
  }

  Future<void> _onSymptomSelected(String symptom, {bool isHelper = false}) async {
    _stopTimer();
    final severity = classifySymptom(symptom);
    await _activateAndGo(
      triggerType: triggerForSymptom(severity, isHelper: isHelper),
      severity: severity,
      symptoms: [symptom],
      isHelperFlow: isHelper,
    );
  }

  Future<void> _onHelperSeverity(EmergencySeverity severity) async {
    _stopTimer();
    await _activateAndGo(
      triggerType: triggerForSymptom(severity, isHelper: true),
      severity: severity,
      isHelperFlow: true,
    );
  }

  void _onBackToInitial() {
    _stopTimer();
    setState(() => _phase = _AccessPhase.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergencyConstants.emergencyBg,
      appBar: AppBar(
        backgroundColor: EmergencyConstants.emergencyRed,
        foregroundColor: Colors.white,
        title: const Text('Emergency'),
        leading: EmergencyHomeButton(onBeforeExit: _stopTimer),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator(color: EmergencyConstants.emergencyRed))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: switch (_phase) {
                  _AccessPhase.initial => _buildInitial(),
                  _AccessPhase.symptoms => _buildSymptoms(isHelper: false),
                  _AccessPhase.helper => _buildHelper(),
                },
              ),
            ),
    );
  }

  Widget _buildInitial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EmergencyConstants.emergencyRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.emergency, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                'Emergency Mode Activated',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you able to respond?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _timerBanner(),
        const SizedBox(height: 8),
        Text(
          _timerActive
              ? 'If you do nothing, SOS will activate automatically.'
              : 'Auto-SOS timer stopped. Choose an option below.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: EmergencyConstants.emergencyText),
        ),
        const Spacer(),
        EmergencyActionButton(
          label: 'I Am Critical',
          subtitle: 'Immediate SOS — ambulance & contacts',
          icon: Icons.warning_amber_rounded,
          onTap: _onCritical,
        ),
        EmergencyActionButton(
          label: 'I Can Respond',
          subtitle: 'Select symptoms for guided help',
          icon: Icons.healing,
          filled: false,
          onTap: _onCanRespond,
        ),
        EmergencyActionButton(
          label: 'Help Someone Else',
          subtitle: 'Assist another person in distress',
          icon: Icons.people_alt,
          filled: false,
          onTap: _onHelpSomeoneElse,
        ),
      ],
    );
  }

  Widget _timerBanner() {
    final stopped = !_timerActive;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stopped
              ? Colors.grey.shade400
              : EmergencyConstants.emergencyRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            stopped ? Icons.timer_off : Icons.timer,
            color: stopped ? Colors.grey : EmergencyConstants.emergencyRed,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            stopped ? 'Timer stopped' : 'Auto SOS in $_secondsLeft s',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: stopped ? Colors.grey.shade700 : EmergencyConstants.emergencyRedDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptoms({required bool isHelper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What symptoms are you experiencing?',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: allSymptoms
                .map(
                  (s) => EmergencyActionButton(
                    label: s,
                    icon: Icons.medical_services_outlined,
                    filled: EmergencyConstants.criticalSymptoms.contains(s),
                    onTap: () => _onSymptomSelected(s, isHelper: isHelper),
                  ),
                )
                .toList(),
          ),
        ),
        TextButton(
          onPressed: _onBackToInitial,
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildHelper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How severe is their condition?',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        EmergencyActionButton(
          label: 'Critical',
          subtitle: 'Call ambulance immediately',
          icon: Icons.warning_amber_rounded,
          onTap: () => _onHelperSeverity(EmergencySeverity.critical),
        ),
        EmergencyActionButton(
          label: 'Moderate',
          subtitle: 'Video doctor & hospitals',
          icon: Icons.video_call,
          filled: false,
          onTap: () => _onHelperSeverity(EmergencySeverity.moderate),
        ),
        EmergencyActionButton(
          label: 'Minor',
          subtitle: 'Suggest normal consultation',
          icon: Icons.info_outline,
          filled: false,
          onTap: () => _onHelperSeverity(EmergencySeverity.minor),
        ),
        const Spacer(),
        TextButton(
          onPressed: _onBackToInitial,
          child: const Text('Back'),
        ),
      ],
    );
  }
}
