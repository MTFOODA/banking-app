import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/features/banks/domain/entities/bank_definition.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/theme/branding_theme.dart';
import 'package:faisal_app/core/theme/faisal_palette.dart';
import 'package:faisal_app/core/widgets/faisal_logo.dart';
import 'package:faisal_app/features/branding/domain/entities/branding_config.dart';
import 'package:faisal_app/features/branding/data/branding_asset_cache.dart';
import 'package:faisal_app/features/branding/domain/repositories/branding_repository.dart';
import 'package:faisal_app/features/branding/presentation/cubit/branding_cubit.dart';
import 'package:faisal_app/features/branding/presentation/cubit/branding_editor_cubit.dart';
import 'package:faisal_app/features/branding/presentation/pages/admin_branding_page.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_runtime.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/l10n/app_localizations.dart';

import 'admin_workflow_test.dart' as admin;
import 'security_flows_test.dart' as fixtures;

BrandingConfig custom({String name = 'QA Brand'}) {
  final data = BrandingConfig.defaults.toJson();
  data['welcome_message'] = name;
  data['bank_overrides'] = {
    'faisal': {
      'welcome_message': name,
      'primary_font': 'NotoSans',
      'arabic_font': 'NotoSansArabic',
      'english_font': 'NotoSans',
      'font_size_scale': 1.1,
    },
  };
  return BrandingConfig.fromJson(data);
}

class FakeBranding extends BrandingRepository {
  BrandingSnapshot active = BrandingSnapshot(0, BrandingConfig.defaults);
  BrandingConfig? draft;
  int revision = 0, fetches = 0;
  bool fail = false, conflict = false;
  Completer<BrandingSnapshot?>? pending;
  final publications = <BrandingHistoryEntry>[];
  final versions = <int?>[];
  int assetFetches = 0;
  @override
  Future<Uint8List> fetchAsset(String url) async {
    assetFetches++;
    check();
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWQAAAABJRU5ErkJggg==',
    );
  }

  void check() {
    if (conflict) {
      throw const AppException(code: AppErrorCode.conflict);
    }
    if (fail) {
      throw const AppException(code: AppErrorCode.network);
    }
  }

  BrandingEditorDocument get document =>
      BrandingEditorDocument(revision: revision, active: active, draft: draft);
  @override
  Future<BrandingSnapshot?> fetch({int? knownVersion}) async {
    fetches++;
    versions.add(knownVersion);
    check();
    if (pending != null) {
      return pending!.future;
    }
    return active.version == knownVersion ? null : active;
  }

  @override
  Future<BrandingEditorDocument> editor() async {
    check();
    return document;
  }

  @override
  Future<BrandingEditorDocument> save(
    int version,
    BrandingConfig config,
  ) async {
    check();
    expect(version, revision);
    draft = config;
    revision++;
    return document;
  }

  @override
  Future<BrandingEditorDocument> publish(int version) async {
    check();
    expect(version, revision);
    revision++;
    active = BrandingSnapshot(revision, draft!);
    draft = null;
    publications.insert(
      0,
      BrandingHistoryEntry(revision, DateTime.utc(2026, 10, 28), active.config),
    );
    return document;
  }

  @override
  Future<BrandingEditorDocument> restore(
    int revision, {
    int? version,
    String? bankCode,
  }) async {
    check();
    draft = version == null
        ? BrandingConfig.defaults
        : publications.firstWhere((p) => p.version == version).config;
    this.revision++;
    return document;
  }

  @override
  Future<List<BrandingHistoryEntry>> history({int? before}) async {
    check();
    return publications;
  }

  @override
  Future<String> upload(Uint8List bytes, String filename) async {
    check();
    return '/branding/assets/${'a' * 64}.png';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('default configuration preserves original ThemeData and customer preference', () {
    for (final brightness in Brightness.values) {
      final original = brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark();
      final theme = BrandingTheme.build(
        BrandingConfig.defaults,
        brightness,
        'ar',
      );
      expect(theme.colorScheme, original.colorScheme);
      expect(theme.textTheme, original.textTheme);
      expect(theme.scaffoldBackgroundColor, original.scaffoldBackgroundColor);
      expect(theme.cardTheme, original.cardTheme);
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
        original.filledButtonTheme.style!.backgroundColor!.resolve({}),
      );
    }
    expect(
      BrandingTheme.mode(BrandingConfig.defaults, ThemeMode.dark),
      ThemeMode.dark,
    );
  });
  test('custom colors, typography, buttons and palette apply in both languages and modes', () {
    final config = custom().forBank(BankCatalogue.bundled.find('faisal')!);
    for (final language in ['ar', 'en']) {
      for (final brightness in Brightness.values) {
        final theme = BrandingTheme.build(config, brightness, language);
        expect(theme.colorScheme.primary, config.color('primary', brightness));
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          config.color('button_background', brightness),
        );
        expect(theme.cardTheme.color, config.color('card', brightness));
        expect(
          theme.extension<FaisalPalette>()!.headerGradient.first,
          config.color('primary', brightness),
        );
        expect(
          theme.textTheme.bodyMedium!.fontFamily,
          language == 'ar' ? 'NotoSansArabic' : 'NotoSans',
        );
        expect(theme.textTheme.bodyMedium!.fontSize, closeTo(15.4, .001));
      }
    }
  });
  test(
    'invalid schema, unsafe assets, missing fonts, contrast and scale rejected',
    () {
      for (final change in [
        <String, dynamic>{'schema_version': 2},
        {'logo_url': 'https://invalid.example/logo.png'},
        {'primary_font': 'RemoteFont'},
        {'font_size_scale': 3},
        {'heading_font_weight': 900},
        {'welcome_message': 'Bad\u202e'},
      ]) {
        expect(
          () => BrandingConfig.fromJson({
            ...BrandingConfig.defaults.toJson(),
            ...change,
          }),
          throwsFormatException,
        );
      }
      final bad = BrandingConfig.defaults.toJson();
      bad['light']['text_primary'] = '#FFFFFF';
      expect(() => BrandingConfig.fromJson(bad), throwsFormatException);
    },
  );
  test('offline startup applies cached configuration immediately and keeps it on network failure', () async {
    final snapshot = BrandingSnapshot(5, custom());
    SharedPreferences.setMockInitialValues({
      brandingCacheKey: jsonEncode(snapshot.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = FakeBranding()..fail = true;
    final cubit = BrandingCubit(repository, preferences);
    expect(cubit.state, snapshot);
    await cubit.refresh();
    expect(cubit.state, snapshot);
    await cubit.close();
  });
  test('invalid cache falls back; unchanged fetches do not emit; requests are coalesced', () async {
    SharedPreferences.setMockInitialValues({brandingCacheKey: 'invalid json'});
    final repository = FakeBranding()..pending = Completer<BrandingSnapshot?>();
    final cubit = BrandingCubit(
      repository,
      await SharedPreferences.getInstance(),
    );
    expect(cubit.state.config, BrandingConfig.defaults);
    final emitted = <BrandingSnapshot>[];
    final subscription = cubit.stream.listen(emitted.add);
    final first = cubit.refresh();
    final second = cubit.refresh(force: true);
    expect(repository.fetches, 1);
    repository.pending!.complete(null);
    await Future.wait([first, second]);
    expect(emitted, isEmpty);
    expect(repository.versions, [0]);
    await cubit.refresh();
    expect(repository.fetches, 1);
    await subscription.cancel();
    await cubit.close();
  });
  test(
    'latest valid configuration persists; older versions are ignored',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = FakeBranding()..active = BrandingSnapshot(3, custom());
      final cubit = BrandingCubit(repository, prefs);
      await cubit.refresh();
      expect(cubit.state.version, 3);
      expect(prefs.getString(brandingCacheKey), isNotNull);
      repository.active = BrandingSnapshot(1, BrandingConfig.defaults);
      await cubit.refresh(force: true);
      expect(cubit.state.version, 3);
      await cubit.close();
    },
  );
  test(
    'branding raster cache survives offline restart and coalesces downloads',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = FakeBranding();
      final cache = BrandingAssetCache(repository, preferences);
      final url = '/branding/assets/${'b' * 64}.png';
      final result = await Future.wait([cache.load(url), cache.load(url)]);
      expect(result.first, isNotNull);
      expect(repository.assetFetches, 1);
      repository.fail = true;
      final offline = BrandingAssetCache(repository, preferences);
      expect(await offline.load(url), isNotNull);
      expect(repository.assetFetches, 1);
    },
  );
  test('restoring defaults and older history creates drafts until explicit publish', () async {
    final repository = FakeBranding();
    final cubit = BrandingEditorCubit(repository);
    await cubit.load();
    cubit.edit('welcome_message', 'First');
    await cubit.save();
    await cubit.publish();
    final first = repository.active.version;
    await cubit.restore();
    expect(repository.active.config.text('welcome_message'), 'First');
    expect(cubit.state.values!['welcome_message'], isNull);
    await cubit.publish();
    expect(repository.active.config, BrandingConfig.defaults);
    await cubit.restore(version: first);
    expect(repository.active.config, BrandingConfig.defaults);
    await cubit.publish();
    expect(repository.active.config.text('welcome_message'), 'First');
    await cubit.close();
  });
  test('save draft is isolated; publish requires saved draft; conflicts and upload failures preserve edits', () async {
    final repository = FakeBranding();
    final cubit = BrandingEditorCubit(repository);
    await cubit.load();
    cubit.edit('welcome_message', 'New brand');
    await cubit.publish();
    expect(cubit.state.error, 'saveFirst');
    await cubit.save();
    expect(repository.active.config, BrandingConfig.defaults);
    expect(cubit.state.dirty, isFalse);
    await cubit.publish();
    expect(repository.active.config.text('welcome_message'), 'New brand');
    cubit.edit('welcome_message', 'Keep this edit');
    repository.conflict = true;
    await cubit.save();
    expect(cubit.state.error, 'conflict');
    expect(cubit.state.values!['welcome_message'], 'Keep this edit');
    repository.conflict = false;
    repository.fail = true;
    await cubit.upload('logo_url', Uint8List(4), 'logo.png');
    expect(cubit.state.values!['welcome_message'], 'Keep this edit');
    await cubit.close();
  });
  testWidgets(
    'theme updates preserve router, navigation and entered form values',
    (tester) async {
      final repository = FakeBranding();
      final cubit = BrandingCubit(repository, null);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Column(
                children: [
                  const FaisalLogo(showWordmark: true),
                  TextFormField(key: const Key('retained-form')),
                  TextButton(
                    onPressed: () => context.push('/details'),
                    child: const Text('Existing action'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/details',
            builder: (_, _) =>
                const Scaffold(body: Text('Existing details screen')),
          ),
        ],
      );
      var rebuilds = 0;
      Widget app() => BrandingRuntime(
        cubit: cubit,
        builder: (context, config) {
          rebuilds++;
          return MaterialApp.router(
            theme: BrandingTheme.build(config, Brightness.light, 'en'),
            routerConfig: router,
          );
        },
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('retained-form')),
        'pending transfer draft',
      );
      final before = rebuilds;
      await cubit.refresh(force: true);
      await tester.pumpAndSettle();
      expect(rebuilds, before);
      repository.active = BrandingSnapshot(1, custom());
      await cubit.refresh(force: true);
      await tester.pumpAndSettle();
      expect(find.text('Banking App'), findsOneWidget);
      expect(find.text('QA Brand'), findsNothing);
      expect(find.text('pending transfer draft'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/');
      await tester.tap(find.text('Existing action'));
      await tester.pumpAndSettle();
      expect(find.text('Existing details screen'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('pending transfer draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await cubit.close();
    },
  );
  for (final locale in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'editor preview, save, publishing and RTL $locale dark=$dark',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(412, 915));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final repository = FakeBranding();
          final auth = admin.StaffBloc();
          final language = LanguageCubit(null, fixtures.FakeSettings()),
              theme = ThemeCubit(null, fixtures.FakeSettings());
          addTearDown(() async {
            await auth.close();
            await language.close();
            await theme.close();
          });
          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: auth),
                BlocProvider<LanguageCubit>.value(value: language),
                BlocProvider<ThemeCubit>.value(value: theme),
              ],
              child: MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: AdminBrandingPage(
                  repository: repository,
                  onPublished: () async {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(AdminBrandingPage));
          final l = AppLocalizations.of(context);
          expect(
            Directionality.of(context),
            locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          final name = find.byKey(const ValueKey('1-faisal-welcome_message'));
          await tester.ensureVisible(name);
          await tester.enterText(name, 'Example Brand');
          await tester.pumpAndSettle();
          expect(repository.active.config, BrandingConfig.defaults);
          final save = find.byKey(const Key('branding-save'));
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(find.text(l.brandingSaved), findsOneWidget);
          expect(
            repository.draft!
                .forBank(BankCatalogue.bundled.find('faisal')!)
                .text('welcome_message'),
            'Example Brand',
          );
          final publish = find.byKey(const Key('branding-publish'));
          await tester.ensureVisible(publish);
          await tester.tap(publish);
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(MaterialLocalizations.of(context).okButtonLabel).last,
          );
          await tester.pumpAndSettle();
          expect(
            repository.active.config
                .forBank(BankCatalogue.bundled.find('faisal')!)
                .text('welcome_message'),
            'Example Brand',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
