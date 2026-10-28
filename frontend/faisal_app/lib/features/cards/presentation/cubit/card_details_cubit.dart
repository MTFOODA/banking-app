import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/card_entities.dart';
import '../../domain/repositories/cards_repository.dart';

class CardDetailsState extends Equatable {
  const CardDetailsState({
    this.card,
    this.statements = const <CardStatement>[],
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
    this.lastReference,
  });

  final BankCard? card;
  final List<CardStatement> statements;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;
  final String? lastReference;

  CardDetailsState copyWith({
    BankCard? card,
    List<CardStatement>? statements,
    bool? loading,
    bool? busy,
    AppException? error,
    AppException? actionError,
    String? lastReference,
    bool clearErrors = false,
  }) {
    return CardDetailsState(
      card: card ?? this.card,
      statements: statements ?? this.statements,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearErrors ? null : (error ?? this.error),
      actionError: clearErrors ? null : (actionError ?? this.actionError),
      lastReference: lastReference ?? this.lastReference,
    );
  }

  @override
  List<Object?> get props => [
    card,
    statements,
    loading,
    busy,
    actionError?.code,
  ];
}

class CardDetailsCubit extends Cubit<CardDetailsState> {
  CardDetailsCubit(this._repository, this.cardId)
    : super(const CardDetailsState());

  final CardsRepository _repository;
  final String cardId;

  Future<void> load() async {
    emit(const CardDetailsState(loading: true));
    try {
      final card = await _repository.fetchCard(cardId);
      final statements = card.isCredit
          ? await _repository.fetchStatements(cardId)
          : const <CardStatement>[];
      emit(
        CardDetailsState(card: card, statements: statements, loading: false),
      );
    } on AppException catch (error) {
      emit(CardDetailsState(loading: false, error: error));
    }
  }

  Future<bool> freeze() => _run(() => _repository.freezeCard(cardId));

  Future<bool> unfreeze() => _run(() => _repository.unfreezeCard(cardId));

  Future<bool> reportLost(String reportType) =>
      _run(() => _repository.reportLost(cardId, reportType: reportType));

  Future<bool> block() => _run(() => _repository.blockCard(cardId));

  Future<bool> toggleControl(String control, bool enabled) =>
      _run(() => _repository.toggleControl(cardId, control, enabled));

  Future<String?> submitRequest(Future<String> Function() action) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final reference = await action();
      emit(
        state.copyWith(
          busy: false,
          lastReference: reference,
          card: await _repository.fetchCard(cardId),
        ),
      );
      return reference;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return null;
    }
  }

  void clearActionError() => emit(state.copyWith(clearErrors: true));

  Future<bool> _run(Future<BankCard> Function() action) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final card = await action();
      emit(state.copyWith(busy: false, card: card));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }
}
