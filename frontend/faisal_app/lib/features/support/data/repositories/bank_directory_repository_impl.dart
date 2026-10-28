import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/bank_branch.dart';
import '../../domain/repositories/bank_directory_repository.dart';

/// Public directory stays available offline and does not access customer data.
class BankDirectoryRepositoryImpl implements BankDirectoryRepository {
  BankDirectoryRepositoryImpl({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
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
