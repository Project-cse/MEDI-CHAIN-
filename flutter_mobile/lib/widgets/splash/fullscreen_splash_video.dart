import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../brand/medclues_palette.dart';

/// Splash fills the screen — scales video so its own #f5f5f5 canvas reaches all edges.
class FullscreenSplashVideo extends StatelessWidget {
  const FullscreenSplashVideo({
    super.key,
    required this.controller,
    this.fallbackWidth = 1080,
    this.fallbackHeight = 1920,
  });

  final VideoPlayerController controller;
  final double fallbackWidth;
  final double fallbackHeight;

  /// Contain keeps the full MEDCLUES wordmark visible — cover crops M/S on tall phones.
  /// Letterbox bars use splashCanvas (#f5f5f5), matching the video background.
  static const BoxFit _fit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        final w = controller.value.size.width > 0
            ? controller.value.size.width
            : fallbackWidth;
        final h = controller.value.size.height > 0
            ? controller.value.size.height
            : fallbackHeight;

        return ColoredBox(
          color: MedcluesPalette.splashCanvas,
          child: SizedBox.expand(
            child: ClipRect(
              child: FittedBox(
                fit: _fit,
                alignment: Alignment.center,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
