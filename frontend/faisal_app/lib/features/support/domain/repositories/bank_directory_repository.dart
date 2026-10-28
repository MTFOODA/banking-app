import '../entities/bank_branch.dart';

abstract class BankDirectoryRepository {
  Future<List<BankBranch>> loadBranches();
}
