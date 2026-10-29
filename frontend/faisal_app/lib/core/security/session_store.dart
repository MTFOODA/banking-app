import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exception.dart';

/// Token storage backed by the platform keystore.
///
/// The web build falls back to an in-memory store because browser secure
/// storage requires additional host configuration; tokens are then cleared when
/// the tab closes. No password or card number is ever persisted.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              migrateWithBackup: true,
              resetOnError: false,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// A stalled platform keystore must never block application start-up.
  static const Duration _storageTimeout = Duration(seconds: 5);

  static const String _accessKey = 'faisal.access_token';
  static const String _refreshKey = 'faisal.refresh_token';
  static const String _setupKey = 'faisal.setup_token';

  final FlutterSecureStorage _storage;
  final Map<String, String> _memory = <String, String>{};
  bool _useMemoryFallback = kIsWeb;

  String? _accessToken;
  String? _refreshToken;
  String? _setupToken;
  String? activeUserId;
  bool activeIsStaff = false;
  int generation = 0;
  Future<void> _operations = Future.value();

  Future<void> _serialize(Future<void> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.catchError((Object _) {});
    return next;
  }

  Future<void> bindIdentity(String id, {required bool isStaff}) async {
    activeUserId = id;
    activeIsStaff = isStaff;
    await _write(
      'banking.active_identity',
      jsonEncode({'id': id, 'staff': isStaff}),
    );
  }

  Future<String?> bankCredential(String id) =>
      _read('banking.bank_refresh.$id');
  Future<void> saveBankCredential(String id, String token) =>
      _write('banking.bank_refresh.$id', token);
  Future<void> deleteBankCredential(String id) =>
      _delete('banking.bank_refresh.$id');

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get setupToken => _setupToken;
  bool get hasSession => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> load() async {
    _accessToken = await _read(_accessKey);
    _refreshToken = await _read(_refreshKey);
    _setupToken = await _read(_setupKey);
    try {
      final identity =
          jsonDecode(await _read('banking.active_identity') ?? '{}') as Map;
      activeUserId = identity['id'] as String?;
      activeIsStaff = identity['staff'] == true;
    } catch (_) {
      /* Legacy sessions are classified by /auth/me. */
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    String? userId,
    bool isStaff = false,
    int? expectedGeneration,
  }) => _serialize(() async {
    if (expectedGeneration != null && expectedGeneration != generation) {
      throw const AppException(code: AppErrorCode.unauthorized);
    }
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _setupToken = null;
    await _write(_accessKey, accessToken);
    await _write(_refreshKey, refreshToken);
    await _delete(_setupKey);
    if (userId != null &&
        (expectedGeneration == null || expectedGeneration == generation)) {
      await bindIdentity(userId, isStaff: isStaff);
    }
  });

  Future<void> saveSetupToken(String token) async {
    final expected = generation;
    await _serialize(() async {
      if (expected != generation) {
        throw const AppException(code: AppErrorCode.unauthorized);
      }
      _setupToken = token;
      await _write(_setupKey, token);
    });
  }

  Future<void> clear() async {
    generation++;
    _accessToken = null;
    _refreshToken = null;
    _setupToken = null;
    activeUserId = null;
    activeIsStaff = false;
    await _serialize(() async {
      // A queued write may have completed after RAM was cleared above.
      _accessToken = null;
      _refreshToken = null;
      _setupToken = null;
      await _delete(_accessKey);
      await _delete(_refreshKey);
      await _delete(_setupKey);
      await _delete('banking.active_identity');
    });
  }

  Future<String?> _read(String key) async {
    if (_useMemoryFallback) {
      return _memory[key];
    }
    try {
      return await _storage.read(key: key).timeout(_storageTimeout);
    } catch (_) {
      _useMemoryFallback = true;
      return _memory[key];
    }
  }

  Future<void> _write(String key, String value) async {
    _memory[key] = value;
    if (_useMemoryFallback) {
      return;
    }
    try {
      await _storage.write(key: key, value: value).timeout(_storageTimeout);
    } catch (_) {
      _useMemoryFallback = true;
    }
  }

  Future<void> _delete(String key) async {
    _memory.remove(key);
    if (_useMemoryFallback) {
      return;
    }
    try {
      await _storage.delete(key: key).timeout(_storageTimeout);
    } catch (_) {
      _useMemoryFallback = true;
    }
  }

  @visibleForTesting
  Map<String, String> get debugMemory =>
      Map<String, String>.unmodifiable(_memory);

  @visibleForTesting
  static String encodeStub(Object value) => jsonEncode(value);
}
