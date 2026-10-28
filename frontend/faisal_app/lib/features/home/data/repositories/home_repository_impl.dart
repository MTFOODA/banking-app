import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../accounts/domain/repositories/accounts_repository.dart';
import '../../../cards/domain/repositories/cards_repository.dart';
import '../../../transactions/domain/entities/transaction_entities.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required this._accounts,
    required this._cards,
    required this._transactions,
    required this._client,
  });

  final AccountsRepository _accounts;
  final CardsRepository _cards;
  final TransactionsRepository _transactions;
  final DioClient _client;

  @override
  Future<HomeOverview> load() async {
    final accounts = await _accounts.fetchOverview();
    final cards = await _cards.fetchCards();
    final transactions = await _transactions.fetchTransactions(
      filter: const TransactionFilter(),
      page: 1,
      pageSize: 5,
    );
    final banners = await _banners();
    return HomeOverview(
      accounts: accounts,
      cards: cards,
      recentTransactions: transactions.items,
      banners: banners,
    );
  }

  Future<List<FeaturedBanner>> _banners() async {
    try {
      final data = await _client.get('/banners');
      if (data is List) {
        return data
            .map((item) {
              final json = asMap(item);
              return FeaturedBanner(
                id: asString(json['id']),
                titleEn: asString(json['title_en']),
                titleAr: asString(json['title_ar']),
                bodyEn: asString(json['body_en']),
                bodyAr: asString(json['body_ar']),
                category: asString(json['category'], 'announcement'),
                imageUrl: asStringOrNull(json['image_url']),
                ctaLabelEn: asStringOrNull(json['cta_label_en']),
                ctaLabelAr: asStringOrNull(json['cta_label_ar']),
                ctaRoute: asStringOrNull(json['cta_route']),
              );
            })
            .toList(growable: false);
      }
    } catch (_) {
      // Banners are non-critical: the dashboard still renders without them.
    }
    return const <FeaturedBanner>[];
  }
}
