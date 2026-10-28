import 'package:flutter/material.dart';

/// Brand palette for Faisal App.
///
/// These are the shared design tokens; individual screens must not hardcode
/// their own colours. Dark mode uses deeper forest surfaces with the same gold
/// accent so the hierarchy stays recognisable.
class FaisalColors {
  const FaisalColors._();

  // Light tokens.
  static const Color primaryGreen = Color(0xFF075C46);
  static const Color secondaryGreen = Color(0xFF0B795A);
  static const Color deepForestGreen = Color(0xFF063D32);
  static const Color deepHeaderGreen = Color(0xFF06483A);
  static const Color goldAccent = Color(0xFFC8A44D);
  static const Color lightMint = Color(0xFFEAF5EF);
  static const Color softGreenSurface = Color(0xFFF4F9F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF172923);
  static const Color secondaryText = Color(0xFF77857E);
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFD99A22);
  static const Color error = Color(0xFFC83C42);
  static const Color border = Color(0xFFE5EBE6);

  // Dark tokens.
  static const Color darkSurface = Color(0xFF0B1F19);
  static const Color darkElevated = Color(0xFF123027);
  static const Color darkHeader = Color(0xFF052E26);
  static const Color darkMint = Color(0xFF163B30);
  static const Color darkPrimaryText = Color(0xFFF2F7F4);
  static const Color darkSecondaryText = Color(0xFF9DB2A8);
  static const Color darkBorder = Color(0xFF24463A);
  static const Color darkGold = Color(0xFFD9B862);

  static const Color headerGradientStart = deepHeaderGreen;
  static const Color headerGradientEnd = primaryGreen;
}
