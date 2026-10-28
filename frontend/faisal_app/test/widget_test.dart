import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/widgets/faisal_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary button renders its label and responds to taps', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FaisalPrimaryButton(
            label: 'Continue',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(tapped, isTrue);
  });

  testWidgets('disabled primary button does not fire', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: FaisalPrimaryButton(label: 'Disabled', onPressed: null),
        ),
      ),
    );
    await tester.tap(find.text('Disabled'));
    expect(find.text('Disabled'), findsOneWidget);
  });
}
