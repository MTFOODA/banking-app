import 'dart:math' as math;

import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/widgets/faisal_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

double _relativeLuminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between two opaque colours.
double _contrastRatio(Color a, Color b) {
  final first = _relativeLuminance(a);
  final second = _relativeLuminance(b);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('bundled brand logo is declared and loadable', () async {
    final data = await rootBundle.load(FaisalLogo.assetPath);
    expect(data.lengthInBytes, greaterThan(1000));
  });

  testWidgets('FaisalLogo renders the bundled artwork asset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: FaisalLogo()),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, FaisalLogo.assetPath);
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('wordmark contrasts with the surface in both themes', (
    tester,
  ) async {
    for (final theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Center(child: FaisalLogo(size: 64, showWordmark: true)),
          ),
        ),
      );
      // MaterialApp animates between themes; let the implicit animation finish
      // so Theme.of() resolves the theme under test.
      await tester.pumpAndSettle();

      final wordmark = tester.widget<Text>(find.text('Your banks'));
      final tagline = tester.widget<Text>(find.text('Your banks, one app'));
      final surface = theme.colorScheme.surface;

      expect(
        _contrastRatio(wordmark.style!.color!, surface),
        greaterThan(4.5),
        reason:
            'wordmark must be legible on a ${theme.brightness.name} surface',
      );
      expect(
        _contrastRatio(tagline.style!.color!, surface),
        greaterThan(3.0),
        reason: 'tagline must be legible on a ${theme.brightness.name} surface',
      );
    }
  });

  testWidgets('explicit onDark keeps the header-gradient palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          backgroundColor: Color(0xFF075C46),
          body: Center(
            child: FaisalLogo(size: 52, onDark: true, showWordmark: true),
          ),
        ),
      ),
    );

    final wordmark = tester.widget<Text>(find.text('Your banks'));
    expect(wordmark.style!.color, Colors.white);
  });
}
