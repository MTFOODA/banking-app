import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/widgets/faisal_account_card.dart';
import 'package:faisal_app/core/widgets/faisal_bank_card.dart';
import 'package:faisal_app/core/widgets/faisal_transaction_tile.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/authentication/presentation/pages/password_setup_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'security_flow_test.dart' as flow;

/// Uses only fictional customers in backend/serve_integration.py's *_test DB.
/// Do not point this mutation-capable suite at another backend.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'physical device: legacy screens, Arabic RTL and first-login setup',
    (tester) async {
      app.main();
      await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
      await sl<LanguageCubit>().change('en');
      await tester.pumpAndSettle();
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await tester.pumpAndSettle();
      AppLocalizations labels() =>
          AppLocalizations.of(tester.element(find.byType(Scaffold).last));
      Future<void> back() => tester.tap(
        find.byTooltip(
          MaterialLocalizations.of(tester.element(find.byType(Scaffold).last))
              .backButtonTooltip,
        ),
      );
      Future<void> signIn(String identifier, String password) async {
        await tester.enterText(find.byType(TextFormField).at(0), identifier);
        await tester.enterText(find.byType(TextFormField).at(1), password);
        await flow.tap(tester, labels().signIn);
      }

      await signIn('4000000000000101', 'Incorrect#Password26');
      await flow.waitFor(tester, find.text(labels().loginFailed));
      expect(find.byType(NavigationBar), findsNothing);
      await signIn('4000 0000 0000 0101', 'Youssef#2026');
      await flow.waitFor(tester, find.byType(NavigationBar));
      await flow.tap(tester, labels().accounts);
      await flow.waitFor(tester, find.byType(FaisalAccountCard));
      await tester.tap(find.byType(FaisalAccountCard).first);
      await flow.waitFor(tester, find.text(labels().currentBalance));
      expect(find.text(labels().availableBalance), findsWidgets);
      await flow.tap(tester, labels().transactionsTitle);
      await flow.waitFor(tester, find.byType(FaisalTransactionTile));
      await tester.tap(find.byType(FaisalTransactionTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      final search = find.byType(TextField).first;
      await tester.enterText(search, 'no-such-device-test-payment');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await flow.waitFor(tester, find.text(labels().noTransactionsFound));
      await back();
      await tester.pumpAndSettle();
      await back();
      await tester.pumpAndSettle();
      await flow.tap(tester, labels().cards);
      await flow.waitFor(tester, find.byType(FaisalBankCard));
      await tester.tap(find.byType(FaisalBankCard).first);
      await flow.waitFor(tester, find.byType(SwitchListTile));
      final initialControl = tester
          .widget<SwitchListTile>(find.byType(SwitchListTile).first)
          .value;
      await tester.ensureVisible(find.byType(SwitchListTile).first);
      await tester.tap(find.byType(SwitchListTile).first);
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (tester
                .widget<SwitchListTile>(find.byType(SwitchListTile).first)
                .value !=
            initialControl) {
          break;
        }
      }
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
        !initialControl,
      );
      // Restore the test card's original online-payment setting.
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      await flow.tap(tester, labels().freezeCard);
      await flow.tap(tester, labels().confirm);
      await flow.waitFor(tester, find.text(labels().unfreezeCard));
      await flow.tap(tester, labels().unfreezeCard);
      await flow.tap(tester, labels().confirm);
      await flow.waitFor(tester, find.text(labels().freezeCard));
      await back();
      await tester.pumpAndSettle();
      await flow.tap(tester, labels().more);
      await flow.tap(tester, labels().profileTitle);
      await flow.waitFor(tester, find.text('Youssef Kamal'));
      await sl<LanguageCubit>().change('ar');
      await tester.pumpAndSettle();
      expect(
        Directionality.of(
          tester.element(find.text(labels().profileTitle).first),
        ),
        TextDirection.rtl,
      );
      expect(find.text(labels().biometricLogin), findsOneWidget);
      await back();
      await tester.pumpAndSettle();
      await flow.tap(tester, labels().transfers);
      await flow.waitFor(tester, find.byType(DropdownButtonFormField<String>));
      expect(
        Directionality.of(
          tester.element(find.byType(DropdownButtonFormField<String>).first),
        ),
        TextDirection.rtl,
      );
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.dark,
      );
      await sl<ThemeCubit>().change(ThemeMode.light);
      await sl<LanguageCubit>().change('en');
      await tester.pumpAndSettle();
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await tester.pumpAndSettle();

      await signIn('4000000000000109', 'Temp#Nada2026');
      await flow.waitFor(tester, find.byType(PasswordSetupPage));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(0), 'short');
      await tester.enterText(find.byType(TextFormField).at(1), 'different');
      await tester.pumpAndSettle();
      final continueButton = find.ancestor(
        of: find.text(labels().continueToHome),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(
        tester.widget<ButtonStyleButton>(continueButton).onPressed,
        isNull,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Device#Nada2026',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Device#Nada2026',
      );
      await tester.pump();
      await flow.tap(tester, labels().continueToHome);
      await flow.waitFor(tester, find.byType(NavigationBar));
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.waitFor(tester, find.text('Sign in'));
      await flow.openSignIn(tester);
      await tester.pumpAndSettle();
      await signIn('5550000000110', 'Device#Nada2026');
      await flow.waitFor(tester, find.byType(NavigationBar));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordSetupPage), findsNothing);
    },
  );
}
