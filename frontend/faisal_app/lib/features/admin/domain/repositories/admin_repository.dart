import '../../../products/domain/entities/discover_entities.dart';
import '../../../requests/domain/entities/request_entities.dart';
import '../entities/admin_entities.dart';

abstract class AdminRepository {
  Future<AdminDashboard> fetchDashboard();

  Future<AdminCustomerPage> fetchCustomers({
    String? search,
    int page,
    int pageSize,
  });

  Future<AdminCustomer> fetchCustomer(String customerId);

  Future<AdminRequestPage> fetchRequests({
    String? status,
    String? search,
    int page,
    int pageSize,
  });

  Future<AdminRequestDetail> fetchRequest(String requestId);

  Future<ServiceRequestEntity> approveRequest(
    String requestId, {
    String? reason,
    String? explanation,
  });

  Future<ServiceRequestEntity> rejectRequest(
    String requestId, {
    required String reason,
    String? explanation,
  });

  Future<ServiceRequestEntity> requestInformation(
    String requestId, {
    required String message,
    List<String> requiredFields,
  });

  Future<ServiceRequestEntity> assignRequest(
    String requestId, {
    String? reviewerId,
  });

  Future<void> addNote(String requestId, String note);

  Future<List<AdminReviewer>> fetchReviewers();

  Future<List<Announcement>> fetchAnnouncements();

  Future<Announcement> createAnnouncement(Map<String, dynamic> payload);

  Future<Announcement> updateAnnouncement(
    String id,
    Map<String, dynamic> payload,
  );

  Future<Announcement> publishAnnouncement(String id);

  Future<Announcement> archiveAnnouncement(String id);

  Future<Announcement> duplicateAnnouncement(String id);

  Future<List<BankingProduct>> fetchProducts();

  Future<BankingProduct> createProduct(Map<String, dynamic> payload);

  Future<List<Offer>> fetchOffers();

  Future<Offer> createOffer(Map<String, dynamic> payload);

  Future<List<AuditEntry>> fetchAuditLogs({int page, int pageSize});
}
