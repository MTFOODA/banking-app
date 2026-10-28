import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/security/session_store.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository, this._sessionStore) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthTokensRefreshed>(
      (event, emit) => emit(
        state.copyWith(status: AuthStatus.authenticated, user: event.user),
      ),
    );
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthPasswordSetupSubmitted>(_onPasswordSetupSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthProfileRefreshRequested>(_onProfileRefreshRequested);
    on<AuthErrorCleared>(
      (event, emit) => emit(state.copyWith(clearError: true, busy: false)),
    );
    on<AuthPasswordChanged>(_onPasswordChanged);
  }

  final AuthRepository _repository;
  final SessionStore _sessionStore;

  /// Upper bound for validating a saved session. Dio has its own transport
  /// timeouts; this guard also covers a stalled platform channel or a server
  /// that stops responding mid-request.
  static const Duration _restoreTimeout = Duration(seconds: 20);

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    if (isClosed) {
      return;
    }

    // A retry from the startup screen goes back to the spinner while the
    // saved session is validated again.
    if (state.status == AuthStatus.sessionRestoreFailed) {
      emit(const AuthState(status: AuthStatus.unknown, busy: true));
    }

    if (_repository.hasStoredSession) {
      try {
        final user = await _repository.currentUser().timeout(_restoreTimeout);
        if (isClosed) {
          return;
        }
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      } on TimeoutException {
        _emitRestoreFailure(emit, AppErrorCode.timeout);
      } on AppException catch (error) {
        if (error.code == AppErrorCode.unauthorized ||
            error.code == AppErrorCode.forbidden) {
          // The server rejected the credentials: follow the auth rules and
          // return to sign-in rather than keeping an invalid session.
          await _clearSessionSafely();
          if (isClosed) {
            return;
          }
          emit(
            const AuthState(
              status: AuthStatus.unauthenticated,
              sessionExpired: true,
            ),
          );
          return;
        }
        // Transient failure: the saved session may still be valid, so keep it
        // and offer a retry instead of sending the user to sign-in.
        _emitRestoreFailure(emit, error.code, detail: error.message);
      } catch (_) {
        _emitRestoreFailure(emit, AppErrorCode.unknown);
      }
      return;
    }

    final setupToken = _sessionStore.setupToken;
    if (isClosed) {
      return;
    }
    if (setupToken != null && setupToken.isNotEmpty) {
      emit(
        AuthState(
          status: AuthStatus.firstLoginRequired,
          setupToken: setupToken,
        ),
      );
      return;
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _emitRestoreFailure(
    Emitter<AuthState> emit,
    AppErrorCode code, {
    String? detail,
  }) {
    if (isClosed || emit.isDone) {
      return;
    }
    emit(
      AuthState(
        status: AuthStatus.sessionRestoreFailed,
        errorCode: code,
        errorDetail: detail,
      ),
    );
  }

  Future<void> _clearSessionSafely() async {
    try {
      await _sessionStore.clear();
    } catch (_) {
      // A storage failure must not leave the UI stuck on the startup screen.
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!_canEmit(emit)) {
      return;
    }
    emit(const AuthState(status: AuthStatus.unauthenticated, busy: true));
    try {
      final outcome = await _repository.login(
        identifier: event.identifier,
        password: event.password,
        rememberDevice: event.rememberDevice,
      );
      if (!_canEmit(emit)) {
        return;
      }
      if (outcome.status == LoginStatus.passwordSetupRequired) {
        emit(
          AuthState(
            status: AuthStatus.firstLoginRequired,
            setupToken: outcome.setupToken,
            user: outcome.user,
          ),
        );
        return;
      }
      final session = outcome.session;
      if (session == null) {
        emit(
          const AuthState(
            status: AuthStatus.unauthenticated,
            errorCode: AppErrorCode.unauthorized,
          ),
        );
        return;
      }
      emit(AuthState(status: AuthStatus.authenticated, user: session.user));
    } on AppException catch (error) {
      if (!_canEmit(emit)) {
        return;
      }
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorCode: error.code,
          errorDetail: error.message,
        ),
      );
    } catch (_) {
      if (!_canEmit(emit)) {
        return;
      }
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorCode: AppErrorCode.unknown,
        ),
      );
    }
  }

  Future<void> _onPasswordSetupSubmitted(
    AuthPasswordSetupSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final token = state.setupToken ?? _sessionStore.setupToken;
    if (token == null || token.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorCode: AppErrorCode.unauthorized,
          busy: false,
        ),
      );
      return;
    }
    emit(state.copyWith(busy: true, clearError: true));
    try {
      final session = await _repository.completeFirstLogin(
        setupToken: token,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      if (!_canEmit(emit)) {
        return;
      }
      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
          justCompletedSetup: true,
        ),
      );
    } on AppException catch (error) {
      if (!_canEmit(emit)) {
        return;
      }
      emit(
        state.copyWith(
          busy: false,
          errorCode: error.code,
          errorDetail: error.message,
        ),
      );
    } catch (_) {
      if (!_canEmit(emit)) {
        return;
      }
      emit(state.copyWith(busy: false, errorCode: AppErrorCode.unknown));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    await _repository.logout(refreshToken: _sessionStore.refreshToken);
    if (!_canEmit(emit)) {
      return;
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _clearSessionSafely();
    if (!_canEmit(emit)) {
      return;
    }
    emit(
      const AuthState(status: AuthStatus.unauthenticated, sessionExpired: true),
    );
  }

  Future<void> _onProfileRefreshRequested(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated) {
      return;
    }
    try {
      final user = await _repository.currentUser();
      if (!_canEmit(emit)) {
        return;
      }
      emit(state.copyWith(user: user));
    } on AppException catch (error) {
      if (error.code == AppErrorCode.unauthorized && !isClosed) {
        add(const AuthSessionExpired());
      }
    } catch (_) {
      // Keep the current identity when a transient refresh fails.
    }
  }

  Future<void> _onPasswordChanged(
    AuthPasswordChanged event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout(refreshToken: _sessionStore.refreshToken);
    if (!_canEmit(emit)) {
      return;
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  bool _canEmit(Emitter<AuthState> emit) => !isClosed && !emit.isDone;

  Future<bool> refreshTokens() async {
    final refreshToken = _sessionStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      final session = await _repository.refreshSession(refreshToken);
      if (session == null || isClosed) {
        return false;
      }
      add(AuthTokensRefreshed(session.user));
      return true;
    } on AppException {
      return false;
    }
  }
}
