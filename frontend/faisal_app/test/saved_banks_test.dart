import 'dart:async';

import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/core/network/dio_client.dart';
import 'package:faisal_app/core/routing/app_routes.dart';
import 'package:faisal_app/core/routing/route_guard.dart';
import 'package:faisal_app/core/security/biometric_service.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:faisal_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:faisal_app/features/authentication/data/repositories/local_saved_banks_repository.dart';
import 'package:faisal_app/features/authentication/domain/entities/auth_entities.dart';
import 'package:faisal_app/features/authentication/domain/repositories/saved_banks_repository.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/authentication/presentation/cubit/saved_banks_cubit.dart';
import 'package:faisal_app/features/authentication/presentation/pages/saved_banks_page.dart';
import 'package:faisal_app/features/banks/presentation/bank_logo.dart';
import 'package:faisal_app/features/banks/presentation/bank_selection_cubit.dart';
import 'package:faisal_app/features/branding/presentation/widgets/branding_scope.dart';
import 'package:faisal_app/features/settings/presentation/cubit/appearance_cubits.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'security_flows_test.dart' as fixtures;

SessionUser customer(String id, String bank, {bool setup = false}) =>
    SessionUser(
      id: id,
      username: 'user$id',
      maskedIdentifier: '***',
      loginType: 'customer',
      mustChangePassword: setup,
      profile: CustomerProfileEntity(
        id: 'profile$id',
        customerNumber: '***',
        firstNameEn: 'QA',
        lastNameEn: 'Customer',
        firstNameAr: 'عميل',
        lastNameAr: 'تجريبي',
        bankCode: bank,
      ),
    );
Map<String, dynamic> payload(String id, String bank) => {
  'access_token': 'access$id',
  'refresh_token': 'rotated$id',
  'user': {
    'id': id,
    'username': 'user$id',
    'login_type': 'customer',
    'must_change_password': false,
    'profile': {'id': 'profile$id', 'bank_code': bank},
  },
};

class Remote extends AuthRemoteDataSource {
  Remote(SessionStore store) : super(DioClient(sessionStore: store));
  Map<String, dynamic> data = payload('a', 'cib');
  Future<Map<String, dynamic>> Function()? refreshHandler;
  Future<Map<String, dynamic>> Function()? registrationHandler;
  int refreshCalls = 0, logoutCalls = 0;
  @override
  Future<Map<String, dynamic>> refresh(String token) async {
    refreshCalls++;
    return refreshHandler == null ? data : refreshHandler!();
  }

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required bool rememberDevice,
    String? bankCode,
  }) async => data;
  @override
  Future<Map<String, dynamic>> me() async =>
      data['user'] as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> securityPost(
    String path,
    Map<String, dynamic> body,
  ) async => registrationHandler == null ? data : registrationHandler!();
  @override
  Future<void> logout({String? refreshToken, bool allDevices = false}) async {
    logoutCalls++;
  }
}

Future<AuthState> send(
  AuthBloc bloc,
  AuthEvent event,
  bool Function(AuthState) match,
) async {
  final next = bloc.stream
      .firstWhere(match)
      .timeout(const Duration(seconds: 3));
  bloc.add(event);
  return next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late SessionStore store;
  late LocalSavedBanksRepository saved;
  late Remote remote;
  late AuthRepositoryImpl repository;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = SessionStore();
    saved = LocalSavedBanksRepository(prefs, store);
    remote = Remote(store);
    repository = AuthRepositoryImpl(remote, store, savedBanks: saved);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await sl.reset();
    await saved.dispose();
  });

  test('two banks and a second identity at one bank are retained; metadata has no credentials', () async {
    await saved.remember(customer('a', 'cib'), 'secret-a');
    await saved.remember(customer('b', 'nbe'), 'secret-b');
    await saved.remember(customer('c', 'cib'), 'secret-c');
    await saved.remember(customer('a', 'cib'), 'rotated-a');
    expect(saved.entries.map((e) => e.userId), ['a', 'c', 'b']);
    final metadata = prefs.getString(LocalSavedBanksRepository.key)!;
    expect(metadata, isNot(contains('secret')));
    expect(metadata, isNot(contains('rotated')));
    final restored = LocalSavedBanksRepository(prefs, store);
    expect(restored.entries, saved.entries);
    expect(await restored.credential(restored.entries.first), 'rotated-a');
    await restored.dispose();
  });

  test('unknown bank/corrupt metadata is ignored and staff/unfinished customers are never saved', () async {
    await prefs.setString(LocalSavedBanksRepository.key, '[{"bad":true}]');
    final invalid = LocalSavedBanksRepository(prefs, store);
    expect(invalid.entries, isEmpty);
    await invalid.dispose();
    await saved.remember(customer('a', 'cib', setup: true), 'secret');
    await saved.remember(
      const SessionUser(
        id: 'admin',
        username: 'devadmin',
        maskedIdentifier: '***',
        loginType: 'staff',
        mustChangePassword: false,
      ),
      'staffsecret',
    );
    expect(saved.entries, isEmpty);
  });

  test('startup shows chooser without activating a saved customer or contacting server', () async {
    await repository.login(
      identifier: 'usera',
      password: 'unused',
      rememberDevice: true,
      bankCode: 'cib',
    );
    final auth = AuthBloc(repository, store, savedBanks: saved);
    await send(
      auth,
      const AuthStarted(),
      (s) => s.status == AuthStatus.unauthenticated,
    );
    expect(store.hasSession, isFalse);
    expect(remote.refreshCalls, 0);
    expect(await saved.credential(saved.entries.single), 'rotateda');
    await auth.close();
  });

  test('legacy session is verified before migration; Android biometric upgrade requires re-enablement', () async {
    await store.saveSession(
      accessToken: 'legacy',
      refreshToken: 'legacyrefresh',
    );
    await prefs.setBool('faisal.biometric_enabled', true);
    final biometric = BiometricService(prefs);
    final auth = AuthBloc(
      repository,
      store,
      savedBanks: saved,
      biometrics: biometric,
    );
    await send(
      auth,
      const AuthStarted(),
      (s) => s.status == AuthStatus.unauthenticated,
    );
    expect(saved.entries.single.userId, 'a');
    expect(
      biometric.enabledFor('a'),
      isFalse,
    ); // Android upgrade requires secure re-enablement.
    expect(biometric.enabledFor('b'), isFalse);
    expect(store.hasSession, isFalse);
    await auth.close();
  });

  test('mandatory first login takes precedence over chooser', () async {
    await saved.remember(customer('a', 'cib'), 'secret');
    await store.saveSetupToken('setup-token');
    final auth = AuthBloc(repository, store, savedBanks: saved);
    await send(auth, const AuthStarted(), (s) => s.isFirstLogin);
    expect(auth.state.setupToken, 'setup-token');
    expect(
      resolveRedirect(
        auth: auth.state,
        location: AppRoutes.savedBanks,
        hasSavedBanks: true,
      ),
      AppRoutes.passwordSetup,
    );
    await auth.close();
  });

  test('registration completion opens the persisted identity, while background refresh cannot authenticate a signed-out chooser', () async {
    final auth = AuthBloc(repository, store, savedBanks: saved);
    await send(
      auth,
      const AuthStarted(),
      (s) => s.status == AuthStatus.unauthenticated,
    );
    auth.add(AuthTokensRefreshed(customer('a', 'cib')));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(auth.state.isAuthenticated, isFalse);
    await repository.login(
      identifier: 'usera',
      password: 'unused',
      rememberDevice: true,
    );
    await send(
      auth,
      AuthRegistrationCompleted(customer('a', 'cib')),
      (s) => s.isAuthenticated,
    );
    expect(auth.state.user!.id, 'a');
    await auth.close();
  });

  test('server response must match both selected owner and bank before persisting credentials', () async {
    for (final wrong in [payload('b', 'cib'), payload('a', 'nbe')]) {
      remote.data = wrong;
      await expectLater(
        repository.resumeSavedBank(
          refreshToken: 'token',
          userId: 'a',
          bankCode: 'cib',
        ),
        throwsA(isA<AppException>()),
      );
      expect(store.hasSession, isFalse);
      expect(saved.entries, isEmpty);
    }
  });

  test(
    'rotating resume updates only the selected account credential',
    () async {
      await saved.remember(customer('a', 'cib'), 'old-a');
      await saved.remember(customer('b', 'nbe'), 'old-b');
      final result = await repository.resumeSavedBank(
        refreshToken: 'old-a',
        userId: 'a',
        bankCode: 'cib',
      );
      expect(result.user.id, 'a');
      expect(store.activeUserId, 'a');
      expect(await store.bankCredential('a'), 'rotateda');
      expect(await store.bankCredential('b'), 'old-b');
    },
  );

  test(
    'a delayed refresh cannot replace a newer account after switching',
    () async {
      await repository.login(
        identifier: 'usera',
        password: 'unused',
        rememberDevice: true,
      );
      final response = Completer<Map<String, dynamic>>();
      remote.refreshHandler = () => response.future;
      final refreshing = repository.refreshSession(store.refreshToken!);
      await store.clear();
      remote.data = payload('b', 'nbe');
      await repository.login(
        identifier: 'userb',
        password: 'unused',
        rememberDevice: true,
      );
      response.complete(payload('a', 'cib'));
      expect(await refreshing, isNull);
      expect(store.activeUserId, 'b');
      expect(store.accessToken, 'accessb');
    },
  );

  test('a registration response cannot replace a customer who signed in while it was pending', () async {
    final response = Completer<Map<String, dynamic>>();
    remote.registrationHandler = () => response.future;
    final registration = repository.completeRegistration(
      'grant',
      'unused',
      'unused',
      'usera',
    );
    final rejected = expectLater(registration, throwsA(isA<AppException>()));
    await store.clear();
    remote.data = payload('b', 'nbe');
    await repository.login(
      identifier: 'userb',
      password: 'unused',
      rememberDevice: true,
    );
    response.complete(payload('a', 'cib'));
    await rejected;
    expect(store.activeUserId, 'b');
    expect(store.accessToken, 'accessb');
    expect(saved.entries.single.userId, 'b');
  });

  test('return to banks parks current session; explicit logout invalidates only that account', () async {
    await saved.remember(customer('b', 'nbe'), 'secret-b');
    final auth = AuthBloc(repository, store, savedBanks: saved);
    await send(
      auth,
      const AuthLoginRequested(
        identifier: 'usera',
        password: 'unused',
        rememberDevice: true,
      ),
      (s) => s.isAuthenticated,
    );
    await send(
      auth,
      const AuthReturnToBanksRequested(),
      (s) => !s.busy && s.status == AuthStatus.unauthenticated,
    );
    expect(remote.logoutCalls, 0);
    expect(await store.bankCredential('a'), isNotNull);
    await send(
      auth,
      const AuthLoginRequested(
        identifier: 'usera',
        password: 'unused',
        rememberDevice: true,
      ),
      (s) => s.isAuthenticated,
    );
    await send(
      auth,
      const AuthLogoutRequested(),
      (s) => !s.busy && s.status == AuthStatus.unauthenticated,
    );
    expect(await store.bankCredential('a'), isNull);
    expect(await store.bankCredential('b'), 'secret-b');
    expect(saved.entries.length, 2);
    await auth.close();
  });

  for (final rejected in [false, true]) {
    test(
      'biometric card uses one protected read and backend verification; revoked=$rejected',
      () async {
        final native = fixtures.FakeLocalAuth(),
            vault = fixtures.ProtectedTestVault();
        final biometric = BiometricService(prefs, auth: native, vault: vault);
        await saved.remember(customer('a', 'cib'), 'old-a');
        await saved.remember(customer('b', 'nbe'), 'old-b');
        biometric.bindIdentity('a');
        expect(await biometric.enable('Enable'), isTrue);
        expect(biometric.enabledFor('b'), isFalse);
        vault.prompts = 0;
        if (rejected) {
          remote.refreshHandler = () async =>
              throw const AppException(code: AppErrorCode.unauthorized);
        }
        final auth = AuthBloc(
          repository,
          store,
          savedBanks: saved,
          biometrics: biometric,
        );
        await send(
          auth,
          AuthSavedBankRequested(saved.entries.last, 'Unlock'),
          (s) => !s.busy && s.status != AuthStatus.unknown,
        );
        expect(vault.prompts, 1);
        expect(native.prompts, 0);
        expect(remote.refreshCalls, 1);
        expect(auth.state.isAuthenticated, !rejected);
        expect(store.hasSession, !rejected);
        expect(await store.bankCredential('b'), 'old-b');
        if (rejected) {
          expect(await store.bankCredential('a'), isNull);
          expect(saved.pendingLogin?.userId, 'a');
        }
        await auth.close();
      },
    );
  }

  test('cancelled biometric never reads refresh API; offline preserves retry credential', () async {
    final vault = fixtures.ProtectedTestVault();
    final biometric = BiometricService(
      prefs,
      auth: fixtures.FakeLocalAuth(),
      vault: vault,
    );
    biometric.bindIdentity('a');
    await biometric.enable('Enable');
    await saved.remember(customer('a', 'cib'), 'old-a');
    final auth = AuthBloc(
      repository,
      store,
      savedBanks: saved,
      biometrics: biometric,
    );
    vault.allowed = false;
    await send(
      auth,
      AuthSavedBankRequested(saved.entries.single, 'Unlock'),
      (s) => !s.busy && s.errorCode != null,
    );
    expect(remote.refreshCalls, 0);
    expect(store.hasSession, isFalse);
    vault.allowed = true;
    remote.refreshHandler = () async =>
        throw const AppException(code: AppErrorCode.network);
    await send(
      auth,
      AuthSavedBankRequested(saved.entries.single, 'Unlock'),
      (s) => !s.busy && s.errorCode == AppErrorCode.network,
    );
    expect(await store.bankCredential('a'), 'old-a');
    expect(auth.state.isAuthenticated, isFalse);
    await auth.close();
  });

  test('disabling biometric for one identity leaves other identity preferences unchanged', () async {
    final service = BiometricService(
      prefs,
      auth: fixtures.FakeLocalAuth(),
      vault: fixtures.ProtectedTestVault(),
    );
    service.bindIdentity('a');
    await service.enable('Enable');
    service.bindIdentity('b');
    expect(service.enabled, isFalse);
    await service.enable('Enable');
    service.bindIdentity('a');
    await service.disable();
    expect(service.enabledFor('a'), isFalse);
    expect(service.enabledFor('b'), isTrue);
  });

  test('Android native guard makes one fresh operation per unlock and never enables another owner', () async {
    const channel = MethodChannel('banking/biometric_guard_v2');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final local = fixtures.FakeLocalAuth();
    final service = BiometricService(prefs, auth: local);
    await prefs.setBool('faisal.biometric_enabled', true);
    await prefs.setBool('faisal.biometric_enabled.a', true);
    service.bindIdentity('a');
    expect(service.enabled, isFalse);
    expect(await service.enable('Enable'), isTrue);
    expect(service.enabledFor('a'), isTrue);
    expect(service.enabledFor('b'), isFalse);
    expect(await service.unlock('Unlock'), isTrue);
    expect(await service.unlock('Unlock'), isTrue);
    expect(calls.where((c) => c.method == 'enable').length, 1);
    expect(calls.where((c) => c.method == 'unlock').length, 2);
    expect(
      calls
          .where((c) => c.method != 'supported')
          .every((c) => (c.arguments as Map)['identity'] == 'a'),
      isTrue,
    );
    expect(local.prompts, 0);
    await service.disable();
    expect(service.enabled, isFalse);
  });

  test('duplicate taps and error-clear cannot start a second native prompt while unlocking', () async {
    const channel = MethodChannel('banking/biometric_guard_v2');
    final pending = Completer<bool>(), started = Completer<void>();
    var unlocks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'unlock') {
            unlocks++;
            if (!started.isCompleted) started.complete();
            return pending.future;
          }
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await saved.remember(customer('a', 'cib'), 'old-a');
    final service = BiometricService(prefs, auth: fixtures.FakeLocalAuth())
      ..bindIdentity('a');
    await service.enable('Enable');
    final auth = AuthBloc(
      repository,
      store,
      savedBanks: saved,
      biometrics: service,
    );
    auth.add(AuthSavedBankRequested(saved.entries.single, 'Unlock'));
    await started.future;
    auth.add(const AuthErrorCleared());
    auth.add(AuthSavedBankRequested(saved.entries.single, 'Unlock'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(auth.state.busy, isTrue);
    expect(unlocks, 1);
    final result = auth.stream.firstWhere((s) => s.isAuthenticated);
    pending.complete(true);
    await result;
    expect(remote.refreshCalls, 1);
    await auth.close();
  });

  test('chooser redirects preserve add bank, login and first login routes', () {
    const unauth = AuthState(status: AuthStatus.unauthenticated);
    for (final selected in [true, false]) {
      expect(
        resolveRedirect(
          auth: unauth,
          location: AppRoutes.splash,
          hasSelectedBank: selected,
          hasSavedBanks: true,
        ),
        AppRoutes.savedBanks,
      );
      expect(
        resolveRedirect(
          auth: unauth,
          location: AppRoutes.savedBanks,
          hasSelectedBank: selected,
          hasSavedBanks: true,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          auth: unauth,
          location: AppRoutes.onboarding,
          hasSelectedBank: selected,
          hasSavedBanks: true,
        ),
        isNull,
      );
    }
    expect(
      resolveRedirect(
        auth: unauth,
        location: AppRoutes.login,
        hasSavedBanks: true,
      ),
      isNull,
    );
  });

  for (final locale in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'bank cards keep logos/themes, password fallback and add bank $locale dark=$dark',
        (t) async {
          await saved.remember(customer('a', 'cib'), 'secret-a');
          await saved.remember(customer('b', 'nbe'), 'secret-b');
          final auth = AuthBloc(repository, store, savedBanks: saved);
          final selection = BankSelectionCubit(prefs),
              cubit = SavedBanksCubit(saved);
          final language = LanguageCubit(prefs, fixtures.FakeSettings());
          sl.registerSingleton<SavedBanksRepository>(saved);
          sl.registerSingleton<SavedBanksCubit>(cubit);
          sl.registerSingleton<BankSelectionCubit>(selection);
          sl.registerSingleton<BiometricService>(BiometricService(prefs));
          final router = GoRouter(
            initialLocation: AppRoutes.savedBanks,
            routes: [
              GoRoute(
                path: AppRoutes.savedBanks,
                builder: (_, _) => const SavedBanksPage(),
              ),
              GoRoute(
                path: AppRoutes.login,
                builder: (_, _) => const Scaffold(body: Text('password-login')),
              ),
              GoRoute(
                path: AppRoutes.onboarding,
                builder: (_, _) => const Scaffold(body: Text('choose-bank')),
              ),
            ],
          );
          addTearDown(() async {
            router.dispose();
            await auth.close();
            await cubit.close();
            await selection.close();
            await language.close();
          });
          await t.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider.value(value: auth),
                BlocProvider.value(value: language),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: dark ? AppTheme.dark() : AppTheme.light(),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(find.byType(BankLogo), findsNWidgets(2));
          expect(
            Directionality.of(t.element(find.byType(SavedBanksPage))),
            locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          final cibCard = find.byKey(const ValueKey('saved-bank-a'));
          final nbeCard = find.byKey(const ValueKey('saved-bank-b'));
          expect(BrandingScope.bankOf(t.element(cibCard))!.code, 'cib');
          expect(
            Theme.of(t.element(cibCard)).colorScheme.primary,
            isNot(Theme.of(t.element(nbeCard)).colorScheme.primary),
          );
          final login = find.byKey(const ValueKey('saved-bank-sign-in-a'));
          await t.ensureVisible(login);
          await t.tap(login);
          await t.pumpAndSettle();
          expect(find.text('password-login'), findsOneWidget);
          expect(saved.pendingLogin?.username, 'usera');
          expect(selection.state, 'cib');
          expect(remote.refreshCalls, 0);
          router.go(AppRoutes.savedBanks);
          await t.pumpAndSettle();
          final add = find.byKey(const Key('saved-banks-add'));
          await t.ensureVisible(add);
          await t.tap(add);
          await t.pumpAndSettle();
          expect(find.text('choose-bank'), findsOneWidget);
          expect(saved.pendingLogin, isNull);
          expect(saved.entries.length, 2);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }
}
