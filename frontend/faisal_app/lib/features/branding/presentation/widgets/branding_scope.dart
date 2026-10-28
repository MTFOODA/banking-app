import 'package:flutter/material.dart';

import '../../../../core/theme/faisal_palette.dart';

import '../../domain/entities/branding_config.dart';

class BrandingScope extends InheritedWidget {
  const BrandingScope({
    super.key,
    required this.config,
    required super.child,
    this.preview = false,
  });
  final BrandingConfig config;
  final bool preview;
  static Color headerText(BuildContext context) => of(context).customTheme
      ? (Theme.of(context).extension<FaisalPalette>()?.onHeader ?? Colors.white)
      : Colors.white;
  static BrandingConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandingScope>()?.config ??
      BrandingConfig.defaults;
  static bool isPreview(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandingScope>()?.preview ??
      false;
  @override
  bool updateShouldNotify(BrandingScope old) =>
      config != old.config || preview != old.preview;
}
