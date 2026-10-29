import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../../banks/domain/entities/bank_definition.dart';
import '../../domain/entities/bank_directory.dart';

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/bank_branch.dart';
import '../../domain/repositories/bank_directory_repository.dart';

/// Public directory stays available offline and does not access customer data.
class BankDirectoryRepositoryImpl implements BankDirectoryRepository {
  BankDirectoryRepositoryImpl({
    AssetBundle? bundle,
    this.client,
    this.preferences,
  }) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final DioClient? client;
  final SharedPreferences? preferences;
  final Map<String, BankDirectory> _memory = {};
  final Map<String, Future<BankDirectory>> _requests = {};
  static String cacheKey(String bankCode) => 'banking.directory.v1.$bankCode';
  @override
  Future<BankDirectory> loadDirectory(
    String bankCode, {
    bool refresh = false,
  }) async {
    if (BankCatalogue.bundled.find(bankCode) == null) {
      throw const AppException(code: AppErrorCode.unknown);
    }
    var cached = _memory[bankCode];
    if (cached == null) {
      try {
        final raw = preferences?.getString(cacheKey(bankCode));
        if (raw != null) {
          cached = BankDirectory.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
            bankCode,
          );
        }
      } catch (_) {}
      if (cached == null) {
        try {
          final raw = await _bundle.loadString(
            'assets/data/bank_directories/$bankCode.json',
          );
          cached = BankDirectory.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
            bankCode,
          );
        } catch (_) {
          if (bankCode == 'faisal') {
            cached = BankDirectory(
              bankCode: bankCode,
              branches: await loadBranches(),
              branchesStatus: 'published',
            );
          } else {
            cached = BankDirectory(bankCode: bankCode);
          }
        }
      }
      _memory[bankCode] = cached;
    }
    if (!refresh || client == null) return cached;
    return _requests[bankCode] ??= _refresh(
      bankCode,
      cached,
    ).whenComplete(() => _requests.remove(bankCode));
  }

  Future<BankDirectory> _refresh(String bankCode, BankDirectory cached) async {
    try {
      final raw = await client!.get(
        '/banks/$bankCode/directory',
        query: {'known_version': cached.version},
      );
      if (raw is! Map) return cached;
      if (raw['unchanged'] == true &&
          raw['bank_code'] == bankCode &&
          raw['version'] == cached.version) {
        return cached;
      }
      final json = Map<String, dynamic>.from(raw);
      final next = BankDirectory.fromJson(json, bankCode);
      _memory[bankCode] = next;
      try {
        await preferences?.setString(cacheKey(bankCode), jsonEncode(json));
      } catch (_) {}
      return next;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<List<BankBranch>> loadBranches() async {
    try {
      final data = jsonDecode(
        await _bundle.loadString('assets/data/bank_branches.json'),
      ) as Map;
      return List.unmodifiable(
        (data['branches'] as List).map((row) {
          final uri = Uri.parse(row['maps_url'] as String);
          if (uri.scheme != 'https' ||
              uri.host != 'www.google.com' ||
              uri.path != '/maps/search/') {
            throw const FormatException('Invalid branch map URI');
          }
          return BankBranch(
            id: row['id'] as String,
            name: row['name'] as String,
            governorate: row['governorate'] as String,
            address: row['address'] as String,
            mapsUri: uri,
          );
        }),
      );
    } catch (_) {
      throw const AppException(code: AppErrorCode.unknown);
    }
  }
}
