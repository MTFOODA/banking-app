import '../entities/bank_directory.dart';
import '../entities/bank_branch.dart';

abstract class BankDirectoryRepository {
  Future<List<BankBranch>> loadBranches();
  Future<BankDirectory> loadDirectory(
    String bankCode, {
    bool refresh = false,
  }) async {
    return BankDirectory(
      bankCode: bankCode,
      branches: bankCode == 'faisal' ? await loadBranches() : const [],
      branchesStatus: bankCode == 'faisal' ? 'published' : 'unavailable',
    );
  }
}
