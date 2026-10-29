import '../../../../core/network/dio_client.dart';
import '../../domain/entities/auth_entities.dart';
import '../models/auth_mapper.dart';

/// REST calls for authentication. Tokens are returned to the repository which
/// owns secure persistence.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;
  Future<Map<String, dynamic>> securityPost(
    String path,
    Map<String, dynamic> body,
  ) async => _asMap(await _client.post('/auth/$path', body: body));

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required bool rememberDevice,
    String? bankCode,
  }) async {
    final data = await _client.post(
      '/auth/login',
      body: {
        'identifier': identifier,
        'identifier_type': 'username',
        'password': password,
        'remember_device': rememberDevice,
        'bank_code': ?bankCode,
      },
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> completeFirstLogin({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) async {
    final data = await _client.post(
      '/auth/first-login/complete',
      body: {'new_password': password, 'confirm_password': confirmPassword},
      headers: {'Authorization': 'Bearer $setupToken'},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final data = await _client.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _client.get('/auth/me');
    return _asMap(data);
  }

  Future<void> logout({String? refreshToken, bool allDevices = false}) async {
    await _client.post(
      '/auth/logout',
      body: {'refresh_token': ?refreshToken, 'all_devices': allDevices},
    );
  }

  Future<void> changePassword({
    required String authorizationToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post(
      '/auth/change-password',
      body: {
        'current_password': currentPassword,
        'authorization_token': authorizationToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<String> requestPasswordReset(String cardNumber) async {
    final data = await _client.post(
      '/auth/forgot-password',
      body: {'card_number': cardNumber},
    );
    final map = _asMap(data);
    return map['message'] as String? ?? '';
  }

  SessionUser mapUser(Map<String, dynamic> json) =>
      AuthMapper.userFromJson(json);

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
