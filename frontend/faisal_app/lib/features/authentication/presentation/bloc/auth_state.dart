import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_entities.dart';

enum AuthStatus {
  /// Startup: the saved session has not been validated yet.
  unknown,

  /// The saved session could not be validated because of a transient problem
  /// (network, timeout, server error). Credentials are kept so the user can
  /// retry; this is not an authentication failure.
  sessionRestoreFailed,

  unauthenticated,
  firstLoginRequired,
  authenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.setupToken,
    this.busy = false,
    this.errorCode,
    this.errorDetail,
    this.sessionExpired = false,
    this.justCompletedSetup = false,
  });

  final AuthStatus status;
  final SessionUser? user;
  final String? setupToken;
  final bool busy;
  final AppErrorCode? errorCode;
  final String? errorDetail;
  final bool sessionExpired;
  final bool justCompletedSetup;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isFirstLogin => status == AuthStatus.firstLoginRequired;
  bool get isStaff => user?.isStaff ?? false;

  bool can(String permission) => user?.can(permission) ?? false;

  AuthState copyWith({
    AuthStatus? status,
    SessionUser? user,
    String? setupToken,
    bool? busy,
    AppErrorCode? errorCode,
    String? errorDetail,
    bool clearError = false,
    bool? sessionExpired,
    bool? justCompletedSetup,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      setupToken: setupToken ?? this.setupToken,
      busy: busy ?? this.busy,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorDetail: clearError ? null : (errorDetail ?? this.errorDetail),
      sessionExpired: sessionExpired ?? this.sessionExpired,
      justCompletedSetup: justCompletedSetup ?? this.justCompletedSetup,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    setupToken,
    busy,
    errorCode,
    errorDetail,
    sessionExpired,
    justCompletedSetup,
  ];
}
