import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark or system theme. The choice is saved on this device, so it is
/// still there after the app restarts.
class AppearanceSettings {
  AppearanceSettings._();

  static const String prefKey = 'appearance.theme_mode';

  /// Light Mode is the default for new installs and for anyone without a saved choice.
  static const ThemeMode defaultMode = ThemeMode.light;

  /// The mode the app is using right now. TriporaApp listens to this.
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    defaultMode,
  );

  static ThemeMode parse(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => defaultMode,
  };

  static String encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static String label(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System default',
  };

  /// Reads the saved choice. If storage cannot be read, uses Light.
  static Future<void> load({SharedPreferences? prefs}) async {
    try {
      final store = prefs ?? await SharedPreferences.getInstance();
      themeMode.value = parse(store.getString(prefKey));
    } catch (_) {
      themeMode.value = defaultMode;
    }
  }

  /// Applies [mode] straight away and saves it. Returns false when the choice
  /// could not be saved; it still applies for this session.
  static Future<bool> choose(ThemeMode mode, {SharedPreferences? prefs}) async {
    themeMode.value = mode;
    try {
      final store = prefs ?? await SharedPreferences.getInstance();
      return await store.setString(prefKey, encode(mode));
    } catch (_) {
      return false;
    }
  }
}
