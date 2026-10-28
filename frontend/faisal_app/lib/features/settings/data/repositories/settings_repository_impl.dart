import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/settings_entities.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<ProfileDetails> fetchProfile() async {
    final data = await _client.get('/profile');
    return _profile(asMap(data));
  }

  @override
  Future<String> updateProfile(Map<String, dynamic> changes) async {
    final data = await _client.patch('/profile', body: changes);
    return asMap(data)['reference'] as String;
  }

  @override
  Future<CustomerPreferences> fetchPreferences() async {
    final data = await _client.get('/preferences');
    return _preferences(asMap(data));
  }

  @override
  Future<CustomerPreferences> updatePreferences(
    Map<String, dynamic> changes,
  ) async {
    final data = await _client.patch('/preferences', body: changes);
    return _preferences(asMap(data));
  }

  @override
  Future<List<TrustedSession>> fetchSessions() async {
    final data = await _client.get('/profile/sessions');
    if (data is List) {
      return data.map((item) => _session(asMap(item))).toList(growable: false);
    }
    return const <TrustedSession>[];
  }

  @override
  Future<void> revokeOtherSessions() async {
    await _client.post('/auth/logout', body: {'all_devices': true});
  }

  ProfileDetails _profile(Map<String, dynamic> json) {
    final profile = asMap(json['profile']);
    return ProfileDetails(
      username: asStringOrNull(json['username']),
      pendingReference: asStringOrNull(json['pending_reference']),
      userId: asString(json['user_id']),
      maskedIdentifier: asString(json['login_identifier_masked']),
      firstNameEn: asString(profile['first_name_en']),
      lastNameEn: asString(profile['last_name_en']),
      firstNameAr: asString(profile['first_name_ar']),
      lastNameAr: asString(profile['last_name_ar']),
      customerNumber: asString(profile['customer_number']),
      email: asStringOrNull(profile['email']),
      phone: asStringOrNull(profile['phone']),
      address: asStringOrNull(profile['address']),
      identityVerified: asBool(profile['identity_verified']),
      segment: asString(profile['segment'], 'retail'),
    );
  }

  CustomerPreferences _preferences(Map<String, dynamic> json) {
    return CustomerPreferences(
      language: asString(json['language'], 'en'),
      theme: asString(json['theme'], 'system'),
      notificationsEnabled: asBool(json['notifications_enabled'], true),
      transactionNotifications: asBool(json['transaction_notifications'], true),
      marketingNotifications: asBool(json['marketing_notifications']),
      biometricEnabled: asBool(json['biometric_enabled']),
    );
  }

  TrustedSession _session(Map<String, dynamic> json) {
    return TrustedSession(
      id: asString(json['id']),
      userAgent: asStringOrNull(json['user_agent']),
      ipAddress: asStringOrNull(json['ip_address']),
      createdAt: asDate(json['created_at']),
      lastUsedAt: asDateOrNull(json['last_used_at']),
      expiresAt: asDate(json['expires_at']),
      isCurrent: asBool(json['current']),
    );
  }
}
