import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/core/routing/app_routes.dart';
import 'package:faisal_app/core/routing/route_guard.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/features/authentication/domain/entities/auth_entities.dart';
import 'package:faisal_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_event.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/authentication/presentation/pages/splash_page.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const SessionUser _user = SessionUser(
  id: 'user-1',
  maskedIdentifier: '**** 1234',
  loginType: 'customer',
  mustChangePassword: false,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  _FakeAuthRepository(this._store);

  final SessionStore _store;
  Future<SessionUser> Function()? currentUserHandler;

  @override
  bool get hasStoredSession => _store.hasSession;

  @override
  Future<SessionUser> currentUser() {
    final handler = currentUserHandler;
    if (handler == null) {
      throw StateError('currentUserHandler not configured');
    }
    return handler();
  }

  @override
  Future<LoginOutcome> login({
    required String identifier,
    required String password,
    required bool rememberDevice,
    String? bankCode,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> completeFirstLogin({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession?> refreshSession(String refreshToken) =>
      throw UnimplementedError();

  @override
  Future<void> logout({String? refreshToken, bool allDevices = false}) async {}

  @override
  Future<void> changePassword({
    required String authorizationToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => throw UnimplementedError();

  @override
  Future<String> requestPasswordReset(String cardNumber) =>
      throw UnimplementedError();
}

Future<SessionStore> _emptyStore() async =>
    SessionStore(storage: const FlutterSecureStorage());

Widget _host(AuthBloc bloc) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BlocProvider<AuthBloc>.value(value: bloc, child: const SplashPage()),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  group('startup redirects', () {
    test('signed-out state leaves the splash screen for sign-in', () {
      final redirect = resolveRedirect(
        auth: const AuthState(status: AuthStatus.unauthenticated),
        location: AppRoutes.splash,
      );
      expect(redirect, AppRoutes.preLogin);
    });

    test('signed-out state stays on the credential screens', () {
      expect(
        resolveRedirect(
          auth: const AuthState(status: AuthStatus.unauthenticated),
          location: AppRoutes.login,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          auth: const AuthState(status: AuthStatus.unauthenticated),
          location: AppRoutes.forgotPassword,
        ),
        isNull,
      );
    });

    test('restoring state stays on the splash screen', () {
      expect(
        resolveRedirect(auth: const AuthState(), location: AppRoutes.splash),
        isNull,
      );
    });

    test('a recoverable restore failure keeps the splash screen for retry', () {
      expect(
        resolveRedirect(
          auth: const AuthState(
            status: AuthStatus.sessionRestoreFailed,
            errorCode: AppErrorCode.network,
          ),
          location: AppRoutes.splash,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          auth: const AuthState(
            status: AuthStatus.sessionRestoreFailed,
            errorCode: AppErrorCode.network,
          ),
          location: AppRoutes.home,
        ),
        AppRoutes.splash,
      );
    });
  });

  group('session restoration', () {
    test(
      'network failure keeps the saved session and offers a retry',
      () async {
        final store = await _emptyStore();
        await store.saveSession(accessToken: 'access', refreshToken: 'refresh');
        final repository = _FakeAuthRepository(store)
          ..currentUserHandler = () async =>
              throw const AppException(code: AppErrorCode.network);
        final bloc = AuthBloc(repository, store);
        addTearDown(bloc.close);

        final failure = bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.sessionRestoreFailed,
        );
        bloc.add(const AuthStarted());
        final state = await failure;

        expect(state.errorCode, AppErrorCode.network);
        expect(
          store.hasSession,
          isTrue,
          reason: 'transient errors must not sign the user out',
        );
      },
    );

    test(
      'unexpected errors become a recoverable state, not a spinner',
      () async {
        final store = await _emptyStore();
        await store.saveSession(accessToken: 'access', refreshToken: 'refresh');
        final repository = _FakeAuthRepository(store)
          ..currentUserHandler = () async => throw StateError('bad payload');
        final bloc = AuthBloc(repository, store);
        addTearDown(bloc.close);

        final failure = bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.sessionRestoreFailed,
        );
        bloc.add(const AuthStarted());
        final state = await failure;

        expect(state.errorCode, AppErrorCode.unknown);
        expect(bloc.state.status, isNot(AuthStatus.unknown));
      },
    );

    test(
      'rejected credentials clear the session and return to sign-in',
      () async {
        final store = await _emptyStore();
        await store.saveSession(accessToken: 'access', refreshToken: 'refresh');
        final repository = _FakeAuthRepository(store)
          ..currentUserHandler = () async =>
              throw const AppException(code: AppErrorCode.unauthorized);
        final bloc = AuthBloc(repository, store);
        addTearDown(bloc.close);

        final signedOut = bloc.stream.firstWhere(
          (state) => state.status == AuthStatus.unauthenticated,
        );
        bloc.add(const AuthStarted());
        final state = await signedOut;

        expect(state.sessionExpired, isTrue);
        expect(store.hasSession, isFalse);
      },
    );

    test('retry after a transient failure authenticates the session', () async {
      final store = await _emptyStore();
      await store.saveSession(accessToken: 'access', refreshToken: 'refresh');
      final repository = _FakeAuthRepository(store)
        ..currentUserHandler = () async =>
            throw const AppException(code: AppErrorCode.timeout);
      final bloc = AuthBloc(repository, store);
      addTearDown(bloc.close);

      final failure = bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.sessionRestoreFailed,
      );
      bloc.add(const AuthStarted());
      await failure;

      repository.currentUserHandler = () async => _user;
      final authenticated = bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.authenticated,
      );
      bloc.add(const AuthStarted());
      expect((await authenticated).user, _user);
    });

    test('closing the bloc mid-restore does not emit or throw', () async {
      final store = await _emptyStore();
      await store.saveSession(accessToken: 'access', refreshToken: 'refresh');
      final repository = _FakeAuthRepository(store)
        ..currentUserHandler = () async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          throw const AppException(code: AppErrorCode.network);
        };
      final bloc = AuthBloc(repository, store);

      bloc.add(const AuthStarted());
      await bloc.close();
      expect(bloc.isClosed, isTrue);
    });

    test('missing session and setup token goes straight to sign-in', () async {
      final store = await _emptyStore();
      final bloc = AuthBloc(_FakeAuthRepository(store), store);
      addTearDown(bloc.close);

      final signedOut = bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.unauthenticated,
      );
      bloc.add(const AuthStarted());
      expect((await signedOut).status, AuthStatus.unauthenticated);
    });

    test('saved setup token routes to the password-setup step', () async {
      final store = await _emptyStore();
      await store.saveSetupToken('setup-token');
      final bloc = AuthBloc(_FakeAuthRepository(store), store);
      addTearDown(bloc.close);

      final setup = bloc.stream.firstWhere(
        (state) => state.status == AuthStatus.firstLoginRequired,
      );
      bloc.add(const AuthStarted());
      expect((await setup).setupToken, 'setup-token');
    });
  });

  testWidgets('startup failure renders a retry action instead of a spinner', (
    tester,
  ) async {
    final store = await _emptyStore();
    await store.saveSession(accessToken: 'access', refreshToken: 'refresh');
    final repository = _FakeAuthRepository(store)
      ..currentUserHandler = () async =>
          throw const AppException(code: AppErrorCode.network);
    final bloc = AuthBloc(repository, store);
    addTearDown(bloc.close);

    await tester.pumpWidget(_host(bloc));
    bloc.add(const AuthStarted());
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Cannot reach the server'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
