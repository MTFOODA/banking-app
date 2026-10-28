import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/card_entities.dart';
import '../../domain/repositories/cards_repository.dart';

class CardsState extends Equatable {
  const CardsState({
    this.overview,
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
    this.lastReference,
  });

  final CardsOverview? overview;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;
  final String? lastReference;

  CardsState copyWith({
    CardsOverview? overview,
    bool? loading,
    bool? busy,
    AppException? error,
    AppException? actionError,
    String? lastReference,
    bool clearErrors = false,
  }) {
    return CardsState(
      overview: overview ?? this.overview,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearErrors ? null : (error ?? this.error),
      actionError: clearErrors ? null : (actionError ?? this.actionError),
      lastReference: lastReference ?? this.lastReference,
    );
  }

  @override
  List<Object?> get props => [
    overview,
    loading,
    busy,
    error?.code,
    actionError?.code,
    lastReference,
  ];
}

class CardsCubit extends Cubit<CardsState> {
  CardsCubit(this._repository) : super(const CardsState());

  final CardsRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(loading: true, clearErrors: true));
    }
    try {
      emit(
        state.copyWith(
          overview: await _repository.fetchCards(),
          loading: false,
          clearErrors: true,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<bool> freeze(String cardId) =>
      _run(() => _repository.freezeCard(cardId));

  Future<bool> unfreeze(String cardId) =>
      _run(() => _repository.unfreezeCard(cardId));

  Future<bool> reportLost(String cardId, String reportType) =>
      _run(() => _repository.reportLost(cardId, reportType: reportType));

  Future<bool> block(String cardId) =>
      _run(() => _repository.blockCard(cardId));

  Future<bool> toggleControl(String cardId, String control, bool enabled) =>
      _run(() => _repository.toggleControl(cardId, control, enabled));

  void clearActionError() => emit(state.copyWith(clearErrors: true));

  Future<bool> _run(Future<BankCard> Function() action) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      await action();
      emit(
        state.copyWith(overview: await _repository.fetchCards(), busy: false),
      );
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          busy: false,
          actionError: const AppException(code: AppErrorCode.unknown),
        ),
      );
      return false;
    }
  }
}
