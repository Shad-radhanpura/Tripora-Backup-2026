import 'package:flutter/material.dart';

import '../services/appearance_settings.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Settings. Right now this holds the Appearance choice (light, dark or the
/// phone's own setting), which applies across the whole app at once.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _choose(BuildContext context, ThemeMode mode) async {
    final saved = await AppearanceSettings.choose(mode);
    if (!context.mounted) return;
    if (!saved) {
      showAppMessage(
        context,
        'Could not save this choice on the device. It applies until the app closes.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              const SectionHeader(
                title: 'Appearance',
                subtitle: 'Applies across the whole app.',
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppearanceSettings.themeMode,
                builder: (context, current, _) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: [
                          for (final mode in ThemeMode.values)
                            ButtonSegment<ThemeMode>(
                              value: mode,
                              label: Text(AppearanceSettings.label(mode)),
                              icon: Icon(_iconFor(mode)),
                            ),
                        ],
                        selected: {current},
                        onSelectionChanged: (selection) =>
                            _choose(context, selection.first),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _describe(current),
                        style: TextStyle(color: palette.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
    ThemeMode.system => Icons.brightness_auto_rounded,
  };

  static String _describe(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Always use the light colours.',
    ThemeMode.dark => 'Always use the dark colours. Easier on the eyes at night.',
    ThemeMode.system =>
      "Follow this phone's or browser's light or dark setting.",
  };
}
