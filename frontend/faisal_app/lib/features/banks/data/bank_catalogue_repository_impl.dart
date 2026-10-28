import '../../../core/network/dio_client.dart';
import '../domain/entities/bank_definition.dart';
import '../domain/repositories/bank_catalogue_repository.dart';

class BankCatalogueRepositoryImpl implements BankCatalogueRepository {
  BankCatalogueRepositoryImpl(this.client);
  final DioClient client;
  @override
  Future<BankCatalogue?> fetch({String? knownVersion}) async {
    final raw = Map<String, dynamic>.from(
      await client.get('/banks', query: {'known_version': knownVersion}) as Map,
    );
    return raw['unchanged'] == true ? null : BankCatalogue.fromJson(raw);
  }
}
