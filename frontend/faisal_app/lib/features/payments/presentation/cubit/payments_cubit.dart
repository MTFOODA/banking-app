import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../transactions/domain/entities/transaction_entities.dart';
import '../../domain/entities/payment_entities.dart';
import '../../domain/repositories/payments_repository.dart';

class PaymentsState extends Equatable {
  const PaymentsState({
    this.billers = const <Biller>[],
    this.history = const <BankTransaction>[],
    this.loading = true,
    this.submitting = false,
    this.error,
    this.submitError,
    this.result,
  });

  final List<Biller> billers;
  final List<BankTransaction> history;
  final bool loading;
  final bool submitting;
  final AppException? error;
  final AppException? submitError;
  final PaymentResult? result;

  PaymentsState copyWith({
    List<Biller>? billers,
    List<BankTransaction>? history,
    bool? loading,
    bool? submitting,
    AppException? error,
    AppException? submitError,
    PaymentResult? result,
    bool clearSubmit = false,
    bool clearErrors = false,
  }) {
    return PaymentsState(
      billers: billers ?? this.billers,
      history: history ?? this.history,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: clearErrors ? null : (error ?? this.error),
      submitError: clearSubmit ? null : (submitError ?? this.submitError),
      result: clearSubmit ? null : (result ?? this.result),
    );
  }

  @override
  List<Object?> get props => [
    billers,
    history,
    loading,
    submitting,
    result,
    submitError?.code,
  ];
}

class PaymentsCubit extends Cubit<PaymentsState> {
  PaymentsCubit(this._repository) : super(const PaymentsState());

  final PaymentsRepository _repository;

  Future<void> load() async {
    emit(const PaymentsState(loading: true));
    try {
      final billers = await _repository.fetchBillers();
      final history = await _repository.fetchHistory();
      emit(
        PaymentsState(billers: billers, history: history.items, loading: false),
      );
    } on AppException catch (error) {
      emit(PaymentsState(loading: false, error: error));
    }
  }

  Future<bool> pay({
    required Biller biller,
    required double amount,
    required String fundingAccountId,
    String? note,
  }) async {
    final key = 'pay-${DateTime.now().microsecondsSinceEpoch}';
    emit(
      state.copyWith(submitting: true, clearSubmit: true, clearErrors: true),
    );
    try {
      final result = await _repository.payBill(
        billerCode: biller.code,
        amount: amount,
        fundingAccountId: fundingAccountId,
        note: note,
        idempotencyKey: key,
      );
      final history = await _repository.fetchHistory();
      emit(
        state.copyWith(
          submitting: false,
          result: result,
          history: history.items,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(submitting: false, submitError: error));
      return false;
    }
  }
}
