import 'package:flutter/material.dart';

import '../theme/faisal_palette.dart';

/// Shared, app-wide balance visibility control.
///
/// Held in memory only; it deliberately resets when the app restarts.
class BalanceVisibilityController extends ChangeNotifier {
  BalanceVisibilityController({this._visible = true});

  bool _visible;

  bool get visible => _visible;

  void toggle() {
    _visible = !_visible;
    notifyListeners();
  }

  void set(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    notifyListeners();
  }
}

/// Eye button that toggles [BalanceVisibilityController].
class FaisalBalanceVisibilityToggle extends StatelessWidget {
  const FaisalBalanceVisibilityToggle({
    super.key,
    required this.controller,
    required this.showLabel,
    required this.hideLabel,
    this.onDark = true,
  });

  final BalanceVisibilityController controller;
  final String showLabel;
  final String hideLabel;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => IconButton(
        tooltip: controller.visible ? hideLabel : showLabel,
        onPressed: controller.toggle,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          controller.visible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: onDark ? context.palette.onHeader : context.colors.onSurface,
          size: 20,
        ),
      ),
    );
  }
}
