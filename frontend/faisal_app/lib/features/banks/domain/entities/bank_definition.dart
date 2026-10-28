import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../branding/domain/entities/branding_config.dart';
import 'bank_catalogue.g.dart';

class BankDefinition extends Equatable {
  const BankDefinition({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.website,
    required this.primary,
    required this.accent,
    required this.light,
    required this.dark,
    required this.registrationEnabled,
  });
  final String code, nameEn, nameAr, website, primary, accent;
  final Map<String, String> light, dark;
  final bool registrationEnabled;
  String name(String language) => language == 'ar' ? nameAr : nameEn;
  factory BankDefinition.fromJson(Map<String, dynamic> value) {
    String text(String key, int max) {
      final text = value[key];
      if (text is! String || text.isEmpty || text.length > max) {
        throw const FormatException('Invalid bank metadata');
      }
      return text;
    }

    final code = text('code', 32), website = text('website', 255);
    if (!RegExp(r'^[a-z][a-z0-9_]{1,31}$').hasMatch(code) ||
        Uri.tryParse(website)?.scheme != 'https') {
      throw const FormatException('Invalid bank identity');
    }
    Map<String, String> colors(String mode) {
      final raw = value[mode];
      if (raw is! Map || raw.length != brandingColorKeys.length) {
        throw const FormatException('Invalid bank palette');
      }
      final result = <String, String>{};
      for (final key in brandingColorKeys) {
        final color = raw[key];
        if (color is! String || !RegExp(r'^#[A-Fa-f0-9]{6}$').hasMatch(color)) {
          throw const FormatException('Invalid bank color');
        }
        result[key] = color.toUpperCase();
      }
      for (final fg in ['primary', 'error', 'text_primary', 'text_secondary']) {
        for (final bg in ['background', 'surface', 'card']) {
          if (BrandingConfig.contrastRatio(
                BrandingConfig.parseColor(result[fg]!),
                BrandingConfig.parseColor(result[bg]!),
              ) <
              4.5) {
            throw const FormatException('Unreadable bank palette');
          }
        }
      }
      if (BrandingConfig.contrastRatio(
            BrandingConfig.parseColor(result['button_text']!),
            BrandingConfig.parseColor(result['button_background']!),
          ) <
          4.5) {
        throw const FormatException('Unreadable bank button');
      }
      return Map.unmodifiable(result);
    }

    final primary = text('identity_primary', 7),
        accent = text('identity_accent', 7);
    if (!RegExp(r'^#[A-Fa-f0-9]{6}$').hasMatch(primary) ||
        !RegExp(r'^#[A-Fa-f0-9]{6}$').hasMatch(accent)) {
      throw const FormatException('Invalid bank identity color');
    }
    return BankDefinition(
      code: code,
      nameEn: text('name_en', 120),
      nameAr: text('name_ar', 120),
      website: website,
      primary: primary,
      accent: accent,
      light: colors('light'),
      dark: colors('dark'),
      registrationEnabled: value['registration_enabled'] == true,
    );
  }
  @override
  List<Object?> get props => [
    code,
    nameEn,
    nameAr,
    website,
    primary,
    accent,
    jsonEncode(light),
    jsonEncode(dark),
    registrationEnabled,
  ];
}

class BankCatalogue extends Equatable {
  const BankCatalogue(this.version, this.banks);
  final String version;
  final List<BankDefinition> banks;
  static final bundled = BankCatalogue.fromJson(
    jsonDecode(bankCatalogueJson) as Map<String, dynamic>,
  );
  factory BankCatalogue.fromJson(Map<String, dynamic> value) {
    if (value['version'] is! String ||
        value['banks'] is! List ||
        (value['banks'] as List).length > 100) {
      throw const FormatException('Invalid bank catalogue');
    }
    final banks = (value['banks'] as List)
        .map(
          (row) =>
              BankDefinition.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    if (banks.map((b) => b.code).toSet().length != banks.length) {
      throw const FormatException('Duplicate bank code');
    }
    return BankCatalogue(value['version'] as String, List.unmodifiable(banks));
  }
  BankDefinition? find(String? code) {
    for (final bank in banks) {
      if (bank.code == code) {
        return bank;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [version, banks];
}
