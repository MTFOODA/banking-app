import '../../../../core/errors/app_exception.dart';
import '../../../../core/security/session_store.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/entities/security_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._store);

  final AuthRemoteDataSource _remote;
  final SessionStore _store;

  RegistrationChallenge _challenge(Map<String, dynamic> json) =>
      RegistrationChallenge(
        reference: json['challenge'] as String,
        contact: json['contact_masked'] as String,
        resendAfter: json['resend_after'] as int,
        development: json['delivery'] == 'development_no_delivery',
        developmentCode: json['development_code'] as String?,
      );

  @override
  Future<RegistrationChallenge> startRegistration(String identifier) async =>
      _challenge(
        await _remote.securityPost('registration/start', {
          'identifier': identifier,
        }),
      );
  @override
  Future<RegistrationChallenge> resendRegistration(String challenge) async =>
      _challenge(
        await _remote.securityPost('registration/resend', {
          'challenge': challenge,
        }),
      );
  @override
  Future<String> verifyRegistration(String challenge, String code) async =>
      (await _remote.securityPost('registration/verify', {
            'challenge': challenge,
            'code': code,
          }))['authorization_token']
          as String;
  @override
  Future<UsernameAvailability> checkUsername(
    String grant,
    String username,
  ) async {
    final data = await _remote.securityPost('registration/username', {
      'authorization_token': grant,
      'username': username,
    });
    return UsernameAvailability(
      data['username'] as String,
      data['available'] as bool,
      (data['suggestions'] as List).cast<String>(),
    );
  }

  @override
  Future<AuthSession> completeRegistration(
    String token,
    String password,
    String confirmation,
    String username,
  ) async => _persistSession(
    await _remote.securityPost('registration/complete', {
      'authorization_token': token,
      'new_password': password,
      'confirm_password': confirmation,
      'username': username,
    }),
  );
  @override
  Future<AuthorizationCredential> authorize(
    String scope,
    String password, {
    Map<String, dynamic>? transfer,
    Map<String, dynamic>? investment,
  }) async {
    final json = await _remote.securityPost('authorize', {
      'scope': scope,
      'current_password': password,
      'transfer': ?transfer,
      'investment': ?investment,
    });
    return AuthorizationCredential(
      json['authorization_token'] as String,
      json['expires_in'] as int,
    );
  }

  @override
  Future<void> confirmBiometric(String token) async {
    await _remote.securityPost('biometric/confirm', {
      'authorization_token': token,
    });
  }

  @override
  bool get hasStoredSession => _store.hasSession;

  @override
  Future<LoginOutcome> login({
    required String identifier,
    required String password,
    required bool rememberDevice,
  }) async {
    final json = await _remote.login(
      identifier: identifier,
      password: password,
      rememberDevice: rememberDevice,
    );
    final status = json['status'] as String?;
    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? AuthMapper.userFromJson(userJson)
        : null;

    if (status == 'password_setup_required') {
      final setupToken = json['setup_token'] as String?;
      if (setupToken == null || setupToken.isEmpty) {
        throw const AppException(code: AppErrorCode.unauthorized);
      }
      await _store.saveSetupToken(setupToken);
      return LoginOutcome(
        status: LoginStatus.passwordSetupRequired,
        setupToken: setupToken,
        user: user,
      );
    }

    final session = await _persistSession(json);
    return LoginOutcome(
      status: LoginStatus.authenticated,
      session: session,
      user: session.user,
    );
  }

  @override
  Future<AuthSession> completeFirstLogin({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) async {
    final json = await _remote.completeFirstLogin(
      setupToken: setupToken,
      password: password,
      confirmPassword: confirmPassword,
    );
    return _persistSession(json);
  }

  @override
  Future<SessionUser> currentUser() async {
    final json = await _remote.me();
    return AuthMapper.userFromJson(json);
  }

  @override
  Future<AuthSession?> refreshSession(String refreshToken) async {
    try {
      final json = await _remote.refresh(refreshToken);
      return await _persistSession(json);
    } on AppException catch (error) {
      if (error.code == AppErrorCode.unauthorized ||
          error.code == AppErrorCode.forbidden) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout({String? refreshToken, bool allDevices = false}) async {
    try {
      await _remote.logout(refreshToken: refreshToken, allDevices: allDevices);
    } on AppException {
      // Local sign-out must still succeed when the server is unreachable.
    } finally {
      await _store.clear();
    }
  }

  @override
  Future<void> changePassword({
    required String authorizationToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _remote.changePassword(
      authorizationToken: authorizationToken,
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    await _store.clear();
  }

  @override
  Future<String> requestPasswordReset(String cardNumber) =>
      _remote.requestPasswordReset(cardNumber);

  Future<AuthSession> _persistSession(Map<String, dynamic> json) async {
    final accessToken = json['access_token'] as String?;
    final refreshToken = json['refresh_token'] as String?;
    final userJson = json['user'];
    if (accessToken == null ||
        refreshToken == null ||
        userJson is! Map<String, dynamic>) {
      throw const AppException(code: AppErrorCode.unauthorized);
    }
    await _store.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    return AuthSession(
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
      user: AuthMapper.userFromJson(userJson),
    );
  }
}
