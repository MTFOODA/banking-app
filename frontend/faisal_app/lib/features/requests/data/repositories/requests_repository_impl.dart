import 'dart:typed_data';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/request_entities.dart';
import '../../domain/repositories/requests_repository.dart';
import '../models/request_mapper.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  RequestsRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<RequestPage> fetchRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? type,
  }) async {
    final data = await _client.get(
      '/requests',
      query: {
        'page': page,
        'page_size': pageSize,
        'status': status,
        'request_type': type,
      },
    );
    return RequestMapper.page(asMap(data));
  }

  @override
  Future<ServiceRequestEntity> fetchRequest(String requestId) async {
    final data = await _client.get('/requests/$requestId');
    return RequestMapper.request(asMap(data));
  }

  @override
  Future<ServiceRequestEntity> createRequest({
    required String requestType,
    Map<String, dynamic> formData = const <String, dynamic>{},
    String? priority,
  }) async {
    final data = await _client.post(
      '/requests',
      body: {
        'request_type': requestType,
        'form_data': formData,
        'priority': ?priority,
      },
    );
    return RequestMapper.request(asMap(data));
  }

  @override
  Future<ServiceRequestEntity> provideInformation(
    String requestId, {
    required String message,
    Map<String, dynamic> fields = const <String, dynamic>{},
  }) async {
    final data = await _client.post(
      '/requests/$requestId/additional-information',
      body: {'message': message, 'fields': fields},
    );
    return RequestMapper.request(asMap(data));
  }

  @override
  Future<ServiceRequestEntity> cancelRequest(String requestId) async {
    final data = await _client.post('/requests/$requestId/cancel');
    return RequestMapper.request(asMap(data));
  }

  @override
  Future<void> uploadDocument({
    required String requestId,
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await _client.upload(
      '/requests/$requestId/documents',
      filename: filename,
      bytes: bytes,
      contentType: contentType,
    );
  }
}
