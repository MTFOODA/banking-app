import 'package:equatable/equatable.dart';

class CustomerPreferences extends Equatable {
  const CustomerPreferences({
    this.language = 'en',
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.transactionNotifications = true,
    this.marketingNotifications = false,
    this.biometricEnabled = false,
  });

  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool transactionNotifications;
  final bool marketingNotifications;
  final bool biometricEnabled;

  CustomerPreferences copyWith({
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? transactionNotifications,
    bool? marketingNotifications,
    bool? biometricEnabled,
  }) {
    return CustomerPreferences(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      transactionNotifications:
          transactionNotifications ?? this.transactionNotifications,
      marketingNotifications:
          marketingNotifications ?? this.marketingNotifications,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'theme': theme,
    'notifications_enabled': notificationsEnabled,
    'transaction_notifications': transactionNotifications,
    'marketing_notifications': marketingNotifications,
    'biometric_enabled': biometricEnabled,
  };

  @override
  List<Object?> get props => [
    language,
    theme,
    notificationsEnabled,
    transactionNotifications,
    marketingNotifications,
    biometricEnabled,
  ];
}

class TrustedSession extends Equatable {
  const TrustedSession({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.isCurrent,
    this.userAgent,
    this.ipAddress,
    this.lastUsedAt,
  });

  final String id;
  final String? userAgent;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime expiresAt;
  final bool isCurrent;

  String get deviceLabel {
    final agent = userAgent ?? '';
    if (agent.contains('Android')) {
      return 'Android device';
    }
    if (agent.contains('iPhone') || agent.contains('iPad')) {
      return 'iOS device';
    }
    if (agent.contains('Windows')) {
      return 'Windows device';
    }
    if (agent.contains('Mac')) {
      return 'Mac device';
    }
    return agent.isEmpty ? 'Unknown device' : agent.split(' ').first;
  }

  @override
  List<Object?> get props => [id, isCurrent];
}

class ProfileDetails extends Equatable {
  const ProfileDetails({
    required this.userId,
    required this.maskedIdentifier,
    required this.firstNameEn,
    required this.lastNameEn,
    required this.firstNameAr,
    required this.lastNameAr,
    required this.customerNumber,
    this.email,
    this.phone,
    this.address,
    this.identityVerified = false,
    this.segment = 'retail',
    this.pendingReference,
    this.username,
  });

  final String userId;
  final String maskedIdentifier;
  final String firstNameEn;
  final String lastNameEn;
  final String firstNameAr;
  final String lastNameAr;
  final String customerNumber;
  final String? email;
  final String? phone;
  final String? address;
  final bool identityVerified;
  final String segment;
  final String? pendingReference;
  final String? username;

  String displayName(bool arabic) => arabic
      ? '$firstNameAr $lastNameAr'.trim()
      : '$firstNameEn $lastNameEn'.trim();

  @override
  List<Object?> get props => [userId, email, phone, address];
}
