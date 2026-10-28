import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'faisal_palette.dart';

/// 8-point spacing scale shared by every screen.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

class AppSizes {
  const AppSizes._();

  static const double maxContentWidth = 1180;
  static const double maxFormWidth = 460;
  static const double maxAuthWidth = 480;
  static const double buttonHeight = 52;
  static const double bottomNavHeight = 72;
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;
  static const double avatar = 40;
}

class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration themeTransition = Duration(milliseconds: 220);
}

/// Breakpoints for responsive layouts (phone, tablet, desktop/admin).
class AppBreakpoints {
  const AppBreakpoints._();

  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phone;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phone && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

class FaisalGradients {
  const FaisalGradients._();

  static LinearGradient header(Brightness brightness) => LinearGradient(
    colors: brightness == Brightness.dark
        ? FaisalPalette.dark.headerGradient
        : FaisalPalette.light.headerGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient card(Brightness brightness) => LinearGradient(
    colors: brightness == Brightness.dark
        ? FaisalPalette.dark.cardGradient
        : FaisalPalette.light.cardGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldSheen = LinearGradient(
    colors: [Color(0xFFE3C77E), FaisalColors.goldAccent, Color(0xFF9E7B2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
