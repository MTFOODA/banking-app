import 'package:equatable/equatable.dart';

class RequestHistoryEntry extends Equatable {
  const RequestHistoryEntry({
    required this.id,
    required this.toStatus,
    required this.createdAt,
    this.fromStatus,
    this.note,
    this.actorLabel,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final String? actorLabel;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, toStatus, createdAt];
}

class RequestDocumentEntity extends Equatable {
  const RequestDocumentEntity({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, filename];
}

class ServiceRequestEntity extends Equatable {
  const ServiceRequestEntity({
    required this.id,
    required this.reference,
    required this.requestType,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.decidedAt,
    this.assignedLabel,
    this.decisionReason,
    this.customerExplanation,
    this.formData = const <String, dynamic>{},
    this.history = const <RequestHistoryEntry>[],
    this.documents = const <RequestDocumentEntity>[],
    this.availableActions = const <String>[],
  });

  final String id;
  final String reference;
  final String requestType;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  final String? assignedLabel;
  final String? decisionReason;
  final String? customerExplanation;
  final Map<String, dynamic> formData;
  final List<RequestHistoryEntry> history;
  final List<RequestDocumentEntity> documents;
  final List<String> availableActions;

  bool get needsCustomerAction => status == 'pending_customer_info';
  bool get isOpen =>
      status != 'completed' && status != 'rejected' && status != 'cancelled';

  @override
  List<Object?> get props => [
    id,
    reference,
    status,
    updatedAt,
    availableActions,
    documents,
  ];
}

class RequestPage extends Equatable {
  const RequestPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasNext,
  });

  final List<ServiceRequestEntity> items;
  final int page;
  final int total;
  final bool hasNext;

  @override
  List<Object?> get props => [items, page, total, hasNext];
}
