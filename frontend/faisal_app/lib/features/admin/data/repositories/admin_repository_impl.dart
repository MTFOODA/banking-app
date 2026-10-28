import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_content_api.dart';
import 'admin_mappers.dart';
import 'admin_requests_api.dart';

class AdminRepositoryImpl
    with AdminContentApi, AdminRequestsApi
    implements AdminRepository {
  AdminRepositoryImpl(this.client);

  @override
  final DioClient client;

  @override
  Future<AdminDashboard> fetchDashboard() async {
    final json = asMap(await client.get('/admin/dashboard'));
    return AdminDashboard(
      customersCount: asInt(json['customers_count']),
      activeAccounts: asInt(json['active_accounts']),
      cardsByStatus: asIntMap(json['cards_by_status']),
      requestsByStatus: asIntMap(json['requests_by_status']),
      pendingRequests: asInt(json['pending_requests']),
      publishedAnnouncements: asInt(json['published_announcements']),
      scheduledMaintenance: asInt(json['scheduled_maintenance']),
      recentActions: asMapList(json['recent_actions'])
          .map(auditFromJson)
          .toList(growable: false),
      generatedAt: asDate(json['generated_at']),
      demoData: asBool(json['demo_data'], true),
    );
  }

  @override
  Future<AdminCustomerPage> fetchCustomers({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = asMap(
      await client.get(
        '/admin/customers',
        query: {'search': search, 'page': page, 'page_size': pageSize},
      ),
    );
    return AdminCustomerPage(
      items: asMapList(json['items'])
          .map(adminCustomerFromJson)
          .toList(growable: false),
      page: asInt(json['page'], 1),
      total: asInt(json['total']),
      hasNext: asBool(json['has_next']),
    );
  }

  @override
  Future<AdminCustomer> fetchCustomer(String customerId) async {
    final json = asMap(await client.get('/admin/customers/$customerId'));
    return adminCustomerFromJson(json);
  }

  @override
  Future<List<AuditEntry>> fetchAuditLogs({
    int page = 1,
    int pageSize = 50,
  }) async {
    final json = asMap(
      await client.get(
        '/admin/audit-logs',
        query: {'page': page, 'page_size': pageSize},
      ),
    );
    return asMapList(json['items']).map(auditFromJson).toList(growable: false);
  }
}
