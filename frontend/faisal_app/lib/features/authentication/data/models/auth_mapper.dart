import '../../domain/entities/auth_entities.dart';

/// DTO mapping for authentication payloads.
class AuthMapper {
  const AuthMapper._();

  static SessionUser userFromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    return SessionUser(
      username: json['username'] as String?,
      id: json['id'] as String,
      maskedIdentifier: json['login_identifier_masked'] as String? ?? '',
      loginType: json['login_type'] as String? ?? 'customer',
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      profile: profileJson is Map<String, dynamic>
          ? profileFromJson(profileJson)
          : null,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      preferredLanguage: json['preferred_language'] as String?,
      preferredTheme: json['preferred_theme'] as String?,
    );
  }

  static CustomerProfileEntity profileFromJson(Map<String, dynamic> json) {
    return CustomerProfileEntity(
      id: json['id'] as String,
      customerNumber: json['customer_number'] as String? ?? '',
      firstNameEn: json['first_name_en'] as String? ?? '',
      lastNameEn: json['last_name_en'] as String? ?? '',
      firstNameAr: json['first_name_ar'] as String? ?? '',
      lastNameAr: json['last_name_ar'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      nationalIdMasked: json['national_id_masked'] as String?,
      segment: json['segment'] as String? ?? 'retail',
      identityVerified: json['identity_verified'] as bool? ?? false,
    );
  }

  static CustomerProfileEntity? profileFromProfilePayload(
    Map<String, dynamic> json,
  ) {
    final profile = json['profile'];
    if (profile is Map<String, dynamic>) {
      return profileFromJson(profile);
    }
    return null;
  }
}
