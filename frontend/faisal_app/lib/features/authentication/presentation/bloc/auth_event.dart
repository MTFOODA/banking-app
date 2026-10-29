import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_entities.dart';
import '../../domain/entities/saved_bank.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSavedBankRequested extends AuthEvent {
  const AuthSavedBankRequested(this.entry, this.reason);
  final SavedBank entry;
  final String reason;
  @override
  List<Object?> get props => [entry];
}

/// Parks the active session locally; explicit logout still revokes it.
class AuthReturnToBanksRequested extends AuthEvent {
  const AuthReturnToBanksRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.identifier,
    required this.password,
    required this.rememberDevice,
    this.bankCode,
  });

  /// Card number or account number (normalised by the API).
  final String identifier;
  final String password;
  final bool rememberDevice;
  final String? bankCode;

  @override
  List<Object?> get props => [identifier, rememberDevice, bankCode];
}

class AuthTokensRefreshed extends AuthEvent {
  const AuthTokensRefreshed(this.user);

  final SessionUser user;

  @override
  List<Object?> get props => [user];
}

class AuthRegistrationCompleted extends AuthEvent {
  const AuthRegistrationCompleted(this.user);
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
