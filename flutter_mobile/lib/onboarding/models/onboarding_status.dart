class OnboardingStatus {
  const OnboardingStatus({
    this.onboardingCompleted = false,
    this.tutorialCompleted = false,
    this.emergencyContactCompleted = false,
    this.profileCompleted = false,
    this.onboardingStep = 0,
  });

  final bool onboardingCompleted;
  final bool tutorialCompleted;
  final bool emergencyContactCompleted;
  final bool profileCompleted;
  final int onboardingStep;

  bool get needsOnboarding => !onboardingCompleted;

  /// 0–5 tour, 6 emergency form, 7 profile form, 8 completion pending
  int get resumeStep {
    if (onboardingCompleted) return 8;
    if (!tutorialCompleted) return onboardingStep.clamp(0, 5);
    if (!emergencyContactCompleted) return 6;
    if (!profileCompleted) return 7;
    return 8;
  }

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      onboardingCompleted: json['onboardingCompleted'] == true,
      tutorialCompleted: json['tutorialCompleted'] == true,
      emergencyContactCompleted: json['emergencyContactCompleted'] == true,
      profileCompleted: json['profileCompleted'] == true,
      onboardingStep: json['onboardingStep'] is int
          ? json['onboardingStep'] as int
          : int.tryParse('${json['onboardingStep'] ?? 0}') ?? 0,
    );
  }

  OnboardingStatus copyWith({
    bool? onboardingCompleted,
    bool? tutorialCompleted,
    bool? emergencyContactCompleted,
    bool? profileCompleted,
    int? onboardingStep,
  }) {
    return OnboardingStatus(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      emergencyContactCompleted: emergencyContactCompleted ?? this.emergencyContactCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }

  Map<String, dynamic> toPatchJson() => {
        if (onboardingCompleted) 'onboardingCompleted': true,
        'tutorialCompleted': tutorialCompleted,
        'emergencyContactCompleted': emergencyContactCompleted,
        'profileCompleted': profileCompleted,
        'onboardingStep': onboardingStep,
      };
}
