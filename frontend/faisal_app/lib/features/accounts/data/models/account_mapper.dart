import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/account_entities.dart';

class AccountMapper {
  const AccountMapper._();

  static Account account(Map<String, dynamic> json) {
    return Account(
      id: asString(json['id']),
      accountType: asString(json['account_type'], 'current'),
      accountNumberMasked: asString(json['account_number_masked']),
      iban: asStringOrNull(json['iban']),
      currency: asString(json['currency'], 'EGP'),
      status: asString(json['status'], 'active'),
      currentBalance: asDouble(json['current_balance']),
      availableBalance: asDouble(json['available_balance']),
      blockedBalance: asDouble(json['blocked_balance']),
      productNameEn: asString(json['product_name_en']),
      productNameAr: asString(json['product_name_ar']),
      openedAt: asDate(json['opened_at']),
      linkedCards: asMapList(json['linked_cards'])
          .map(linkedCard)
          .toList(growable: false),
      services: asStringList(json['services']),
    );
  }

  static LinkedCard linkedCard(Map<String, dynamic> json) {
    return LinkedCard(
      id: asString(json['id']),
      last4: asString(json['card_last4']),
      kind: asString(json['card_kind'], 'debit'),
      status: asString(json['status']),
      network: asStringOrNull(json['network']),
    );
  }

  static AccountsOverview overview(Map<String, dynamic> json) {
    final totalsJson = asMap(json['totals']);
    return AccountsOverview(
      totals: AccountTotals(
        totalAvailable: asDouble(totalsJson['total_available']),
        totalCurrent: asDouble(totalsJson['total_current']),
        currency: asString(totalsJson['currency'], 'EGP'),
        eligibleAccounts: asInt(totalsJson['eligible_accounts']),
      ),
      accounts: asMapList(json['accounts'])
          .map(account)
          .toList(growable: false),
    );
  }

  static AccountProduct product(Map<String, dynamic> json) {
    return AccountProduct(
      id: asString(json['id']),
      code: asString(json['code']),
      nameEn: asString(json['name_en']),
      nameAr: asString(json['name_ar']),
      accountType: asString(json['account_type'], 'current'),
      currency: asString(json['currency'], 'EGP'),
      descriptionEn: asString(json['description_en']),
      descriptionAr: asString(json['description_ar']),
      minimumBalance: asDouble(json['minimum_balance']),
      isActive: asBool(json['is_active'], true),
    );
  }
}
