import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/branding_config.dart';
import '../../domain/repositories/branding_repository.dart';

class BrandingRepositoryImpl implements BrandingRepository {
  BrandingRepositoryImpl(this.client);
  final DioClient client;
  @override
  Future<Uint8List> fetchAsset(String url) async {
    if (!RegExp(r'^/branding/assets/[a-f0-9]{64}\.png$').hasMatch(url)) {
      throw const FormatException('Unsafe branding asset');
    }
    final cancellation = CancelToken();
    final response = await client.raw.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancellation,
      onReceiveProgress: (received, total) {
        if (received > 2 * 1024 * 1024) {
          cancellation.cancel('Branding image size limit');
        }
      },
    );
    final data = response.data!;
    if (data.length > 2 * 1024 * 1024) {
      throw const FormatException('Branding image too large');
    }
    return Uint8List.fromList(data);
  }

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  @override
  Future<BrandingSnapshot?> fetch({int? knownVersion}) async {
    final data = _map(
      await client.get('/branding', query: {'known_version': knownVersion}),
    );
    return data['unchanged'] == true ? null : BrandingSnapshot.fromJson(data);
  }

  @override
  Future<BrandingEditorDocument> editor() async =>
      BrandingEditorDocument.fromJson(
        _map(await client.get('/admin/branding')),
      );
  @override
  Future<BrandingEditorDocument> save(
    int revision,
    BrandingConfig config,
  ) async => BrandingEditorDocument.fromJson(
    _map(
      await client.patch(
        '/admin/branding/draft',
        body: {'expected_revision': revision, 'config': config.toJson()},
      ),
    ),
  );
  @override
  Future<BrandingEditorDocument> publish(int revision) async =>
      BrandingEditorDocument.fromJson(
        _map(
          await client.post(
            '/admin/branding/publish',
            body: {'expected_revision': revision},
          ),
        ),
      );
  @override
  Future<BrandingEditorDocument> restore(int revision, {int? version}) async =>
      BrandingEditorDocument.fromJson(
        _map(
          await client.post(
            version == null
                ? '/admin/branding/defaults'
                : '/admin/branding/history/$version/restore',
            body: {'expected_revision': revision},
          ),
        ),
      );
  @override
  Future<List<BrandingHistoryEntry>> history({int? before}) async {
    final data = await client.get(
      '/admin/branding/history',
      query: {'before': before},
    ) as List;
    return data.map((value) {
      final row = _map(value);
      return BrandingHistoryEntry(
        row['version'] as int,
        DateTime.parse(row['published_at'] as String),
        BrandingConfig.fromJson(_map(row['config'])),
      );
    }).toList();
  }

  @override
  Future<String> upload(Uint8List bytes, String filename) async {
    final lower = filename.toLowerCase();
    if (bytes.length > 2 * 1024 * 1024 ||
        (!lower.endsWith('.png') &&
            !lower.endsWith('.jpg') &&
            !lower.endsWith('.jpeg'))) {
      throw const FormatException('PNG/JPEG, maximum 2 MB');
    }
    return _map(
          await client.upload(
            '/admin/branding/assets',
            bytes: bytes,
            filename: filename,
            contentType: lower.endsWith('.png') ? 'image/png' : 'image/jpeg',
          ),
        )['url']
        as String;
  }
}
