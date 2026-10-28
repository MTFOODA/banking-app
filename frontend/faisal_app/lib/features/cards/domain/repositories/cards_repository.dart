import '../entities/card_entities.dart';
import '../entities/card_product.dart';

abstract class CardsRepository {
  Future<List<CardProduct>> fetchProducts();
  Future<CardsOverview> fetchCards();

  Future<BankCard> fetchCard(String cardId);

  Future<BankCard> freezeCard(String cardId, {String? reason});

  Future<BankCard> unfreezeCard(String cardId);

  Future<BankCard> reportLost(
    String cardId, {
    required String reportType,
    String? note,
  });

  Future<BankCard> blockCard(String cardId, {String? reason});

  Future<BankCard> toggleControl(String cardId, String control, bool enabled);

  Future<String> requestReplacement(
    String cardId, {
    required String reason,
    String? deliveryBranch,
    bool urgent = false,
  });

  Future<String> requestLimitChange(
    String cardId, {
    required String limitType,
    required double requestedAmount,
    required String reason,
    required bool increase,
  });

  Future<String> requestSupplementary({
    required String primaryCardId,
    required String holderFirstName,
    required String holderLastName,
    required String relationship,
    required String nationalId,
    String? phone,
    String? productCode,
    required double spendingLimit,
    List<String> restrictions = const <String>[],
  });

  Future<String> requestService(
    String cardId,
    String requestType, {
    String? note,
  });

  Future<List<CardStatement>> fetchStatements(String cardId);
}
