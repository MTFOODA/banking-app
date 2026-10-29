import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/core/routing/app_routes.dart';
import 'package:faisal_app/core/routing/route_guard.dart';
import 'package:faisal_app/core/theme/app_colors.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/products/domain/entities/discover_entities.dart';
import 'package:faisal_app/features/products/domain/repositories/discover_repository.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/support/data/repositories/bank_directory_repository_impl.dart';
import 'package:faisal_app/features/support/domain/entities/bank_branch.dart';
import 'package:faisal_app/features/support/domain/repositories/bank_directory_repository.dart';
import 'package:faisal_app/features/support/presentation/pages/branch_directory_page.dart';
import 'package:faisal_app/features/support/presentation/pages/public_bank_services_page.dart';
import 'package:faisal_app/features/support/presentation/services/bank_contact_links.dart';
import 'package:faisal_app/l10n/app_localizations.dart';

import 'admin_workflow_test.dart' as admin;
import 'security_flows_test.dart' as fixtures;

class Links extends BankContactLinks {
  final opened = <Uri>[];
  bool available = true;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return available;
  }
}

class Directory extends BankDirectoryRepository {
  Directory(this.branches);
  final List<BankBranch> branches;
  bool fail = false;
  @override
  Future<List<BankBranch>> loadBranches() async {
    if (fail) throw const AppException(code: AppErrorCode.unknown);
    return branches;
  }
}

class WaitingNotices extends admin.PublicRepository {
  final response = Completer<List<Announcement>>();
  @override
  Future<List<Announcement>> fetchPublicAnnouncements({String? bankCode}) =>
      response.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late admin.PublicRepository notices;
  late Links links;
  late Directory directory;
  late LanguageCubit language;
  late ThemeCubit theme;
  setUp(() async {
    notices = admin.PublicRepository()..empty = true;
    links = Links();
    directory = Directory(await BankDirectoryRepositoryImpl().loadBranches());
    language = LanguageCubit(null, fixtures.FakeSettings());
    theme = ThemeCubit(null, fixtures.FakeSettings());
    sl.registerSingleton<DiscoverRepository>(notices);
    sl.registerSingleton<BankDirectoryRepository>(directory);
    sl.registerSingleton<BankContactLinks>(links);
  });
  tearDown(() async {
    await language.close();
    await theme.close();
    await sl.reset();
  });
  Future<GoRouter> pump(
    WidgetTester t, {
    String locale = 'en',
    bool dark = false,
    double scale = 1,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.preLogin,
      routes: [
        GoRoute(
          path: AppRoutes.preLogin,
          builder: (_, _) => const BankNoticesPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('Login destination')),
        ),
        GoRoute(
          path: AppRoutes.branches,
          builder: (_, _) => const BranchDirectoryPage(),
        ),
        GoRoute(
          path: AppRoutes.atms,
          builder: (_, _) => const AtmLocatorPage(),
        ),
        GoRoute(
          path: AppRoutes.callCenter,
          builder: (_, _) => const CallCenterPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LanguageCubit>.value(value: language),
          BlocProvider<ThemeCubit>.value(value: theme),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    return router;
  }

  Future<void> tap(WidgetTester t, String key) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pump();
    final finder = find.byKey(ValueKey(key));
    await t.ensureVisible(finder);
    await t.pump();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  test('branch directory preserves 44 IDs with distinct official Giza and Dokki pins and requested order', () async {
    final branches = await BankDirectoryRepositoryImpl().loadBranches();
    expect(branches.length, 44);
    expect(branches.map((b) => b.id).toSet().length, 44);
    expect(branches.first.name, contains('26'));
    for (final branch in branches) {
      expect(branch.address, isNotEmpty);
      expect(branch.governorate, isNotEmpty);
      expect(branch.mapsUri.host, 'www.google.com');
      expect(branch.mapsUri.queryParameters['api'], '1');
      if (!['15', '16'].contains(branch.id)) {
        expect(branch.mapsUri.queryParameters['query'], contains(branch.name));
      }
    }
    expect(branches[1].id, '15');
    expect(branches[1].name, 'الجيزة - المبنى الإداري');
    expect(branches[1].mapsUri.queryParameters['query'], '30.039497,31.218555');
    final dokki = branches.singleWhere((b) => b.id == '16');
    expect(dokki.name, 'الدقي');
    expect(dokki.mapsUri.queryParameters['query'], '30.0564606,31.2115721');
    expect(dokki.mapsUri, isNot(branches[1].mapsUri));
    expect(branches.map((b) => b.id), [
      '1',
      '15',
      ...List.generate(13, (i) => '${i + 2}'),
      ...List.generate(29, (i) => '${i + 16}'),
    ]);
  });
  test('public service routes allow signed-out access but preserve protected routes and mandatory password setup', () {
    for (final path in [
      AppRoutes.branches,
      AppRoutes.atms,
      AppRoutes.callCenter,
    ]) {
      expect(
        resolveRedirect(
          auth: const AuthState(status: AuthStatus.unauthenticated),
          location: path,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          auth: const AuthState(status: AuthStatus.firstLoginRequired),
          location: path,
        ),
        AppRoutes.passwordSetup,
      );
    }
    expect(
      resolveRedirect(
        auth: const AuthState(status: AuthStatus.unauthenticated),
        location: AppRoutes.accounts,
      ),
      AppRoutes.login,
    );
  });
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'four public service cards work without announcements, $locale narrow and large text',
      (t) async {
        t.view.physicalSize = const Size(320, 740);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final router = await pump(
          t,
          locale: locale,
          dark: locale == 'ar',
          scale: 1.5,
        );
        await t.pumpAndSettle();
        for (final key in [
          'notice_continue_login',
          'public_branches',
          'public_atms',
          'public_call_center',
        ]) {
          expect(find.byKey(ValueKey(key)), findsOneWidget);
          expect(
            t.widget<Material>(find.byKey(ValueKey(key))).color,
            key == 'notice_continue_login'
                ? FaisalColors.primaryGreen
                : FaisalColors.white,
          );
        }
        expect(
          Directionality.of(t.element(find.byType(BankNoticesPage))),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        await tap(t, 'public_branches');
        expect(find.byType(BranchDirectoryPage), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
        await tap(t, 'public_atms');
        expect(find.byType(AtmLocatorPage), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
        await tap(t, 'public_call_center');
        expect(find.byType(CallCenterPage), findsOneWidget);
        router.pop();
        await t.pumpAndSettle();
        await tap(t, 'notice_continue_login');
        expect(find.text('Login destination'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'announcements stay below the four cards and a failed fetch can retry without blocking services',
    (t) async {
      notices.fail = true;
      await pump(t);
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('notice_continue_login')),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      notices.fail = false;
      notices.empty = false;
      await t.ensureVisible(find.text('Try again'));
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      final notice = find.text('Important service notice');
      expect(notice, findsOneWidget);
      expect(
        t.getTopLeft(notice).dy,
        greaterThan(
          t.getBottomLeft(find.byKey(const ValueKey('public_call_center'))).dy,
        ),
      );
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('slow announcements do not block navigation to public services', (
    t,
  ) async {
    await sl.unregister<DiscoverRepository>();
    final waiting = WaitingNotices();
    sl.registerSingleton<DiscoverRepository>(waiting);
    await pump(t);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tap(t, 'public_call_center');
    expect(find.byType(CallCenterPage), findsOneWidget);
    waiting.response.complete([]);
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'branch search normalizes Arabic and filters governorate; map uses original source link',
    (t) async {
      await pump(t);
      await tap(t, 'public_branches');
      expect(find.text('Results: 44'), findsOneWidget);
      await tap(t, 'branch_map_15');
      expect(
        links.opened.single.queryParameters['query'],
        '30.039497,31.218555',
      );
      await t.enterText(find.byKey(const ValueKey('branch_search')), 'الازهر');
      await t.pumpAndSettle();
      expect(find.text('Results: 1'), findsOneWidget);
      expect(find.text('الأزهر'), findsOneWidget);
      await tap(t, 'branch_map_2');
      expect(links.opened.last.queryParameters['query'], contains('106'));
      await t.enterText(
        find.byKey(const ValueKey('branch_search')),
        'no matching address',
      );
      await t.pumpAndSettle();
      expect(find.textContaining('No branches match'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('branch_search')), '');
      await t.pumpAndSettle();
      await tap(t, 'branch_governorate');
      final popup = find.byType(Scrollable).last;
      final choice = find.descendant(of: popup, matching: find.text('القاهرة'));
      await t.scrollUntilVisible(choice, 120, scrollable: popup);
      await t.pumpAndSettle();
      await t.tap(choice);
      await t.pumpAndSettle();
      final expected = directory.branches
          .where((b) => b.governorate == 'القاهرة')
          .length;
      expect(find.text('Results: $expected'), findsOneWidget);
      expect(expected, lessThan(44));
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'directory failure retries and external URL failure is recoverable',
    (t) async {
      directory.fail = true;
      final router = await pump(t);
      await tap(t, 'public_branches');
      expect(find.textContaining('Could not load the branch'), findsOneWidget);
      directory.fail = false;
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('Results: 44'), findsOneWidget);
      router.pop();
      await t.pumpAndSettle();
      await tap(t, 'public_atms');
      links.available = false;
      await tap(t, 'atm_official_locator');
      expect(find.textContaining('Could not open the link.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'ATM search encodes area; official locator and call center dial/copy work',
    (t) async {
      final router = await pump(t);
      await tap(t, 'public_atms');
      await t.enterText(
        find.byKey(const ValueKey('atm_area')),
        'مدينة نصر & test',
      );
      await tap(t, 'atm_map_search');
      expect(
        links.opened.last.queryParameters['query'],
        'Faisal Islamic Bank ATM مدينة نصر & test',
      );
      await tap(t, 'atm_official_locator');
      expect(links.opened.last, BankContactLinks.locator);
      router.pop();
      await t.pumpAndSettle();
      await tap(t, 'public_call_center');
      await tap(t, 'call_center_dial');
      expect(links.opened.last.toString(), 'tel:19851');
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tap(t, 'call_center_copy');
      expect(copied, '19851');
      expect(find.text('Phone number copied'), findsOneWidget);
      await tap(t, 'call_center_website');
      expect(links.opened.last.host, 'www.faisalbank.com.eg');
      await t.pumpWidget(const SizedBox());
    },
  );
}
