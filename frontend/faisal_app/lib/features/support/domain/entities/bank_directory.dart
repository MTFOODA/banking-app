import 'bank_branch.dart';

class BankDirectory {
  const BankDirectory({
    required this.bankCode,
    this.version = 'bundled',
    this.branches = const [],
    this.atms = const [],
    this.branchesStatus = 'unavailable',
    this.atmsStatus = 'unavailable',
    this.reviewedAt,
    this.hotline,
    this.branchLocatorUrl,
    this.atmLocatorUrl,
    this.contactUrl,
  });
  final String bankCode, version, branchesStatus, atmsStatus;
  final List<BankBranch> branches, atms;
  final String? reviewedAt, hotline;
  final Uri? branchLocatorUrl, atmLocatorUrl, contactUrl;
  factory BankDirectory.fromJson(
    Map<String, dynamic> json,
    String expectedBank,
  ) {
    if (json['bank_code'] != expectedBank || json['version'] is! String) {
      throw const FormatException('Directory affiliation mismatch');
    }
    String status(String key) {
      final value = json[key];
      if (![
        'published',
        'partial',
        'unavailable',
        'not_applicable',
      ].contains(value)) {
        throw const FormatException('Invalid directory coverage');
      }
      return value as String;
    }

    Uri? link(String key) {
      final value = json[key];
      if (value == null) return null;
      final uri = Uri.tryParse(value as String);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const FormatException('Invalid public service link');
      }
      return uri;
    }

    List<BankBranch> rows(String kind) {
      final value = json[kind];
      if (value is! List || value.length > 10000) {
        throw const FormatException('Invalid directory list');
      }
      final ids = <String>{};
      return List.unmodifiable(
        value.map((row) {
          final map = row as Map;
          String text(String key) {
            final v = map[key];
            if (v is! String ||
                v.length > 2000 ||
                (key != 'governorate' && v.trim().isEmpty)) {
              throw const FormatException('Invalid public address');
            }
            return v;
          }

          final id = text('id'), uri = Uri.parse(text('maps_url'));
          if (!ids.add(id) ||
              uri.scheme != 'https' ||
              uri.authority != 'www.google.com' ||
              uri.path != '/maps/search/' ||
              uri.queryParameters['api'] != '1') {
            throw const FormatException('Invalid public map');
          }
          return BankBranch(
            id: id,
            name: text('name'),
            address: text('address'),
            governorate: text('governorate'),
            mapsUri: uri,
          );
        }),
      );
    }

    final hotline = json['hotline'];
    if (hotline != null &&
        (hotline is! String ||
            !RegExp(r'^\+?[0-9]{5,15}$').hasMatch(hotline))) {
      throw const FormatException('Invalid hotline');
    }
    return BankDirectory(
      bankCode: expectedBank,
      version: json['version'] as String,
      branches: rows('branches'),
      atms: rows('atms'),
      branchesStatus: status('branches_status'),
      atmsStatus: status('atms_status'),
      reviewedAt: json['reviewed_at'] as String?,
      hotline: hotline as String?,
      branchLocatorUrl: link('branch_locator_url'),
      atmLocatorUrl: link('atm_locator_url'),
      contactUrl: link('contact_url'),
    );
  }
}
