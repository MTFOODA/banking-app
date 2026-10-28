import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/repayment_entities.dart';
import '../../domain/repositories/repayments_repository.dart';

class RepaymentsState extends Equatable {
  const RepaymentsState({
    this.quote,
    this.quoting = false,
    this.submitting = false,
    this.error,
    this.submitError,
    this.record,
    this.history = const <RepaymentRecord>[],
    this.historyLoading = false,
  });

  final RepaymentQuote? quote;
  final bool quoting;
  final bool submitting;
  final AppException? error;
  final AppException? submitError;
  final RepaymentRecord? record;
  final List<RepaymentRecord> history;
  final bool historyLoading;

  RepaymentsState copyWith({
    RepaymentQuote? quote,
    bool? quoting,
    bool? submitting,
    AppException? error,
    AppException? submitError,
    RepaymentRecord? record,
    List<RepaymentRecord>? history,
    bool? historyLoading,
    bool clearSubmit = false,
    bool clearErrors = false,
  }) {
    return RepaymentsState(
      quote: clearSubmit ? null : (quote ?? this.quote),
      quoting: quoting ?? this.quoting,
      submitting: submitting ?? this.submitting,
      error: clearErrors ? null : (error ?? this.error),
      submitError: clearSubmit ? null : (submitError ?? this.submitError),
      record: clearSubmit ? null : (record ?? this.record),
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
    );
  }

  @override
  List<Object?> get props => [
    quote,
    quoting,
    submitting,
    error?.code,
    submitError?.code,
    record,
    history.length,
  ];
}

class RepaymentsCubit extends Cubit<RepaymentsState> {
  RepaymentsCubit(this._repository) : super(const RepaymentsState());

  final RepaymentsRepository _repository;

  Future<void> loadQuote({
    required String cardId,
    required String fundingAccountId,
    required String mode,
    double? amount,
  }) async {
    emit(state.copyWith(quoting: true, clearErrors: true));
    try {
      emit(
        state.copyWith(
          quote: await _repository.quote(
            cardId: cardId,
            fundingAccountId: fundingAccountId,
            mode: mode,
            amount: amount,
          ),
          quoting: false,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(quoting: false, error: error));
    }
  }

  Future<bool> submit({
    required String cardId,
    required String fundingAccountId,
    required String mode,
    double? amount,
  }) async {
    final key = 'rep-${DateTime.now().microsecondsSinceEpoch}';
    emit(
      state.copyWith(submitting: true, clearSubmit: true, clearErrors: true),
    );
    try {
      final record = await _repository.createRepayment(
        cardId: cardId,
        fundingAccountId: fundingAccountId,
        mode: mode,
        amount: amount,
        idempotencyKey: key,
      );
      emit(state.copyWith(submitting: false, record: record));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(submitting: false, submitError: error));
      return false;
    }
  }

  Future<void> loadHistory() async {
    emit(state.copyWith(historyLoading: true, clearErrors: true));
    try {
      final page = await _repository.fetchRepayments();
      emit(state.copyWith(history: page.items, historyLoading: false));
    } on AppException catch (error) {
      emit(state.copyWith(historyLoading: false, error: error));
    }
  }
}
