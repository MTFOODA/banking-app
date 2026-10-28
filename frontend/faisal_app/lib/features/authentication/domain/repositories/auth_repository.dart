import '../entities/auth_entities.dart';
import '../entities/security_entities.dart';

abstract class AuthRepository {
  Future<RegistrationChallenge> startRegistration(String identifier);
  Future<RegistrationChallenge> resendRegistration(String challenge);
  Future<String> verifyRegistration(String challenge, String code);
  Future<UsernameAvailability> checkUsername(String grant, String username);
  Future<AuthSession> completeRegistration(
    String token,
    String password,
    String confirmation,
    String username,
  );
  Future<AuthorizationCredential> authorize(
    String scope,
    String password, {
    Map<String, dynamic>? transfer,
    Map<String, dynamic>? investment,
  });
  Future<void> confirmBiometric(String token);
  Future<LoginOutcome> login({
    required String identifier,
    required String password,
    required bool rememberDevice,
  });

  Future<AuthSession> completeFirstLogin({
    required String setupToken,
    required String password,
    required String confirmPassword,
  });

  Future<SessionUser> currentUser();

  /// Refreshes tokens; returns null when the refresh token is no longer valid.
  Future<AuthSession?> refreshSession(String refreshToken);

  Future<void> logout({String? refreshToken, bool allDevices = false});

  Future<void> changePassword({
    required String authorizationToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<String> requestPasswordReset(String cardNumber);

  bool get hasStoredSession;
}
