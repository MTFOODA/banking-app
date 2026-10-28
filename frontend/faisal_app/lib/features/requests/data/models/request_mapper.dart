import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/request_entities.dart';

class RequestMapper {
  const RequestMapper._();

  static ServiceRequestEntity request(Map<String, dynamic> json) {
    return ServiceRequestEntity(
      id: asString(json['id']),
      reference: asString(json['reference']),
      requestType: asString(json['request_type']),
      status: asString(json['status'], 'submitted'),
      priority: asString(json['priority'], 'normal'),
      createdAt: asDate(json['created_at']),
      updatedAt: asDate(json['updated_at']),
      submittedAt: asDateOrNull(json['submitted_at']),
      decidedAt: asDateOrNull(json['decided_at']),
      assignedLabel: asStringOrNull(json['assigned_label']),
      decisionReason: asStringOrNull(json['decision_reason']),
      customerExplanation: asStringOrNull(json['customer_explanation']),
      formData: asMap(json['form_data']),
      history: asMapList(json['history']).map(history).toList(growable: false),
      documents: asMapList(json['documents'])
          .map(document)
          .toList(growable: false),
      availableActions: asStringList(json['available_actions']),
    );
  }

  static RequestHistoryEntry history(Map<String, dynamic> json) {
    return RequestHistoryEntry(
      id: asString(json['id']),
      fromStatus: asStringOrNull(json['from_status']),
      toStatus: asString(json['to_status']),
      note: asStringOrNull(json['note']),
      actorLabel: asStringOrNull(json['actor_label']),
      createdAt: asDate(json['created_at']),
    );
  }

  static RequestDocumentEntity document(Map<String, dynamic> json) {
    return RequestDocumentEntity(
      id: asString(json['id']),
      filename: asString(json['filename']),
      contentType: asString(json['content_type']),
      sizeBytes: asInt(json['size_bytes']),
      createdAt: asDate(json['created_at']),
    );
  }

  static RequestPage page(Map<String, dynamic> json) {
    return RequestPage(
      items: asMapList(json['items']).map(request).toList(growable: false),
      page: asInt(json['page'], 1),
      total: asInt(json['total']),
      hasNext: asBool(json['has_next']),
    );
  }
}
