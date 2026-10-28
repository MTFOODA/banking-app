import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/routing/app_routes.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:faisal_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:faisal_app/features/admin/domain/entities/admin_entities.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_request_page.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_requests_page.dart';
import 'package:faisal_app/features/admin/presentation/pages/admin_announcement_form.dart';
import 'package:faisal_app/features/admin/presentation/cubit/admin_content_cubit.dart';
import 'package:faisal_app/features/admin/presentation/cubit/admin_request_detail_cubit.dart';
import 'package:faisal_app/features/products/domain/entities/discover_entities.dart';
import 'package:faisal_app/features/products/domain/repositories/discover_repository.dart';
import 'package:faisal_app/features/products/presentation/pages/bank_notices_page.dart';
import 'package:faisal_app/features/authentication/domain/entities/auth_entities.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/features/requests/domain/entities/request_entities.dart';

import 'security_flows_test.dart' as fixtures;

Announcement notice() => const Announcement(
  id: 'notice',
  titleEn: 'Important service notice',
  titleAr: 'تنبيه مهم للخدمات',
  bodyEn: 'Fictional bank service information.',
  bodyAr: 'معلومات تجريبية عن خدمات البنك.',
  category: 'announcement',
  priority: 'high',
  status: 'published',
  displayLocation: 'pre_login',
);

class StaffBloc extends AuthBloc {
  StaffBloc() : super(fixtures.FakeAuth(), SessionStore()) {
    emit(
      const AuthState(
        status: AuthStatus.authenticated,
        user: SessionUser(
          id: 'staff',
          maskedIdentifier: '***01',
          loginType: 'staff',
          mustChangePassword: false,
          permissions: ['admin.dashboard.view', 'admin.requests.decide'],
        ),
      ),
    );
  }
}

class WorkflowRepository implements AdminRepository {
  bool failDetail = false;
  String status = 'submitted';
  int decisions = 0;
  String? reason;
  ServiceRequestEntity get request => ServiceRequestEntity(
    id: 'request',
    reference: 'REQ-WIDGET-001',
    requestType: 'account_open',
    status: status,
    priority: 'normal',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    decisionReason: reason,
    formData: const {'product_code': 'AP-CURRENT'},
  );
  @override
  Future<AdminRequestDetail> fetchRequest(String id) async {
    if (failDetail) throw fixtures.failure;
    return AdminRequestDetail(request: request);
  }

  @override
  Future<ServiceRequestEntity> approveRequest(
    String id, {
    String? reason,
    String? explanation,
  }) async {
    decisions++;
    status = 'completed';
    return request;
  }

  @override
  Future<ServiceRequestEntity> rejectRequest(
    String id, {
    required String reason,
    String? explanation,
  }) async {
    decisions++;
    status = 'rejected';
    this.reason = reason;
    return request;
  }

  @override
  Future<AdminRequestPage> fetchRequests({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => AdminRequestPage(
    items: [
      AdminRequestItem(
        id: 'request',
        reference: 'REQ-WIDGET-001',
        customerId: 'customer',
        customerName: 'Fictional Customer',
        requestType: 'account_open',
        status: this.status,
        priority: 'normal',
      ),
    ],
    page: 1,
    total: 1,
    hasNext: false,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PublicRepository implements DiscoverRepository {
  bool fail = false, empty = false;
  @override
  Future<List<Announcement>> fetchPublicAnnouncements() async {
    if (fail) throw fixtures.failure;
    return empty ? [] : [notice()];
  }

  @override
  Future<Announcement> fetchAnnouncement(String id) async => notice();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReceiptRepository extends WorkflowRepository {
  @override
  Future<Announcement> createAnnouncement(Map<String, dynamic> payload) async =>
      notice();
  @override
  Future<List<Announcement>> fetchAnnouncements() async =>
      throw fixtures.failure;
}

void main() {
  test('committed announcement survives a failed library refresh', () async {
    final c = AdminContentCubit(ReceiptRepository());
    expect(await c.createAnnouncement({}), isTrue);
    expect(c.state.announcements.single.id, 'notice');
    expect(c.state.actionError, isNotNull);
    await c.close();
  });
  test('committed decision survives a failed detail refresh', () async {
    final r = WorkflowRepository();
    final c = AdminRequestDetailCubit(r, 'request');
    await c.load();
    r.failDetail = true;
    expect(await c.decide(approve: true, reason: ''), isTrue);
    expect(c.state.detail!.request.status, 'completed');
    expect(c.state.actionError, isNotNull);
    await c.close();
  });
  late WorkflowRepository repo;
  late PublicRepository public;
  late StaffBloc bloc;
  late LanguageCubit language;
  late ThemeCubit theme;
  setUp(() {
    repo = WorkflowRepository();
    public = PublicRepository();
    bloc = StaffBloc();
    language = LanguageCubit(null, fixtures.FakeSettings());
    theme = ThemeCubit(null, fixtures.FakeSettings());
    sl.registerSingleton<AdminRepository>(repo);
    sl.registerSingleton<DiscoverRepository>(public);
  });
  tearDown(() async {
    await bloc.close();
    await language.close();
    await theme.close();
    await sl.reset();
  });
  Future<void> pump(
    WidgetTester t,
    Widget page, {
    String locale = 'en',
    bool dark = false,
  }) async {
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: bloc),
          BlocProvider<LanguageCubit>.value(value: language),
          BlocProvider<ThemeCubit>.value(value: theme),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  testWidgets('reject requires a meaningful reason and records the decision', (
    t,
  ) async {
    await pump(t, const AdminRequestDetailsPage(id: 'request'));
    await tap(t, find.byKey(const ValueKey('admin_reject')));
    await tap(t, find.byKey(const ValueKey('admin_decision_confirm')));
    expect(repo.decisions, 0);
    expect(find.textContaining('at least 5'), findsOneWidget);
    await t.enterText(
      find.byKey(const ValueKey('admin_decision_reason')),
      'Missing fictional documents',
    );
    await tap(t, find.byKey(const ValueKey('admin_decision_confirm')));
    expect(repo.decisions, 1);
    expect(repo.reason, 'Missing fictional documents');
    expect(find.byKey(const ValueKey('admin_reject')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('approve waits for explicit confirmation', (t) async {
    await pump(t, const AdminRequestDetailsPage(id: 'request'));
    await tap(t, find.byKey(const ValueKey('admin_approve')));
    expect(repo.decisions, 0);
    await tap(t, find.byKey(const ValueKey('admin_decision_confirm')));
    expect(repo.decisions, 1);
    expect(repo.status, 'completed');
    await t.pumpWidget(const SizedBox());
  });
  for (final locale in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'admin queue and public notice use $locale theme dark=$dark on narrow screens',
        (t) async {
          t.view.physicalSize = const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await pump(t, const AdminRequestsPage(), locale: locale, dark: dark);
          expect(find.text('REQ-WIDGET-001'), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await pump(t, const BankNoticesPage(), locale: locale, dark: dark);
          expect(
            find.text(
              locale == 'ar' ? 'تنبيه مهم للخدمات' : 'Important service notice',
            ),
            findsOneWidget,
          );
          expect(
            Directionality.of(t.element(find.byType(BankNoticesPage))),
            locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'announcement form validates bilingual content and saves chosen location',
    (t) async {
      Map<String, dynamic>? saved;
      await pump(
        t,
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AdminAnnouncementForm(
                  onSave: (p) async {
                    saved = p;
                    return true;
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tap(t, find.text('Open'));
      await tap(t, find.byKey(const ValueKey('announcement_save')));
      expect(saved, isNull);
      for (final key in [
        'announcement_title_en',
        'announcement_title_ar',
        'announcement_body_en',
        'announcement_body_ar',
      ]) {
        await t.enterText(find.byKey(ValueKey(key)), 'Fictional message');
      }
      await tap(t, find.byKey(const ValueKey('announcement_location')));
      await tap(t, find.text('Before sign-in').last);
      await tap(t, find.byKey(const ValueKey('announcement_save')));
      expect(saved?['display_location'], 'pre_login');
      expect(saved?['status'], 'draft');
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('empty public portal stays visible until explicit sign-in', (
    t,
  ) async {
    public.empty = true;
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
      ],
    );
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LanguageCubit>.value(value: language),
          BlocProvider<ThemeCubit>.value(value: theme),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Login destination'), findsNothing);
    expect(find.byKey(const ValueKey('public_branches')), findsOneWidget);
    await tap(t, find.byKey(const ValueKey('notice_continue_login')));
    expect(find.text('Login destination'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    router.dispose();
  });
}
