import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom, theme-aware tokens that are not part of [ColorScheme].
@immutable
class FaisalPalette extends ThemeExtension<FaisalPalette> {
  const FaisalPalette({
    required this.headerGradient,
    required this.gold,
    required this.softSurface,
    required this.mintSurface,
    required this.success,
    required this.warning,
    required this.danger,
    required this.outline,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.cardGradient,
    required this.chipBackground,
  });

  final List<Color> headerGradient;
  final Color gold;
  final Color softSurface;
  final Color mintSurface;
  final Color success;
  final Color warning;
  final Color danger;
  final Color outline;
  final Color onHeader;
  final Color onHeaderMuted;
  final List<Color> cardGradient;
  final Color chipBackground;

  static const FaisalPalette light = FaisalPalette(
    headerGradient: [FaisalColors.deepHeaderGreen, FaisalColors.primaryGreen],
    gold: FaisalColors.goldAccent,
    softSurface: FaisalColors.softGreenSurface,
    mintSurface: FaisalColors.lightMint,
    success: FaisalColors.success,
    warning: FaisalColors.warning,
    danger: FaisalColors.error,
    outline: FaisalColors.border,
    onHeader: FaisalColors.white,
    onHeaderMuted: Color(0xFFBFD8CC),
    cardGradient: [FaisalColors.deepForestGreen, FaisalColors.secondaryGreen],
    chipBackground: FaisalColors.white,
  );

  static const FaisalPalette dark = FaisalPalette(
    headerGradient: [FaisalColors.darkHeader, Color(0xFF0A3B31)],
    gold: FaisalColors.darkGold,
    softSurface: FaisalColors.darkSurface,
    mintSurface: FaisalColors.darkMint,
    success: Color(0xFF4CC38A),
    warning: Color(0xFFE4B34B),
    danger: Color(0xFFF0737A),
    outline: FaisalColors.darkBorder,
    onHeader: FaisalColors.darkPrimaryText,
    onHeaderMuted: Color(0xFF9DB2A8),
    cardGradient: [Color(0xFF06251F), Color(0xFF0A4B3D)],
    chipBackground: FaisalColors.darkElevated,
  );

  @override
  FaisalPalette copyWith({
    List<Color>? headerGradient,
    Color? gold,
    Color? softSurface,
    Color? mintSurface,
    Color? success,
    Color? warning,
    Color? danger,
    Color? outline,
    Color? onHeader,
    Color? onHeaderMuted,
    List<Color>? cardGradient,
    Color? chipBackground,
  }) {
    return FaisalPalette(
      headerGradient: headerGradient ?? this.headerGradient,
      gold: gold ?? this.gold,
      softSurface: softSurface ?? this.softSurface,
      mintSurface: mintSurface ?? this.mintSurface,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      outline: outline ?? this.outline,
      onHeader: onHeader ?? this.onHeader,
      onHeaderMuted: onHeaderMuted ?? this.onHeaderMuted,
      cardGradient: cardGradient ?? this.cardGradient,
      chipBackground: chipBackground ?? this.chipBackground,
    );
  }

  @override
  FaisalPalette lerp(ThemeExtension<FaisalPalette>? other, double t) {
    if (other is! FaisalPalette) {
      return this;
    }
    return FaisalPalette(
      headerGradient: _lerpGradient(headerGradient, other.headerGradient, t),
      gold: Color.lerp(gold, other.gold, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      mintSurface: Color.lerp(mintSurface, other.mintSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      onHeader: Color.lerp(onHeader, other.onHeader, t)!,
      onHeaderMuted: Color.lerp(onHeaderMuted, other.onHeaderMuted, t)!,
      cardGradient: _lerpGradient(cardGradient, other.cardGradient, t),
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
    );
  }

  static List<Color> _lerpGradient(List<Color> a, List<Color> b, double t) {
    if (a.length != b.length) {
      return t < 0.5 ? a : b;
    }
    return List<Color>.generate(
      a.length,
      (index) => Color.lerp(a[index], b[index], t)!,
    );
  }
}

/// Convenience accessors so widgets never reach for raw colour constants.
extension FaisalThemeContext on BuildContext {
  FaisalPalette get palette =>
      Theme.of(this).extension<FaisalPalette>() ?? FaisalPalette.light;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
