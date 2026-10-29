import 'package:equatable/equatable.dart';

/// Non-secret chooser metadata. Identity and ownership are revalidated by the API.
class SavedBank extends Equatable {
  const SavedBank({
    required this.userId,
    required this.bankCode,
    required this.username,
  });
  final String userId, bankCode, username;
  Map<String, String> toJson() => {
    'user_id': userId,
    'bank_code': bankCode,
    'username': username,
  };
  @override
  List<Object?> get props => [userId, bankCode, username];
}
