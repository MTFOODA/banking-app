import '../entities/auth_entities.dart';
import '../entities/saved_bank.dart';

abstract class SavedBanksRepository {
  List<SavedBank> get entries;
  Stream<List<SavedBank>> get changes;
  SavedBank? get pendingLogin;
  set pendingLogin(SavedBank? value);
  Future<void> remember(SessionUser user, String refreshToken);
  Future<String?> credential(SavedBank entry);
  Future<void> invalidate(String userId);
}
