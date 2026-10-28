import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/support_entities.dart';
import '../../domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._client);

  final DioClient _client;

  @override
  Future<List<SupportTicketEntity>> fetchTickets() async {
    final data = await _client.get('/support/tickets');
    if (data is List) {
      return data.map((item) => _ticket(asMap(item))).toList(growable: false);
    }
    return const <SupportTicketEntity>[];
  }

  @override
  Future<SupportTicketEntity> createTicket({
    required String subject,
    required String message,
    String priority = 'normal',
  }) async {
    final data = await _client.post(
      '/support/tickets',
      body: {'subject': subject, 'message': message, 'priority': priority},
    );
    return _ticket(asMap(data));
  }

  @override
  Future<SupportTicketEntity> sendMessage(
    String ticketId,
    String message,
  ) async {
    final data = await _client.post(
      '/support/tickets/$ticketId/messages',
      body: {'message': message},
    );
    return _ticket(asMap(data));
  }

  SupportTicketEntity _ticket(Map<String, dynamic> json) {
    return SupportTicketEntity(
      id: asString(json['id']),
      reference: asString(json['reference']),
      subject: asString(json['subject']),
      status: asString(json['status'], 'open'),
      priority: asString(json['priority'], 'normal'),
      createdAt: asDate(json['created_at']),
      messages: asMapList(json['messages'])
          .map(
            (item) => SupportMessageEntity(
              id: asString(item['id']),
              senderType: asString(item['sender_type'], 'customer'),
              body: asString(item['body']),
              createdAt: asDate(item['created_at']),
            ),
          )
          .toList(growable: false),
    );
  }
}
