import 'package:flutter/material.dart';

/// Shared colour tokens for Tripora.
///
/// Brand colours and category colours live here as constants. Colours that
/// must change between light and dark mode (backgrounds, text, borders) come
/// from [TriporaPalette] through `context.palette`, so they follow the theme.
class AppColors {
  AppColors._();

  // Palette: deep teal (primary), turquoise (accent), coral (calls to action)
  // on a warm cream background. Text colours meet WCAG AA contrast on white.
  static const Color navy = Color(0xFF0B4F5C); // deep teal
  static const Color blue = Color(0xFF0E7C86); // primary teal
  static const Color purple = Color(0xFF7C3AED); // category colour only
  static const Color teal = Color(0xFF13958B); // turquoise accent
  static const Color pink = Color(0xFFDB2777);
  static const Color orange = Color(0xFFEA580C); // status and tag colour
  static const Color coral = Color(0xFFC2410C); // calls to action and place names
  static const Color green = Color(0xFF16A34A);

  static const Color background = Color(0xFFFBF7F0); // soft cream
  static const Color surface = Colors.white;
  static const Color surfaceTint = Color(0xFFE8F5F3); // light teal tint
  static const Color border = Color(0xFFE7E0D4);

  static const Color text = Color(0xFF13262B);
  static const Color muted = Color(0xFF5B6B70);
  static const Color danger = Color(0xFFDC2626);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, blue, teal],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [coral, Color(0xFFD35A1F)],
  );

  static List<BoxShadow> softShadow([Color color = Colors.black]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Colour used for each travel interest across the app.
  static Color forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return green;
      case 'adventure':
        return orange;
      case 'culture':
        return purple;
      case 'beach':
        return teal;
      case 'shopping':
        return pink;
      default:
        return blue;
    }
  }

  static IconData iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return Icons.forest_rounded;
      case 'adventure':
        return Icons.hiking_rounded;
      case 'culture':
        return Icons.account_balance_rounded;
      case 'beach':
        return Icons.beach_access_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.travel_explore_rounded;
    }
  }
}

/// Theme-dependent colours. Read them with `context.palette` in a build
/// method, so widgets rebuild when the user switches light or dark mode.
class TriporaPalette extends ThemeExtension<TriporaPalette> {
  final Color background;
  final Color surface;
  final Color surfaceTint;
  final Color border;
  final Color text;
  final Color muted;
  final Color danger;
  final Color blue;
  final Color navy;
  final Color teal;
  final Color green;
  final Color orange;
  final Color purple;
  final Color pink;
  final Color coral;
  final Color warningSurface;
  final Color warningBorder;
  final Color warningText;

  const TriporaPalette({
    required this.background,
    required this.surface,
    required this.surfaceTint,
    required this.border,
    required this.text,
    required this.muted,
    required this.danger,
    required this.blue,
    required this.navy,
    required this.teal,
    required this.green,
    required this.orange,
    required this.purple,
    required this.pink,
    required this.coral,
    required this.warningSurface,
    required this.warningBorder,
    required this.warningText,
  });

  static const TriporaPalette light = TriporaPalette(
    background: AppColors.background,
    surface: Colors.white,
    surfaceTint: AppColors.surfaceTint,
    border: AppColors.border,
    text: AppColors.text,
    muted: AppColors.muted,
    danger: AppColors.danger,
    blue: AppColors.blue,
    navy: AppColors.navy,
    teal: AppColors.teal,
    green: AppColors.green,
    orange: AppColors.orange,
    purple: AppColors.purple,
    pink: AppColors.pink,
    coral: AppColors.coral,
    warningSurface: Color(0xFFFFF5DF),
    warningBorder: Color(0xFFFFD78A),
    warningText: Color(0xFF795000),
  );

  // Dark colours are lighter versions of the same hues, tuned so text and
  // icons keep at least 4.5:1 contrast on the dark surfaces.
  static const TriporaPalette dark = TriporaPalette(
    background: Color(0xFF0F1B1E),
    surface: Color(0xFF182A2E),
    surfaceTint: Color(0xFF1F3D42),
    border: Color(0xFF2F4D52),
    text: Color(0xFFE9F2F3),
    muted: Color(0xFFA9BCC0),
    danger: Color(0xFFFF7A7A),
    blue: Color(0xFF6BCBD3),
    navy: Color(0xFF9EDCE2),
    teal: Color(0xFF4FD1C5),
    green: Color(0xFF4ADE80),
    orange: Color(0xFFFFA45C),
    purple: Color(0xFFB79CFF),
    pink: Color(0xFFF479B8),
    coral: Color(0xFFFF9A6E),
    warningSurface: Color(0xFF3A2E14),
    warningBorder: Color(0xFF7A5A1E),
    warningText: Color(0xFFFFD78A),
  );

  @override
  TriporaPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceTint,
    Color? border,
    Color? text,
    Color? muted,
    Color? danger,
    Color? blue,
    Color? navy,
    Color? teal,
    Color? green,
    Color? orange,
    Color? purple,
    Color? pink,
    Color? coral,
    Color? warningSurface,
    Color? warningBorder,
    Color? warningText,
  }) {
    return TriporaPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      danger: danger ?? this.danger,
      blue: blue ?? this.blue,
      navy: navy ?? this.navy,
      teal: teal ?? this.teal,
      green: green ?? this.green,
      orange: orange ?? this.orange,
      purple: purple ?? this.purple,
      pink: pink ?? this.pink,
      coral: coral ?? this.coral,
      warningSurface: warningSurface ?? this.warningSurface,
      warningBorder: warningBorder ?? this.warningBorder,
      warningText: warningText ?? this.warningText,
    );
  }

  @override
  TriporaPalette lerp(TriporaPalette? other, double t) {
    if (other == null) return this;
    return TriporaPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      green: Color.lerp(green, other.green, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  /// The colours for the theme that is active right now (light or dark).
  TriporaPalette get palette =>
      Theme.of(this).extension<TriporaPalette>() ?? TriporaPalette.light;
}

class TriporaTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.background,

    extensions: const [TriporaPalette.light],

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.purple,
      tertiary: AppColors.teal,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),

    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.55),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.surfaceTint,
      elevation: 0,
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
    ),
  );

  /// Dark theme. Same structure as [lightTheme]; surfaces and text come from
  /// [TriporaPalette.dark] and every input keeps a visible border.
  static ThemeData darkTheme = _buildDark();

  static ThemeData _buildDark() {
    const p = TriporaPalette.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: p.background,

      extensions: const [TriporaPalette.dark],

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.dark,
        primary: p.blue,
        secondary: p.purple,
        tertiary: p.teal,
        surface: p.surface,
        onSurface: p.text,
        error: p.danger,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: p.text, fontSize: 15),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.surfaceTint,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? p.blue : p.muted,
          ),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: p.border),
        ),
      ),
    );
  }
}
