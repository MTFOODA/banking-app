import 'package:equatable/equatable.dart';

class SupportMessageEntity extends Equatable {
  const SupportMessageEntity({
    required this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String senderType;
  final String body;
  final DateTime createdAt;

  bool get fromBank => senderType != 'customer';

  @override
  List<Object?> get props => [id, body, createdAt];
}

class SupportTicketEntity extends Equatable {
  const SupportTicketEntity({
    required this.id,
    required this.reference,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.messages = const <SupportMessageEntity>[],
  });

  final String id;
  final String reference;
  final String subject;
  final String status;
  final String priority;
  final DateTime createdAt;
  final List<SupportMessageEntity> messages;

  @override
  List<Object?> get props => [id, status, messages];
}

class SupportRepositoryContract {
  const SupportRepositoryContract();
}
