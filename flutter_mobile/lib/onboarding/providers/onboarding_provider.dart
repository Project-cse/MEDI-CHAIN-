import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../models/onboarding_status.dart';
import '../onboarding_tour_steps.dart';
import '../services/onboarding_service.dart';

enum OnboardingPhase { loading, tour, emergency, profile, complete, done }

class OnboardingUiState {
  const OnboardingUiState({
    this.phase = OnboardingPhase.loading,
    this.status = const OnboardingStatus(),
    this.tourIndex = 0,
    this.showCompletion = false,
    this.error,
  });

  final OnboardingPhase phase;
  final OnboardingStatus status;
  final int tourIndex;
  final bool showCompletion;
  final String? error;

  bool get needsOnboarding => !status.onboardingCompleted;

  OnboardingUiState copyWith({
    OnboardingPhase? phase,
    OnboardingStatus? status,
    int? tourIndex,
    bool? showCompletion,
    String? error,
  }) {
    return OnboardingUiState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      tourIndex: tourIndex ?? this.tourIndex,
      showCompletion: showCompletion ?? this.showCompletion,
      error: error,
    );
  }
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref.watch(apiServiceProvider));
});

class OnboardingNotifier extends StateNotifier<OnboardingUiState> {
  OnboardingNotifier(this._ref) : super(const OnboardingUiState());

  final Ref _ref;

  OnboardingService get _service => _ref.read(onboardingServiceProvider);

  OnboardingPhase _phaseFor(OnboardingStatus status) {
    if (!status.tutorialCompleted) return OnboardingPhase.tour;
    if (!status.emergencyContactCompleted) return OnboardingPhase.emergency;
    if (!status.profileCompleted) return OnboardingPhase.profile;
    return OnboardingPhase.complete;
  }

  Future<void> load() async {
    if (state.phase != OnboardingPhase.done) {
      state = state.copyWith(phase: OnboardingPhase.loading, error: null);
    }
    try {
      final status = await _service.fetchStatus();
      if (!status.needsOnboarding) {
        state = OnboardingUiState(phase: OnboardingPhase.done, status: status);
        return;
      }
      final tourIndex = status.tutorialCompleted
          ? onboardingTourSteps.length
          : status.onboardingStep.clamp(0, onboardingTourSteps.length - 1);
      final phase = _phaseFor(status);
      state = OnboardingUiState(
        phase: phase,
        status: status,
        tourIndex: tourIndex,
        showCompletion: status.profileCompleted && !status.onboardingCompleted,
      );
    } catch (e) {
      state = state.copyWith(phase: OnboardingPhase.done, error: e.toString());
    }
  }

  Future<void> _persist(OnboardingStatus status) async {
    final saved = await _service.saveStatus(status);
    state = state.copyWith(status: saved);
  }

  OnboardingPhase _nextPhaseFrom(OnboardingStatus status) {
    if (!status.emergencyContactCompleted) return OnboardingPhase.emergency;
    if (!status.profileCompleted) return OnboardingPhase.profile;
    return OnboardingPhase.complete;
  }

  /// Move to the next step using the given status as the source of truth.
  /// Always advances the UI instantly and persists to the server in the
  /// background, so a slow/cold backend can never freeze the flow.
  void _applyAdvance(OnboardingStatus status) {
    final phase = _nextPhaseFrom(status);
    state = state.copyWith(
      phase: phase,
      status: status,
      showCompletion: phase == OnboardingPhase.complete,
    );
    unawaited(_service.saveStatus(status).then((saved) {
      state = state.copyWith(status: saved);
    }).catchError((_) {}));
  }

  /// After tour ends — move forward immediately from local truth. The
  /// emergency/profile steps self-skip if their data already exists on the
  /// server, so there's no need to block here on a network round-trip.
  Future<void> _advanceAfterTour() async {
    _applyAdvance(state.status);
  }

  Future<void> goToTourIndex(int index) async {
    final clamped = index.clamp(0, onboardingTourSteps.length - 1);
    final nextStatus = state.status.copyWith(onboardingStep: clamped);
    state = state.copyWith(tourIndex: clamped, phase: OnboardingPhase.tour, status: nextStatus);
  }

  Future<void> nextTourStep() async {
    if (state.tourIndex >= onboardingTourSteps.length - 1) {
      await skipTour(markTutorialComplete: true);
      return;
    }
    await goToTourIndex(state.tourIndex + 1);
  }

  Future<void> previousTourStep() async {
    if (state.tourIndex <= 0) return;
    await goToTourIndex(state.tourIndex - 1);
  }

  Future<void> skipTour({bool markTutorialComplete = true}) async {
    final next = state.status.copyWith(
      tutorialCompleted: markTutorialComplete,
      onboardingStep: onboardingTourSteps.length,
    );
    state = state.copyWith(
      status: next,
      tourIndex: onboardingTourSteps.length,
    );
    // Persist in the background so leaving the last tour step is instant.
    unawaited(_persist(next).catchError((_) {}));
    await _advanceAfterTour();
  }

  Future<void> completeEmergencyContact() async {
    // The contact (and the server-side flag) is already persisted by the
    // caller's addEmergencyContact call. Advance instantly from local truth;
    // _applyAdvance re-persists the onboarding status in the background.
    final next = state.status.copyWith(emergencyContactCompleted: true);
    _applyAdvance(next);
  }

  Future<void> completeProfile() async {
    final next = state.status.copyWith(profileCompleted: true, onboardingStep: 8);
    state = state.copyWith(
      phase: OnboardingPhase.complete,
      status: next,
      showCompletion: true,
    );
    // Persist in the background so the welcome screen shows instantly.
    unawaited(_service.saveStatus(next).then((saved) {
      state = state.copyWith(status: saved);
    }).catchError((_) {}));
  }

  Future<void> finishOnboarding() async {
    final next = state.status.copyWith(
      onboardingCompleted: true,
      tutorialCompleted: true,
      emergencyContactCompleted: true,
      profileCompleted: true,
      onboardingStep: 8,
    );
    state = OnboardingUiState(phase: OnboardingPhase.done, status: next);
    try {
      await _persist(next);
    } catch (_) {}
  }

  Future<void> resetForReplay() async {
    final reset = OnboardingStatus(
      onboardingCompleted: false,
      tutorialCompleted: false,
      emergencyContactCompleted: true,
      profileCompleted: true,
      onboardingStep: 0,
    );
    await _persist(reset);
    state = OnboardingUiState(phase: OnboardingPhase.tour, status: reset, tourIndex: 0);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingUiState>((ref) {
  return OnboardingNotifier(ref);
});
