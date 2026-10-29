import 'package:faisal_app/features/banks/presentation/bank_onboarding_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/login_page.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Requires a fresh isolated test server: backend/serve_integration.py.
/// All identifiers and passwords below belong only to fictional test fixtures.
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 240; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Expected screen did not appear');
}

Future<void> tap(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final buttons = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  final target = buttons.evaluate().isNotEmpty
      ? buttons.last
      : find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 400));
}

bool isStartupPage(Widget widget) =>
    widget is TextFormField ||
    widget is NavigationBar ||
    widget is BankNoticesPage ||
    widget is BankOnboardingPage;

/// Follow the global bank selection before entering the username form.
Future<void> chooseBank(WidgetTester tester, String code) async {
  if (find.byType(LoginPage).evaluate().isNotEmpty) {
    await tap(tester, 'Change bank');
  }
  await waitFor(tester, find.byType(BankOnboardingPage));
  for (
    var i = 0;
    i < 2 &&
        find.byKey(const Key('bank-onboarding-next')).evaluate().isNotEmpty;
    i++
  ) {
    await tester.tap(find.byKey(const Key('bank-onboarding-next')));
    await tester.pumpAndSettle();
  }
  await tester.enterText(
    find.byKey(const Key('bank-onboarding-search')),
    code == 'banque_misr' ? 'Misr' : code,
  );
  await tester.pumpAndSettle();
  final target = find.byKey(ValueKey('choose-bank-$code'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await waitFor(tester, find.byType(LoginPage));
}

Future<void> openSignIn(WidgetTester tester) async {
  await waitFor(
    tester,
    find.byWidgetPredicate(
      (w) => w is LoginPage || w is BankOnboardingPage || w is BankNoticesPage,
    ),
  );
  final card = find.byKey(const ValueKey('notice_continue_login'));
  if (card.evaluate().isNotEmpty) {
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
  }
  if (find.byType(BankOnboardingPage).evaluate().isNotEmpty) {
    await chooseBank(tester, 'faisal');
  }
  await waitFor(tester, find.byType(TextFormField));
}

Future<String> stepUp(WidgetTester tester, String password) async {
  await tap(tester, 'Authorize operation');
  await waitFor(tester, find.text('Current password'));
  await tester.enterText(find.byType(TextFormField).last, password);
  await tester.pump();
  await tap(tester, 'Authorize operation');
  await waitFor(tester, find.text('Copy Token'));
  await tap(tester, 'Copy Token');
  final token = (await Clipboard.getData('text/plain'))?.text;
  expect(token?.isNotEmpty, isTrue);
  await tap(tester, 'Continue');
  await tester.pumpAndSettle();
  return token!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'registration, authorized transfer, profile review and password change use the real API',
    (tester) async {
      app.main();
      await waitFor(tester, find.byWidgetPredicate(isStartupPage));
      await sl<LanguageCubit>().change('en');
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await openSignIn(tester);
      await tester.pumpAndSettle();
      await waitFor(tester, find.text('Register for digital banking'));
      await tap(tester, 'Register for digital banking');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        '4000-0000-0000-0901',
      );
      await tap(tester, 'Continue');
      await waitFor(tester, find.text('Verify code'));
      final codeWidget = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .first;
      final code = RegExp(r'\b[0-9]{6}\b')
          .firstMatch(codeWidget.data!)
          ?.group(0);
      expect(code?.length, 6);
      await tester.enterText(find.byType(TextFormField).first, code!);
      await tap(tester, 'Verify code');
      await waitFor(tester, find.text('New password'));
      await tester.enterText(find.byType(TextFormField).at(0), 'youssefkamal');
      await waitFor(tester, find.byType(ActionChip));
      expect(find.byType(ActionChip), findsNWidgets(3));
      final selectedUsername =
          (tester.widget<ActionChip>(find.byType(ActionChip).first).label
                  as Text)
              .data!;
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ActionChip).first);
      await tester.tap(find.byType(ActionChip).first);
      await waitFor(tester, find.text('Username is available'));
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Registration#2026',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Registration#2026',
      );
      await tester.pump();
      await tap(tester, 'Continue');
      await waitFor(tester, find.byType(NavigationBar));
      await tap(tester, 'More');
      await tap(tester, 'Transfers');
      await waitFor(tester, find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('**** **** 0901 • EGP').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('**** **** 0902 • EGP').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '10.00');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Fictional integration transfer',
      );
      await tap(tester, 'Review transfer');
      await waitFor(tester, find.text('Authorize operation'));
      final transferToken = await stepUp(tester, 'Registration#2026');
      await tester.enterText(find.byType(TextFormField), transferToken);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tap(tester, 'Confirm transfer');
      await waitFor(tester, find.text('Transfer completed (simulated)'));
      await tap(tester, 'More');
      await tap(tester, 'Profile');
      await waitFor(tester, find.text('Registration Example'));
      await tap(tester, 'Update personal information');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Fictional integration address 10',
      );
      final profileToken = await stepUp(tester, 'Registration#2026');
      await tester.enterText(find.byType(TextFormField).at(3), profileToken);
      await tap(tester, 'Save');
      await waitFor(tester, find.textContaining('Submitted for bank review.'));
      await tap(tester, 'Done');
      await tap(tester, 'Change password');
      final passwordToken = await stepUp(tester, 'Registration#2026');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Registration#2026',
      );
      await tester.enterText(find.byType(TextFormField).at(1), passwordToken);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Changed#Registration26',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Changed#Registration26',
      );
      await tester.pump();
      await tap(tester, 'Change password');
      await openSignIn(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.enterText(
        find.byType(TextFormField).at(0),
        selectedUsername,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Changed#Registration26',
      );
      await tap(tester, 'Sign in');
      await waitFor(tester, find.byType(NavigationBar));
    },
  );
}
