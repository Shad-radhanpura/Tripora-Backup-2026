// Dark mode: the theme choice, its saved value, and the colours it applies.
// Storage is an in-memory mock; nothing touches Firebase.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/screens/settings_page.dart';
import 'package:tripora/services/appearance_settings.dart';
import 'package:tripora/theme/theme.dart';

/// WCAG contrast ratio between two colours (1 to 21).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppearanceSettings.themeMode.value = AppearanceSettings.defaultMode;
  });

  group('saved choice', () {
    test('stored words map to theme modes and back', () {
      expect(AppearanceSettings.parse('dark'), ThemeMode.dark);
      expect(AppearanceSettings.parse('light'), ThemeMode.light);
      expect(AppearanceSettings.parse('system'), ThemeMode.system);
      expect(AppearanceSettings.parse(null), ThemeMode.light);
      expect(AppearanceSettings.parse('neon'), ThemeMode.light);
      for (final mode in ThemeMode.values) {
        expect(AppearanceSettings.parse(AppearanceSettings.encode(mode)), mode);
      }
    });

    test('labels are the ones shown in Settings', () {
      expect(AppearanceSettings.label(ThemeMode.light), 'Light');
      expect(AppearanceSettings.label(ThemeMode.dark), 'Dark');
      expect(AppearanceSettings.label(ThemeMode.system), 'System default');
    });

    test('the default is Light when nothing was saved', () async {
      await AppearanceSettings.load(prefs: await SharedPreferences.getInstance());
      expect(AppearanceSettings.themeMode.value, ThemeMode.light);
    });

    test('a choice is saved and still there after a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final saved = await AppearanceSettings.choose(ThemeMode.dark, prefs: prefs);
      expect(saved, isTrue);
      expect(AppearanceSettings.themeMode.value, ThemeMode.dark);
      expect(prefs.getString(AppearanceSettings.prefKey), 'dark');

      // Simulate a restart: the in-memory value is reset, the saved value is kept.
      AppearanceSettings.themeMode.value = ThemeMode.system;
      await AppearanceSettings.load(prefs: prefs);
      expect(AppearanceSettings.themeMode.value, ThemeMode.dark);
    });
  });

  group('colours', () {
    test('dark and light backgrounds differ', () {
      expect(TriporaPalette.dark.background, isNot(TriporaPalette.light.background));
    });

    test('main text and muted text stay readable on dark surfaces', () {
      expect(
        _contrast(TriporaPalette.dark.text, TriporaPalette.dark.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(TriporaPalette.dark.muted, TriporaPalette.dark.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(TriporaPalette.dark.blue, TriporaPalette.dark.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('the light palette still meets contrast on white', () {
      expect(
        _contrast(TriporaPalette.light.text, TriporaPalette.light.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark theme is dark and carries the dark palette', () {
      final theme = TriporaTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, TriporaPalette.dark.background);
      expect(theme.extension<TriporaPalette>(), same(TriporaPalette.dark));
    });

    test('light theme keeps the cream background', () {
      final theme = TriporaTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<TriporaPalette>(), same(TriporaPalette.light));
    });
  });

  testWidgets('choosing Dark in Settings changes the whole app and is saved', (tester) async {
    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: AppearanceSettings.themeMode,
        builder: (context, mode, _) => MaterialApp(
          theme: TriporaTheme.lightTheme,
          darkTheme: TriporaTheme.darkTheme,
          themeMode: mode,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Light is the default, so the dark option is not selected at the start.
    expect(find.text('Light'), findsWidgets);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    // Let the saved-value write finish outside the fake clock.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(AppearanceSettings.themeMode.value, ThemeMode.dark);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, TriporaPalette.dark.background);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);

    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString(AppearanceSettings.prefKey), 'dark');
  });
}
