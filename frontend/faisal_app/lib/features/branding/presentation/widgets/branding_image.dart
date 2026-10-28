import 'package:flutter/material.dart';

import 'dart:typed_data';

import '../../data/branding_asset_cache.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/security/session_store.dart';
import 'branding_scope.dart';

/// Only validated same-API images; Flutter's image cache reuses immutable URLs.
class BrandingImage extends StatelessWidget {
  const BrandingImage({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.label,
  });
  final String? url;
  final Widget fallback;
  final double? width, height;
  final String? label;
  @override
  Widget build(BuildContext context) {
    if (url == null ||
        !RegExp(r'^/branding/assets/[a-f0-9]{64}\.png$').hasMatch(url!)) {
      return fallback;
    }
    final preview = BrandingScope.isPreview(context);
    if (!preview && sl.isRegistered<BrandingAssetCache>()) {
      final cache = sl<BrandingAssetCache>();
      Widget raster(Uint8List? bytes) => bytes == null
          ? fallback
          : Image.memory(
              bytes,
              width: width,
              height: height,
              fit: BoxFit.contain,
              semanticLabel: label,
              errorBuilder: (_, _, _) => fallback,
            );
      final cached = cache.read(url!);
      if (cached != null) {
        return raster(cached);
      }
      return FutureBuilder<Uint8List?>(
        future: cache.load(url!),
        builder: (_, snapshot) => raster(snapshot.data),
      );
    }
    final uri = '${AppConfig.apiBaseUrl}${preview ? '/admin' : ''}$url';
    final token = preview && sl.isRegistered<SessionStore>()
        ? sl<SessionStore>().accessToken
        : null;
    return Image.network(
      uri,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: label,
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
