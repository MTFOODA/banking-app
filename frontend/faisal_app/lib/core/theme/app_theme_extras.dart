import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'faisal_palette.dart';

/// Navigation, dialog, snackbar and sheet theming.
ThemeData decorateExtras({
  required ThemeData base,
  required ColorScheme scheme,
  required FaisalPalette palette,
  required TextTheme textTheme,
  required Color secondaryText,
}) {
  final isDark = scheme.brightness == Brightness.dark;
  return base.copyWith(
    navigationBarTheme: NavigationBarThemeData(
      height: AppSizes.bottomNavHeight,
      backgroundColor: scheme.surface,
      indicatorColor: palette.mintSurface,
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : secondaryText,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: AppSizes.iconMd,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : secondaryText,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.mintSurface,
      side: BorderSide(color: palette.outline),
      labelStyle: textTheme.bodySmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? FaisalColors.darkElevated
          : FaisalColors.deepForestGreen,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: FaisalColors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
  );
}
