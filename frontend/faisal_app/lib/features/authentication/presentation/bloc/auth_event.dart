import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_entities.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.identifier,
    required this.password,
    required this.rememberDevice,
  });

  /// Card number or account number (normalised by the API).
  final String identifier;
  final String password;
  final bool rememberDevice;

  @override
  List<Object?> get props => [identifier, rememberDevice];
}

class AuthTokensRefreshed extends AuthEvent {
  const AuthTokensRefreshed(this.user);

  final SessionUser user;

  @override
  List<Object?> get props => [user];
}

class AuthPasswordSetupSubmitted extends AuthEvent {
  const AuthPasswordSetupSubmitted({
    required this.password,
    required this.confirmPassword,
  });

  final String password;
  final String confirmPassword;

  @override
  List<Object?> get props => const [];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

class AuthPasswordChanged extends AuthEvent {
  const AuthPasswordChanged();
}
