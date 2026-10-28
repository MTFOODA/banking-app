import 'package:equatable/equatable.dart';

import '../../../requests/domain/entities/request_entities.dart';

class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.actorLabel,
    this.entityId,
    this.details = const <String, dynamic>{},
    this.ipAddress,
  });

  final String id;
  final String? actorLabel;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, action, createdAt];
}

class AdminDashboard extends Equatable {
  const AdminDashboard({
    required this.customersCount,
    required this.activeAccounts,
    required this.cardsByStatus,
    required this.requestsByStatus,
    required this.pendingRequests,
    required this.publishedAnnouncements,
    required this.scheduledMaintenance,
    required this.recentActions,
    required this.generatedAt,
    this.demoData = true,
  });

  final int customersCount;
  final int activeAccounts;
  final Map<String, int> cardsByStatus;
  final Map<String, int> requestsByStatus;
  final int pendingRequests;
  final int publishedAnnouncements;
  final int scheduledMaintenance;
  final List<AuditEntry> recentActions;
  final DateTime generatedAt;
  final bool demoData;

  @override
  List<Object?> get props => [
    customersCount,
    activeAccounts,
    pendingRequests,
    publishedAnnouncements,
    scheduledMaintenance,
    generatedAt,
  ];
}

class AdminCustomer extends Equatable {
  const AdminCustomer({
    required this.id,
    required this.customerNumber,
    required this.nameEn,
    required this.nameAr,
    required this.segment,
    required this.identityVerified,
    required this.isActive,
    required this.mustChangePassword,
    required this.accountsCount,
    required this.cardsCount,
    required this.openRequests,
    required this.createdAt,
    this.email,
    this.phone,
    this.nationalIdMasked,
    this.dateOfBirth,
  });

  final String id;
  final String customerNumber;
  final String nameEn;
  final String nameAr;
  final String? email;
  final String? phone;
  final String segment;
  final bool identityVerified;
  final bool isActive;
  final bool mustChangePassword;
  final int accountsCount;
  final int cardsCount;
  final int openRequests;
  final DateTime createdAt;
  final String? nationalIdMasked;
  final String? dateOfBirth;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  @override
  List<Object?> get props => [
    id,
    isActive,
    accountsCount,
    cardsCount,
    openRequests,
  ];
}

class AdminCustomerPage extends Equatable {
  const AdminCustomerPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasNext,
  });

  final List<AdminCustomer> items;
  final int page;
  final int total;
  final bool hasNext;

  @override
  List<Object?> get props => [items, page, total];
}

class AdminRequestItem extends Equatable {
  const AdminRequestItem({
    required this.id,
    required this.reference,
    required this.customerId,
    required this.customerName,
    required this.requestType,
    required this.status,
    required this.priority,
    this.submittedAt,
    this.assignedLabel,
  });

  final String id;
  final String reference;
  final String customerId;
  final String customerName;
  final String requestType;
  final String status;
  final String priority;
  final DateTime? submittedAt;
  final String? assignedLabel;

  @override
  List<Object?> get props => [id, status, assignedLabel];
}

class AdminRequestPage extends Equatable {
  const AdminRequestPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasNext,
  });

  final List<AdminRequestItem> items;
  final int page;
  final int total;
  final bool hasNext;

  @override
  List<Object?> get props => [items, page, total];
}

class AdminReviewer extends Equatable {
  const AdminReviewer({
    required this.id,
    required this.displayName,
    required this.roles,
  });

  final String id;
  final String displayName;
  final List<String> roles;

  @override
  List<Object?> get props => [id, displayName];
}

class AdminRequestDetail {
  const AdminRequestDetail({required this.request, this.customer});

  final ServiceRequestEntity request;
  final AdminCustomer? customer;
}
