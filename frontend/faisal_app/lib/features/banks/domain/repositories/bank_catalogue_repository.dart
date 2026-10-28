import '../entities/bank_definition.dart';

abstract class BankCatalogueRepository {
  Future<BankCatalogue?> fetch({String? knownVersion});
}
