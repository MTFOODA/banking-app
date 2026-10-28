import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/transaction_entities.dart';

class TransactionMapper {
  const TransactionMapper._();

  static BankTransaction transaction(Map<String, dynamic> json) {
    return BankTransaction(
      id: asString(json['id']),
      reference: asString(json['reference']),
      type: asString(json['transaction_type'], 'transfer'),
      direction: asString(json['direction'], 'debit'),
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], 'EGP'),
      description: asString(json['description']),
      descriptionAr: asStringOrNull(json['description_ar']),
      counterparty: asStringOrNull(json['counterparty']),
      merchant: asStringOrNull(json['merchant']),
      status: asString(json['status'], 'posted'),
      isSimulated: asBool(json['is_simulated'], true),
      balanceAfter: json['balance_after'] == null
          ? null
          : asDouble(json['balance_after']),
      occurredAt: asDate(json['occurred_at']),
      accountId: asStringOrNull(json['account_id']),
      cardId: asStringOrNull(json['card_id']),
      cardLast4: asStringOrNull(json['card_last4']),
      accountNumberMasked: asStringOrNull(json['account_number_masked']),
      fees: asDouble(json['fees']),
    );
  }

  static TransactionPage page(Map<String, dynamic> json) {
    return TransactionPage(
      items: asMapList(json['items']).map(transaction).toList(growable: false),
      page: asInt(json['page'], 1),
      pageSize: asInt(json['page_size'], 20),
      total: asInt(json['total']),
      hasNext: asBool(json['has_next']),
    );
  }
}
