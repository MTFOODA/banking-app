import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/branding_config.dart';
import '../domain/repositories/branding_repository.dart';

/// Small, non-secret raster cache in the existing preference store. Storage
/// failure never replaces a valid image/configuration or blocks startup.
class BrandingAssetCache {
  BrandingAssetCache(this.repository, this.preferences);
  final BrandingRepository repository;
  final SharedPreferences? preferences;
  final _memory = <String, Uint8List>{};
  final _inFlight = <String, Future<Uint8List?>>{};
  Set<String>? _retained;
  static const prefix = 'faisal.branding.image.';
  Uint8List? read(String url) {
    if (_memory.containsKey(url)) {
      return _memory[url];
    }
    try {
      final encoded = preferences?.getString('$prefix${url.split('/').last}');
      if (encoded != null && encoded.length < 2800000) {
        final bytes = base64Decode(encoded);
        if (_isPng(bytes)) {
          return _memory[url] = bytes;
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isPng(Uint8List bytes) =>
      bytes.length > 8 &&
      bytes.length <= 2 * 1024 * 1024 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71;
  Future<Uint8List?> load(String url) {
    final cached = read(url);
    if (cached != null) {
      return Future.value(cached);
    }
    return _inFlight[url] ??= _download(url).whenComplete(() {
      _inFlight.remove(url);
    });
  }

  Future<Uint8List?> _download(String url) async {
    try {
      final bytes = await repository.fetchAsset(url);
      if (!_isPng(bytes)) {
        return null;
      }
      if (_retained != null && !_retained!.contains(url)) {
        return bytes;
      }
      _memory[url] = bytes;
      try {
        await preferences?.setString(
          '$prefix${url.split('/').last}',
          base64Encode(bytes),
        );
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> retain(BrandingConfig config) async {
    final urls = brandingAssetFields
        .map(config.text)
        .whereType<String>()
        .toSet();
    _retained = urls;
    final keys = urls.map((url) => '$prefix${url.split('/').last}').toSet();
    _memory.removeWhere((key, _) => !urls.contains(key));
    for (final key
        in preferences
                ?.getKeys()
                .where((key) => key.startsWith(prefix) && !keys.contains(key))
                .toList() ??
            <String>[]) {
      try {
        await preferences?.remove(key);
      } catch (_) {}
    }
    await Future.wait(urls.map(load));
  }
}
