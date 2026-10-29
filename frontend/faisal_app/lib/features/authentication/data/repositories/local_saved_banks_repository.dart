import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/security/session_store.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/entities/saved_bank.dart';
import '../../domain/repositories/saved_banks_repository.dart';

/// Preferences contain only usernames and bank IDs. Refresh credentials use the
/// existing platform keystore (memory only on web); passwords are never saved.
class LocalSavedBanksRepository implements SavedBanksRepository {
  LocalSavedBanksRepository(this.preferences, this.store) {
    try {
      final raw = jsonDecode(preferences?.getString(key) ?? '[]') as List;
      final seen = <String>{};
      for (final item in raw.take(100)) {
        final id = item['user_id'] as String;
        final bank = item['bank_code'] as String;
        final username = item['username'] as String;
        if (RegExp(r'^[a-zA-Z0-9-]{1,80}$').hasMatch(id) &&
            BankCatalogue.bundled.find(bank) != null &&
            RegExp(r'^[a-zA-Z0-9]{3,64}$').hasMatch(username) &&
            seen.add(id)) {
          _entries.add(
            SavedBank(userId: id, bankCode: bank, username: username),
          );
        }
      }
    } catch (_) {
      /* Corrupt metadata never activates a session. */
    }
  }
  static const key = 'banking.saved_banks.v1';
  final SharedPreferences? preferences;
  final SessionStore store;
  final _entries = <SavedBank>[];
  final _changes = StreamController<List<SavedBank>>.broadcast();
  @override
  List<SavedBank> get entries => List.unmodifiable(_entries);
  @override
  Stream<List<SavedBank>> get changes => _changes.stream;
  @override
  SavedBank? pendingLogin;

  @override
  Future<void> remember(SessionUser user, String refreshToken) async {
    final code = user.profile?.bankCode;
    if (user.isStaff ||
        user.mustChangePassword ||
        code == null ||
        BankCatalogue.bundled.find(code) == null ||
        user.username == null) {
      return;
    }
    final entry = SavedBank(
      userId: user.id,
      bankCode: code,
      username: user.username!,
    );
    await store.saveBankCredential(user.id, refreshToken);
    _entries.removeWhere((item) => item.userId == user.id);
    _entries.insert(0, entry);
    pendingLogin = null;
    try {
      await preferences?.setString(
        key,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      /* Keep the chooser usable in memory. */
    }
    _changes.add(entries);
  }

  @override
  Future<String?> credential(SavedBank entry) async =>
      entries.contains(entry) ? store.bankCredential(entry.userId) : null;

  @override
  Future<void> invalidate(String userId) => store.deleteBankCredential(userId);
  Future<void> dispose() => _changes.close();
}
