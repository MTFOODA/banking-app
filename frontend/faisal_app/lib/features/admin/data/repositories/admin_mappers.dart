import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/admin_entities.dart';

AdminCustomer adminCustomerFromJson(Map<String, dynamic> json) {
  return AdminCustomer(
    id: asString(json['id']),
    customerNumber: asString(json['customer_number']),
    nameEn: asString(json['name_en']),
    nameAr: asString(json['name_ar']),
    email: asStringOrNull(json['email']),
    phone: asStringOrNull(json['phone']),
    segment: asString(json['segment'], 'retail'),
    identityVerified: asBool(json['identity_verified']),
    isActive: asBool(json['is_active'], true),
    mustChangePassword: asBool(json['must_change_password']),
    accountsCount: asInt(json['accounts_count']),
    cardsCount: asInt(json['cards_count']),
    openRequests: asInt(json['open_requests']),
    createdAt: asDate(json['created_at']),
    nationalIdMasked: asStringOrNull(json['national_id_masked']),
    dateOfBirth: asStringOrNull(json['date_of_birth']),
  );
}

AuditEntry auditFromJson(Map<String, dynamic> json) {
  return AuditEntry(
    id: asString(json['id']),
    actorLabel: asStringOrNull(json['actor_label']),
    action: asString(json['action']),
    entityType: asString(json['entity_type']),
    entityId: asStringOrNull(json['entity_id']),
    details: asMap(json['details']),
    ipAddress: asStringOrNull(json['ip_address']),
    createdAt: asDate(json['created_at']),
  );
}
