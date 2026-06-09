import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/emergency/emergency_constants.dart';
import '../../features/emergency/widgets/emergency_help_button.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';

/// Matches mobile/app/(patient)/settings.tsx (dark mode toggle).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dark Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: isDark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isDark ? 'Dark theme is on across the app.' : 'Light theme is on.',
                    style: GoogleFonts.poppins(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outline),
            ),
            tileColor: cs.surface,
            leading: const Icon(Icons.emergency, color: EmergencyConstants.emergencyRed),
            title: Text(
              'Emergency Settings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Contacts, medical info & SOS preferences',
              style: GoogleFonts.poppins(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => context.push(RouteNames.emergencySettings),
          ),
          const SizedBox(height: 12),
          const EmergencyHelpButton(),
        ],
      ),
    );
  }
}
