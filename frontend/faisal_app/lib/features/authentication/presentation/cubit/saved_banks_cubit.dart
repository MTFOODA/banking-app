import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/saved_bank.dart';
import '../../domain/repositories/saved_banks_repository.dart';

class SavedBanksCubit extends Cubit<List<SavedBank>> {
  SavedBanksCubit(this.repository) : super(repository.entries) {
    _subscription = repository.changes.listen((entries) {
      if (!isClosed) emit(entries);
    });
  }
  final SavedBanksRepository repository;
  late final StreamSubscription<List<SavedBank>> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
