import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

const brandingColorKeys = <String>[
  'primary',
  'secondary',
  'accent',
  'background',
  'surface',
  'text_primary',
  'text_secondary',
  'error',
  'button_background',
  'button_text',
  'card',
  'border',
];
const brandingFonts = ['System', 'NotoSans', 'NotoSansArabic'];
const brandingAssetFields = ['logo_url', 'dark_logo_url', 'splash_image_url'];

/// Immutable, versioned public configuration. Defaults preserve existing UI.
class BrandingConfig extends Equatable {
  BrandingConfig._(Map<String, dynamic> data)
    : _json = jsonEncode(data),
      data = Map.unmodifiable(data);
  final Map<String, dynamic> data;
  final String _json;
  static final defaults = BrandingConfig._({
    'schema_version': 1,
    'application_name': null,
    'application_short_name': null,
    'application_tagline': null,
    'welcome_message': null,
    'logo_url': null,
    'dark_logo_url': null,
    'splash_image_url': null,
    'custom_theme': false,
    'light': Map<String, String>.unmodifiable(
      Map.fromIterables(brandingColorKeys, [
        '#075C46',
        '#0B795A',
        '#C8A44D',
        '#F4F9F5',
        '#FFFFFF',
        '#172923',
        '#52635A',
        '#C83C42',
        '#075C46',
        '#FFFFFF',
        '#FFFFFF',
        '#E5EBE6',
      ]),
    ),
    'dark': Map<String, String>.unmodifiable(
      Map.fromIterables(brandingColorKeys, [
        '#58B394',
        '#9FD7C2',
        '#D9B862',
        '#0B1F19',
        '#0B1F19',
        '#F2F7F4',
        '#9DB2A8',
        '#F0737A',
        '#58B394',
        '#0B1F19',
        '#123027',
        '#24463A',
      ]),
    ),
    'primary_font': 'System',
    'arabic_font': 'System',
    'english_font': 'System',
    'font_size_scale': 1.0,
    'heading_font_weight': 700,
    'body_font_weight': 400,
    'theme_mode': 'user',
  });

  factory BrandingConfig.fromJson(Map<String, dynamic> input) {
    if (input.keys.any((k) => !defaults.data.containsKey(k)) ||
        input['schema_version'] != 1) {
      throw const FormatException('Unsupported branding configuration');
    }
    final data = <String, dynamic>{...defaults.toJson(), ...input};
    final lengths = {
      'application_name': 40,
      'application_short_name': 20,
      'application_tagline': 100,
      'welcome_message': 160,
    };
    for (final entry in lengths.entries) {
      final value = data[entry.key];
      if (value != null &&
          (value is! String ||
              value.length > entry.value ||
              value != value.trim() ||
              RegExp(r'[\x00-\x1f\u202a-\u202e\u2066-\u2069]')
                  .hasMatch(value) ||
              (entry.key.contains('name') && value.isEmpty))) {
        throw const FormatException('Invalid branding text');
      }
    }
    for (final field in brandingAssetFields) {
      if (data[field] != null &&
          (data[field] is! String ||
              !RegExp(r'^/branding/assets/[a-f0-9]{64}\.png$')
                  .hasMatch(data[field]))) {
        throw const FormatException('Unsafe branding asset');
      }
    }
    if (data['custom_theme'] is! bool ||
        !['user', 'system', 'light', 'dark'].contains(data['theme_mode']) ||
        !brandingFonts.contains(data['primary_font']) ||
        !['System', 'NotoSansArabic'].contains(data['arabic_font']) ||
        !['System', 'NotoSans'].contains(data['english_font']) ||
        ![400, 500, 600, 700].contains(data['heading_font_weight']) ||
        ![400, 500, 600].contains(data['body_font_weight'])) {
      throw const FormatException('Invalid branding appearance');
    }
    final scale = data['font_size_scale'];
    if (scale is! num || !scale.isFinite || scale < .9 || scale > 1.15) {
      throw const FormatException('Invalid font scale');
    }
    for (final mode in ['light', 'dark']) {
      final value = data[mode];
      if (value is! Map || value.length != brandingColorKeys.length) {
        throw const FormatException('Invalid branding colors');
      }
      final colors = <String, String>{};
      for (final key in brandingColorKeys) {
        final color = value[key];
        if (color is! String || !RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(color)) {
          throw const FormatException('Use #RRGGBB colors');
        }
        colors[key] = color.toUpperCase();
      }
      for (final fg in ['text_primary', 'text_secondary', 'primary', 'error']) {
        for (final bg in ['surface', 'background', 'card']) {
          if (contrastRatio(parseColor(colors[fg]!), parseColor(colors[bg]!)) <
              4.5) {
            throw const FormatException('Text contrast must be at least 4.5:1');
          }
        }
      }
      if (contrastRatio(
            parseColor(colors['button_text']!),
            parseColor(colors['button_background']!),
          ) <
          4.5) {
        throw const FormatException('Button contrast must be at least 4.5:1');
      }
      data[mode] = Map<String, String>.unmodifiable(colors);
    }
    return BrandingConfig._(data);
  }
  Map<String, dynamic> toJson() => jsonDecode(_json) as Map<String, dynamic>;
  String? text(String key) => data[key] as String?;
  bool get customTheme => data['custom_theme'] as bool;
  Color color(String key, Brightness brightness) =>
      parseColor((data[brightness.name] as Map)[key] as String);
  static Color parseColor(String value) =>
      Color(0xff000000 | int.parse(value.substring(1), radix: 16));
  static double contrastRatio(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
  }

  @override
  List<Object?> get props => [_json];
}

class BrandingSnapshot extends Equatable {
  const BrandingSnapshot(this.version, this.config);
  final int version;
  final BrandingConfig config;
  factory BrandingSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['configuration_version'];
    if (version is! int || version < 0) {
      throw const FormatException('Invalid branding version');
    }
    return BrandingSnapshot(
      version,
      BrandingConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map)),
    );
  }
  Map<String, dynamic> toJson() => {
    'configuration_version': version,
    'config': config.toJson(),
  };
  @override
  List<Object?> get props => [version, config];
}

class BrandingEditorDocument {
  const BrandingEditorDocument({
    required this.revision,
    required this.active,
    this.draft,
  });
  final int revision;
  final BrandingSnapshot active;
  final BrandingConfig? draft;
  factory BrandingEditorDocument.fromJson(Map<String, dynamic> json) =>
      BrandingEditorDocument(
        revision: json['revision'] as int,
        active: BrandingSnapshot.fromJson(json),
        draft: json['draft'] == null
            ? null
            : BrandingConfig.fromJson(
                Map<String, dynamic>.from(json['draft'] as Map),
              ),
      );
}

class BrandingHistoryEntry {
  const BrandingHistoryEntry(this.version, this.publishedAt, this.config);
  final int version;
  final DateTime publishedAt;
  final BrandingConfig config;
}
