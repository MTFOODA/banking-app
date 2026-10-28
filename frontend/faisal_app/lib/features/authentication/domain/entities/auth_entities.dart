import 'package:equatable/equatable.dart';

/// Customer profile details exposed by the API (never full identifiers).
class CustomerProfileEntity extends Equatable {
  const CustomerProfileEntity({
    required this.id,
    required this.customerNumber,
    required this.firstNameEn,
    required this.lastNameEn,
    required this.firstNameAr,
    required this.lastNameAr,
    this.email,
    this.phone,
    this.nationalIdMasked,
    this.address,
    this.segment = 'retail',
    this.identityVerified = false,
  });

  final String id;
  final String customerNumber;
  final String firstNameEn;
  final String lastNameEn;
  final String firstNameAr;
  final String lastNameAr;
  final String? email;
  final String? phone;
  final String? nationalIdMasked;
  final String? address;
  final String segment;
  final bool identityVerified;

  String displayName({required bool arabic}) => arabic
      ? '$firstNameAr $lastNameAr'.trim()
      : '$firstNameEn $lastNameEn'.trim();

  @override
  List<Object?> get props => [
    id,
    customerNumber,
    email,
    phone,
    address,
    identityVerified,
  ];
}

/// Authenticated session identity plus effective permissions.
class SessionUser extends Equatable {
  const SessionUser({
    required this.id,
    required this.maskedIdentifier,
    required this.loginType,
    required this.mustChangePassword,
    this.profile,
    this.roles = const <String>[],
    this.permissions = const <String>[],
    this.preferredLanguage,
    this.preferredTheme,
    this.username,
  });

  final String id;
  final String maskedIdentifier;
  final String loginType;
  final bool mustChangePassword;
  final CustomerProfileEntity? profile;
  final List<String> roles;
  final List<String> permissions;
  final String? preferredLanguage;
  final String? preferredTheme;
  final String? username;

  bool get isStaff => loginType == 'staff';

  bool can(String permission) => permissions.contains(permission);

  String get displayName =>
      profile?.displayName(arabic: false) ?? maskedIdentifier;

  @override
  List<Object?> get props => [
    id,
    maskedIdentifier,
    loginType,
    mustChangePassword,
    roles,
    permissions,
    profile,
  ];
}

class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthSession extends Equatable {
  const AuthSession({required this.tokens, required this.user});

  final AuthTokens tokens;
  final SessionUser user;

  @override
  List<Object?> get props => [tokens, user];
}

enum LoginStatus { authenticated, passwordSetupRequired }

class LoginOutcome extends Equatable {
  const LoginOutcome({
    required this.status,
    this.session,
    this.setupToken,
    this.user,
  });

  final LoginStatus status;
  final AuthSession? session;
  final String? setupToken;
  final SessionUser? user;

  @override
  List<Object?> get props => [status, session, setupToken, user];
}
