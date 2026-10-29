import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/bank_definition.dart';

/// A local navigation/appearance preference, never proof of bank ownership.
/// Authenticated screens always take their bank from the backend profile.
class BankSelectionCubit extends Cubit<String?> {
  BankSelectionCubit(this.preferences) : super(_read(preferences));
  final SharedPreferences? preferences;
  static const key = 'banking.selected_bank.v1';
  static const introductionKey = 'banking.introduction_seen.v1';
  static String? _read(SharedPreferences? preferences) {
    final code = preferences?.getString(key);
    return BankCatalogue.bundled.find(code) == null ? null : code;
  }

  bool _seen = false;
  bool get introductionSeen =>
      _seen || (preferences?.getBool(introductionKey) ?? false);
  Future<void> select(String code) async {
    if (BankCatalogue.bundled.find(code) == null) {
      throw ArgumentError('Unknown bank');
    }
    _seen = true;
    emit(code);
    try {
      await preferences?.setString(key, code);
      await preferences?.setBool(introductionKey, true);
    } catch (_) {
      /* In-memory selection remains usable. */
    }
  }
}
