import 'package:flutter/material.dart';

import '../../features/branding/domain/entities/branding_config.dart';
import 'app_theme.dart';
import 'app_theme_components.dart';
import 'faisal_palette.dart';

/// Original theme is untouched unless an administrator explicitly customizes it.
class BrandingTheme {
  static ThemeData build(
    BrandingConfig config,
    Brightness brightness,
    String languageCode,
  ) {
    var base = brightness == Brightness.dark
        ? AppTheme.dark()
        : AppTheme.light();
    if (config.customTheme) {
      Color c(String key) => config.color(key, brightness);
      Color on(Color color) =>
          BrandingConfig.contrastRatio(Colors.white, color) >= 4.5
          ? Colors.white
          : Colors.black;
      final scheme = base.colorScheme.copyWith(
        primary: c('primary'),
        onPrimary: on(c('primary')),
        secondary: c('secondary'),
        onSecondary: on(c('secondary')),
        tertiary: c('accent'),
        onTertiary: on(c('accent')),
        surface: c('surface'),
        onSurface: c('text_primary'),
        onSurfaceVariant: c('text_secondary'),
        error: c('error'),
        onError: on(c('error')),
        outline: c('border'),
        outlineVariant: c('border'),
        surfaceContainerHigh: c('card'),
        surfaceContainerHighest: c('background'),
      );
      final palette = base.extension<FaisalPalette>()!.copyWith(
        headerGradient: [c('primary'), c('primary')],
        cardGradient: [c('primary'), c('secondary')],
        gold: c('accent'),
        softSurface: c('background'),
        mintSurface: c('card'),
        danger: c('error'),
        outline: c('border'),
        onHeader: on(c('primary')),
        onHeaderMuted: on(c('primary')),
        chipBackground: c('surface'),
      );
      final texts = base.textTheme.apply(
        bodyColor: c('text_primary'),
        displayColor: c('text_primary'),
      );
      base = decorateTheme(
        base: base.copyWith(
          colorScheme: scheme,
          textTheme: texts,
          scaffoldBackgroundColor: c('background'),
          canvasColor: c('surface'),
          dividerColor: c('border'),
          extensions: [palette],
        ),
        scheme: scheme,
        palette: palette,
        textTheme: texts,
      );
      base = base.copyWith(
        cardTheme: base.cardTheme.copyWith(color: c('card')),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: c('surface'),
          hintStyle: texts.bodyMedium?.copyWith(color: c('text_secondary')),
          prefixIconColor: c('text_secondary'),
          suffixIconColor: c('text_secondary'),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: base.filledButtonTheme.style?.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? c('border')
                  : c('button_background'),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? c('text_secondary')
                  : c('button_text'),
            ),
          ),
        ),
        snackBarTheme: base.snackBarTheme.copyWith(
          backgroundColor: c('surface'),
          contentTextStyle: texts.bodyMedium?.copyWith(
            color: c('text_primary'),
          ),
        ),
      );
    }
    final d = config.data;
    final customTypography =
        d['primary_font'] != 'System' ||
        d['arabic_font'] != 'System' ||
        d['english_font'] != 'System' ||
        d['font_size_scale'] != 1 ||
        d['heading_font_weight'] != 700 ||
        d['body_font_weight'] != 400;
    if (!customTypography) {
      return base;
    }
    final selected =
        d[languageCode == 'ar' ? 'arabic_font' : 'english_font'] as String;
    final family = selected == 'System'
        ? d['primary_font'] as String
        : selected;
    final heading =
        FontWeight.values[(d['heading_font_weight'] as int) ~/ 100 - 1];
    final body = FontWeight.values[(d['body_font_weight'] as int) ~/ 100 - 1];
    TextTheme typography(TextTheme theme) {
      final scaled = theme.apply(
        fontFamily: family == 'System' ? null : family,
      );
      TextStyle? style(TextStyle? value, FontWeight weight) => value?.copyWith(
        fontWeight: weight,
        fontSize: value.fontSize == null
            ? null
            : value.fontSize! * (d['font_size_scale'] as num).toDouble(),
        fontFamilyFallback: family == 'System'
            ? null
            : const ['NotoSansArabic', 'NotoSans'],
      );
      return scaled.copyWith(
        displayLarge: style(scaled.displayLarge, heading),
        displayMedium: style(scaled.displayMedium, heading),
        displaySmall: style(scaled.displaySmall, heading),
        headlineLarge: style(scaled.headlineLarge, heading),
        headlineMedium: style(scaled.headlineMedium, heading),
        headlineSmall: style(scaled.headlineSmall, heading),
        titleLarge: style(scaled.titleLarge, heading),
        titleMedium: style(scaled.titleMedium, heading),
        titleSmall: style(scaled.titleSmall, heading),
        bodyLarge: style(scaled.bodyLarge, body),
        bodyMedium: style(scaled.bodyMedium, body),
        bodySmall: style(scaled.bodySmall, body),
        labelLarge: style(
          scaled.labelLarge,
          scaled.labelLarge?.fontWeight ?? body,
        ),
        labelMedium: style(
          scaled.labelMedium,
          scaled.labelMedium?.fontWeight ?? body,
        ),
        labelSmall: style(
          scaled.labelSmall,
          scaled.labelSmall?.fontWeight ?? body,
        ),
      );
    }

    final text = typography(base.textTheme);
    return base.copyWith(
      textTheme: text,
      primaryTextTheme: typography(base.primaryTextTheme),
      appBarTheme: base.appBarTheme.copyWith(titleTextStyle: text.titleLarge),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
    );
  }

  static ThemeMode mode(BrandingConfig config, ThemeMode preference) =>
      switch (config.text('theme_mode')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => preference,
      };
}
