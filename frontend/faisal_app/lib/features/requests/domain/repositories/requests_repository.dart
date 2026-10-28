import 'dart:typed_data';

import '../entities/request_entities.dart';

abstract class RequestsRepository {
  Future<RequestPage> fetchRequests({
    int page,
    int pageSize,
    String? status,
    String? type,
  });

  Future<ServiceRequestEntity> fetchRequest(String requestId);

  Future<ServiceRequestEntity> createRequest({
    required String requestType,
    Map<String, dynamic> formData,
    String? priority,
  });

  Future<ServiceRequestEntity> provideInformation(
    String requestId, {
    required String message,
    Map<String, dynamic> fields,
  });

  Future<ServiceRequestEntity> cancelRequest(String requestId);

  Future<void> uploadDocument({
    required String requestId,
    required String filename,
    required Uint8List bytes,
    String? contentType,
  });
}
