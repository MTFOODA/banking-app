import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/card_entities.dart';

class CardMapper {
  const CardMapper._();

  static BankCard card(Map<String, dynamic> json) {
    final limitsJson = json['limits'];
    return BankCard(
      productCode: asString(json['product_code']),
      currency: asStringOrNull(json['currency']),
      id: asString(json['id']),
      last4: asString(json['card_last4']),
      kind: asString(json['card_kind'], 'debit'),
      network: asStringOrNull(json['network']),
      status: asString(json['status'], 'active'),
      cardholderName: asString(json['cardholder_name']),
      expiryMonth: asInt(json['expiry_month'], 1),
      expiryYear: asInt(json['expiry_year'], DateTime.now().year),
      isPrimary: asBool(json['is_primary'], true),
      isSupplementary: asBool(json['is_supplementary']),
      accountId: asStringOrNull(json['account_id']),
      accountNumberMasked: asStringOrNull(json['account_number_masked']),
      availableBalance: json['available_balance'] == null
          ? null
          : asDouble(json['available_balance']),
      productNameEn: asString(json['product_name_en']),
      productNameAr: asString(json['product_name_ar']),
      creditLimit: json['credit_limit'] == null
          ? null
          : asDouble(json['credit_limit']),
      availableCredit: json['available_credit'] == null
          ? null
          : asDouble(json['available_credit']),
      outstandingBalance: json['outstanding_balance'] == null
          ? null
          : asDouble(json['outstanding_balance']),
      statementBalance: json['statement_balance'] == null
          ? null
          : asDouble(json['statement_balance']),
      minimumPayment: json['minimum_payment'] == null
          ? null
          : asDouble(json['minimum_payment']),
      paymentDueDate: asDateOrNull(json['payment_due_date']),
      issuedAt: asDate(json['issued_at']),
      limits: limitsJson is Map<String, dynamic> ? limits(limitsJson) : null,
    );
  }

  static CardLimits limits(Map<String, dynamic> json) {
    return CardLimits(
      dailyPurchaseLimit: asDouble(json['daily_purchase_limit']),
      dailyAtmLimit: asDouble(json['daily_atm_limit']),
      monthlyLimit: asDouble(json['monthly_limit']),
      onlineEnabled: asBool(json['online_enabled'], true),
      internationalEnabled: asBool(json['international_enabled']),
      contactlessEnabled: asBool(json['contactless_enabled'], true),
    );
  }

  static CardsOverview overview(Map<String, dynamic> json) {
    return CardsOverview(
      cards: asMapList(json['cards']).map(card).toList(growable: false),
      activeCount: asInt(json['active_count']),
      frozenCount: asInt(json['frozen_count']),
      creditOutstandingTotal: asDouble(json['credit_outstanding_total']),
    );
  }

  static CardStatement statement(Map<String, dynamic> json) {
    return CardStatement(
      id: asString(json['id']),
      periodStart: asDate(json['period_start']),
      periodEnd: asDate(json['period_end']),
      statementBalance: asDouble(json['statement_balance']),
      minimumPayment: asDouble(json['minimum_payment']),
      dueDate: asDate(json['due_date']),
      status: asString(json['status'], 'open'),
    );
  }
}
