import '../entities/support_entities.dart';

abstract class SupportRepository {
  Future<List<SupportTicketEntity>> fetchTickets();

  Future<SupportTicketEntity> createTicket({
    required String subject,
    required String message,
    String priority = 'normal',
  });

  Future<SupportTicketEntity> sendMessage(String ticketId, String message);
}
