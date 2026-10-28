import 'dart:typed_data';

import '../entities/branding_config.dart';

abstract class BrandingRepository {
  Future<BrandingSnapshot?> fetch({int? knownVersion});
  Future<Uint8List> fetchAsset(String url);
  Future<BrandingEditorDocument> editor();
  Future<BrandingEditorDocument> save(int revision, BrandingConfig config);
  Future<BrandingEditorDocument> publish(int revision);
  Future<BrandingEditorDocument> restore(int revision, {int? version});
  Future<List<BrandingHistoryEntry>> history({int? before});
  Future<String> upload(Uint8List bytes, String filename);
}
