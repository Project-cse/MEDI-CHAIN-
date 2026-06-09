class AppConfig {

  AppConfig._();



  static const String appName = 'MEDCLUES';

  static const String appTagline = 'EMERGENCY | BOOKING';

  static const String brandSubtitle = 'SINCES 2026';

  static const int splashDurationMs = 2500;

  /// Opening intro video — replace `assets/videos/opening.mp4` (same name) to change splash video.
  /// Banner illustration: replace `assets/images/banner_navigation.png`.
  static const String splashVideoAsset = 'assets/videos/opening.mp4';

  static const String currency = 'INR';

  static const String currencySymbol = '₹';

  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;

}

