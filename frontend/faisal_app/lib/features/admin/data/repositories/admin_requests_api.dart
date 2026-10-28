import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../requests/data/models/request_mapper.dart';
import '../../../requests/domain/entities/request_entities.dart';
import '../../domain/entities/admin_entities.dart';
import 'admin_mappers.dart';

/// Request review and decision API calls.
mixin AdminRequestsApi {
  DioClient get client;

  Future<AdminRequestPage> fetchRequests({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = asMap(
      await client.get(
        '/admin/requests',
        query: {
          'status': status,
          'search': search,
          'page': page,
          'page_size': pageSize,
        },
      ),
    );
    return AdminRequestPage(
      items: asMapList(json['items'])
          .map(
            (item) => AdminRequestItem(
              id: asString(item['id']),
              reference: asString(item['reference']),
              customerId: asString(item['customer_id']),
              customerName: asString(item['customer_name'], 'Customer'),
              requestType: asString(item['request_type']),
              status: asString(item['status'], 'submitted'),
              priority: asString(item['priority'], 'normal'),
              submittedAt: asDateOrNull(item['submitted_at']),
              assignedLabel: asStringOrNull(item['assigned_label']),
            ),
          )
          .toList(growable: false),
      page: asInt(json['page'], 1),
      total: asInt(json['total']),
      hasNext: asBool(json['has_next']),
    );
  }

  Future<AdminRequestDetail> fetchRequest(String requestId) async {
    final json = asMap(await client.get('/admin/requests/$requestId'));
    final customerJson = json['customer'];
    return AdminRequestDetail(
      request: RequestMapper.request(json),
      customer: customerJson is Map<String, dynamic>
          ? adminCustomerFromJson(customerJson)
          : null,
    );
  }

  Future<ServiceRequestEntity> approveRequest(
    String requestId, {
    String? reason,
    String? explanation,
  }) async {
    final data = await client.post(
      '/admin/requests/$requestId/approve',
      body: {'reason': reason, 'customer_explanation': explanation},
    );
    return RequestMapper.request(asMap(data));
  }

  Future<ServiceRequestEntity> rejectRequest(
    String requestId, {
    required String reason,
    String? explanation,
  }) async {
    final data = await client.post(
      '/admin/requests/$requestId/reject',
      body: {'reason': reason, 'customer_explanation': explanation},
    );
    return RequestMapper.request(asMap(data));
  }

  Future<ServiceRequestEntity> requestInformation(
    String requestId, {
    required String message,
    List<String> requiredFields = const <String>[],
  }) async {
    final data = await client.post(
      '/admin/requests/$requestId/request-information',
      body: {'message': message, 'required_fields': requiredFields},
    );
    return RequestMapper.request(asMap(data));
  }

  Future<ServiceRequestEntity> assignRequest(
    String requestId, {
    String? reviewerId,
  }) async {
    final data = await client.post(
      '/admin/requests/$requestId/assign',
      body: {'reviewer_id': reviewerId},
    );
    return RequestMapper.request(asMap(data));
  }

  Future<void> addNote(String requestId, String note) async {
    await client.post('/admin/requests/$requestId/notes', body: {'note': note});
  }

  Future<List<AdminReviewer>> fetchReviewers() async {
    final data = await client.get('/admin/reviewers');
    if (data is List) {
      return data
          .map(
            (item) => AdminReviewer(
              id: asString(asMap(item)['id']),
              displayName: asString(asMap(item)['display_name']),
              roles: asStringList(asMap(item)['roles']),
            ),
          )
          .toList(growable: false);
    }
    return const <AdminReviewer>[];
  }
}
