import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_components.dart';
import 'faisal_palette.dart';

/// Centralised [ThemeData] builders. Screens must consume theme tokens only.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, FaisalPalette.light);

  static ThemeData dark() => _build(Brightness.dark, FaisalPalette.dark);

  static ColorScheme _scheme(Brightness brightness, FaisalPalette palette) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: isDark ? const Color(0xFF58B394) : FaisalColors.primaryGreen,
      onPrimary: isDark ? FaisalColors.darkSurface : FaisalColors.white,
      secondary: palette.gold,
      onSecondary: isDark
          ? FaisalColors.darkSurface
          : FaisalColors.deepForestGreen,
      error: palette.danger,
      onError: isDark ? FaisalColors.darkSurface : FaisalColors.white,
      surface: isDark ? FaisalColors.darkSurface : FaisalColors.white,
      onSurface: isDark
          ? FaisalColors.darkPrimaryText
          : FaisalColors.primaryText,
      surfaceContainerHighest: palette.mintSurface,
      surfaceContainerHigh: isDark
          ? FaisalColors.darkElevated
          : FaisalColors.softGreenSurface,
      outline: palette.outline,
      outlineVariant: palette.outline,
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: isDark ? FaisalColors.white : FaisalColors.darkSurface,
      onInverseSurface: isDark
          ? FaisalColors.primaryText
          : FaisalColors.darkPrimaryText,
      inversePrimary: isDark
          ? FaisalColors.deepForestGreen
          : const Color(0xFF9FD7C2),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  static ThemeData _build(Brightness brightness, FaisalPalette palette) {
    final scheme = _scheme(brightness, palette);
    final textTheme = _textTheme(brightness);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.softSurface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      splashFactory: InkSparkle.splashFactory,
      dividerColor: palette.outline,
      dividerTheme: DividerThemeData(
        color: palette.outline,
        thickness: 1,
        space: 1,
      ),
    );
    return decorateTheme(
      base: base,
      scheme: scheme,
      palette: palette,
      textTheme: textTheme,
    );
  }
}

/// Shared radius helper used by component themes and widgets.
BorderRadius faisalRadius([double value = AppRadius.md]) =>
    BorderRadius.circular(value);
