import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:faisal_app/main.dart' as app;
import 'package:faisal_app/core/config/app_config.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/widgets/faisal_logo.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/branding/domain/entities/branding_config.dart';
import 'package:faisal_app/features/branding/domain/repositories/branding_repository.dart';
import 'package:faisal_app/features/branding/presentation/cubit/branding_cubit.dart';
import 'package:faisal_app/features/branding/presentation/pages/admin_branding_page.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_preview.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';

import 'security_flow_test.dart' as flow;

/// Opt-in only. The dedicated 8017 QA database is separate from the operator's
/// persistent demo. Credentials are read once and deleted before sign-in.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real branding draft, preview, image, publish, RTL, defaults and history',
    (tester) async {
      expect(AppConfig.apiBaseUrl.contains(':8017/'), isTrue);
      final credentials = await tester.runAsync(() async {
        final file = File(
          '${Directory.systemTemp.parent.path}/files/qa/branding_login.json',
        );
        final result =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        await file.delete();
        return result;
      });
      app.main();
      await flow.waitFor(tester, find.byWidgetPredicate(flow.isStartupPage));
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      sl<AuthBloc>().add(const AuthLogoutRequested());
      await flow.openSignIn(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        credentials!['username'] as String,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        credentials['password'] as String,
      );
      await flow.tap(tester, 'Sign in');
      await flow.waitFor(tester, find.byType(AdminDashboardPage));
      expect(sl<AuthBloc>().state.can('admin.content.manage'), isTrue);
      final repository = sl<BrandingRepository>();
      // Upload uses the real validated multipart API; original artwork is preserved.
      final image = await rootBundle.load(FaisalLogo.assetPath);
      final uploaded = await repository.upload(
        image.buffer.asUint8List(),
        'qa-logo.png',
      );
      var doc = await repository.editor();
      final values = BrandingConfig.defaults.toJson();
      values['logo_url'] = uploaded;
      values['dark_logo_url'] = uploaded;
      values['splash_image_url'] = uploaded;
      doc = await repository.save(
        doc.revision,
        BrandingConfig.fromJson(values),
      );
      await flow.tap(tester, 'Settings');
      await flow.waitFor(tester, find.text('App Branding & Appearance'));
      await tester.tap(find.text('App Branding & Appearance'));
      await flow.waitFor(tester, find.byType(AdminBrandingPage));
      await flow.waitFor(tester, find.byType(BrandingPreview));
      await tester.pumpAndSettle();
      Finder field(String label) => find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        ),
        matching: find.byType(TextFormField),
      );
      Future<void> enter(String label, String value) async {
        final finder = field(label).first;
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.enterText(finder, value);
        await tester.pumpAndSettle();
      }

      await enter('Application display name', 'Nile QA');
      await enter('Application short name', 'Nile');
      await enter('Welcome message', 'Welcome • أهلاً بك');
      await enter('Tagline (optional)', 'Safe development preview');
      await enter('Primary color', '#1D4ED8');
      await enter('Button background', '#1D4ED8');
      final english = find
          .widgetWithText(
            DropdownButtonFormField<Object>,
            'Original system font',
          )
          .at(2);
      // Select fonts through the real dropdowns using their stable field keys.
      Future<void> font(String key, String name) async {
        final finder = find.byWidgetPredicate(
          (w) =>
              w is DropdownButtonFormField<Object> &&
              w.key.toString().contains(key),
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
      }

      expect(english.evaluate().isNotEmpty, isTrue);
      await font('arabic_font', 'NotoSansArabic');
      await font('english_font', 'NotoSans');
      expect(sl<BrandingCubit>().state.config.text('application_name'), isNull);
      await flow.tap(tester, 'Save draft');
      await flow.waitFor(
        tester,
        find.text('Draft saved. Live branding is unchanged.'),
      );
      expect(sl<BrandingCubit>().state.config.text('application_name'), isNull);
      debugPrint('BRANDING_SCREENSHOT: 01_saved_draft_en');
      await tester.ensureVisible(find.byType(BrandingPreview));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await flow.tap(tester, 'Publish changes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK').last);
      await flow.waitFor(tester, find.text('Branding published successfully.'));
      await tester.pumpAndSettle();
      final first = (await repository.editor()).active.version;
      expect(
        sl<BrandingCubit>().state.config.text('application_name'),
        'Nile QA',
      );
      expect(sl<BrandingCubit>().state.config.text('logo_url'), uploaded);
      expect(find.byType(AdminBrandingPage), findsOneWidget);
      await tester.ensureVisible(find.byType(BrandingPreview));
      await tester.pumpAndSettle();
      debugPrint('BRANDING_SCREENSHOT: 02_published_en');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await sl<LanguageCubit>().change('ar');
      await sl<ThemeCubit>().change(ThemeMode.dark);
      await tester.pumpAndSettle();
      final darkPreview = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: find.text('الوضع الداكن'),
      );
      await tester.ensureVisible(darkPreview);
      await tester.tap(darkPreview);
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(AdminBrandingPage))),
        TextDirection.rtl,
      );
      expect(
        Theme.of(tester.element(find.byType(AdminBrandingPage)))
            .textTheme
            .bodyMedium!
            .fontFamily,
        'NotoSansArabic',
      );
      await tester.ensureVisible(find.byType(BrandingPreview));
      await tester.pumpAndSettle();
      debugPrint('BRANDING_SCREENSHOT: 03_ar_dark');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await sl<LanguageCubit>().change('en');
      await sl<ThemeCubit>().change(ThemeMode.light);
      await tester.pumpAndSettle();
      await flow.tap(tester, 'Restore original branding as draft');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK').last);
      await flow.waitFor(
        tester,
        find.text(
          'Configuration restored as a draft. Review and publish to apply.',
        ),
      );
      expect(
        sl<BrandingCubit>().state.config.text('application_name'),
        'Nile QA',
      );
      await flow.tap(tester, 'Publish changes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK').last);
      await flow.waitFor(tester, find.text('Branding published successfully.'));
      await tester.pumpAndSettle();
      expect(sl<BrandingCubit>().state.config, BrandingConfig.defaults);
      expect(
        Theme.of(tester.element(find.byType(AdminBrandingPage))).colorScheme,
        AppTheme.light().colorScheme,
      );
      // Restore previous immutable publication as a new draft; never rewrites history.
      doc = await repository.editor();
      doc = await repository.restore(doc.revision, version: first);
      expect(doc.draft!.text('application_name'), 'Nile QA');
      expect(doc.active.config, BrandingConfig.defaults);
      doc = await repository.publish(doc.revision);
      await sl<BrandingCubit>().refresh(force: true);
      await tester.pumpAndSettle();
      expect(doc.active.version, greaterThan(first));
      expect(
        sl<BrandingCubit>().state.config.text('application_name'),
        'Nile QA',
      );
      // Leave only the QA database on the original branding; no demo publication.
      doc = await repository.restore(doc.revision);
      await repository.publish(doc.revision);
      await sl<BrandingCubit>().refresh(force: true);
      await tester.pumpAndSettle();
      expect(sl<BrandingCubit>().state.config, BrandingConfig.defaults);
      final response = await sl<DioClient>().get('/branding');
      expect((response as Map)['config']['application_name'], isNull);
      expect(tester.takeException(), isNull);
      debugPrint(
        'BRANDING_QA_PASSED: actual auth, draft isolation, PNG upload, publish, typography, RTL, defaults and history',
      );
    },
    skip: !const bool.fromEnvironment('RUN_BRANDING_QA'),
  );
}
