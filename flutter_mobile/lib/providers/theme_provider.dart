import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/storage_helper.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref, ThemeMode initial) : super(initial);

  final Ref _ref;

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await _ref.read(storageHelperProvider).setDarkMode(next == ThemeMode.dark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final dark = ref.read(storageHelperProvider).getDarkMode();
  return ThemeModeNotifier(ref, dark ? ThemeMode.dark : ThemeMode.light);
});
