import '../entities/settings_entities.dart';

abstract class SettingsRepository {
  Future<ProfileDetails> fetchProfile();

  Future<String> updateProfile(Map<String, dynamic> changes);

  Future<CustomerPreferences> fetchPreferences();

  Future<CustomerPreferences> updatePreferences(Map<String, dynamic> changes);

  Future<List<TrustedSession>> fetchSessions();

  Future<void> revokeOtherSessions();
}
