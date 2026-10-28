import 'package:equatable/equatable.dart';

import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../accounts/domain/entities/account_entities.dart';
import '../../../accounts/domain/repositories/accounts_repository.dart';
import '../../domain/entities/transfer_entities.dart';
import '../../domain/repositories/transfers_repository.dart';

class TransfersState extends Equatable {
  const TransfersState({
    this.beneficiaries = const <Beneficiary>[],
    this.loading = true,
    this.submitting = false,
    this.error,
    this.submitError,
    this.result,
    this.idempotencyKey,
    this.beneficiarySaved = false,
    this.accounts = const [],
    this.quote,
    this.draft,
    this.options = const [],
  });

  final List<Beneficiary> beneficiaries;
  final bool loading;
  final bool submitting;
  final AppException? error;
  final AppException? submitError;
  final TransferResult? result;
  final String? idempotencyKey;
  final bool beneficiarySaved;
  final List<Account> accounts;
  final Map<String, dynamic>? quote;
  final Map<String, dynamic>? draft;
  final List<Map<String, dynamic>> options;

  TransfersState copyWith({
    List<Beneficiary>? beneficiaries,
    bool? loading,
    bool? submitting,
    AppException? error,
    AppException? submitError,
    TransferResult? result,
    String? idempotencyKey,
    bool? beneficiarySaved,
    bool clearSubmitState = false,
    bool clearErrors = false,
    List<Account>? accounts,
    Map<String, dynamic>? quote,
    Map<String, dynamic>? draft,
    bool clearReview = false,
    List<Map<String, dynamic>>? options,
  }) {
    return TransfersState(
      options: options ?? this.options,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      accounts: accounts ?? this.accounts,
      quote: clearReview ? null : quote ?? this.quote,
      draft: clearReview ? null : draft ?? this.draft,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      error: clearErrors ? null : (error ?? this.error),
      submitError: clearSubmitState || clearErrors
          ? null
          : (submitError ?? this.submitError),
      result: clearSubmitState ? null : (result ?? this.result),
      idempotencyKey: clearReview
          ? null
          : idempotencyKey ?? this.idempotencyKey,
      beneficiarySaved: clearSubmitState
          ? false
          : (beneficiarySaved ?? this.beneficiarySaved),
    );
  }

  @override
  List<Object?> get props => [
    options,
    beneficiaries,
    accounts,
    quote,
    draft,
    loading,
    submitting,
    error,
    submitError,
    result,
  ];
}

class TransfersCubit extends Cubit<TransfersState> {
  TransfersCubit(this._repository, this._accounts)
    : super(const TransfersState());

  final TransfersRepository _repository;
  final AccountsRepository _accounts;

  Future<void> load() async {
    if (isClosed || state.submitting) return;
    emit(state.copyWith(loading: true, clearErrors: true));
    try {
      final values = await Future.wait<Object>([
        _repository.fetchBeneficiaries(),
        _accounts.fetchOverview(),
        _repository.fetchTransferOptions(),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          beneficiaries: values[0] as List<Beneficiary>,
          accounts: (values[1] as AccountsOverview).accounts
              .where((a) => a.isActive)
              .toList(),
          loading: false,
          options: values[2] as List<Map<String, dynamic>>,
        ),
      );
    } on AppException catch (error) {
      if (!isClosed) emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<bool> addBeneficiary({
    required String name,
    required String bankName,
    required String accountNumber,
    String? nickname,
    String currency = 'EGP',
  }) async {
    emit(state.copyWith(submitting: true, clearErrors: true));
    try {
      final beneficiary = await _repository.addBeneficiary(
        name: name,
        bankName: bankName,
        accountNumber: accountNumber,
        nickname: nickname,
        currency: currency,
      );
      emit(
        state.copyWith(
          beneficiaries: [...state.beneficiaries, beneficiary],
          submitting: false,
          beneficiarySaved: true,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(submitting: false, submitError: error));
      return false;
    }
  }

  Future<bool> deleteBeneficiary(String id) async {
    try {
      await _repository.deleteBeneficiary(id);
      emit(
        state.copyWith(
          beneficiaries: state.beneficiaries
              .where((item) => item.id != id)
              .toList(),
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(submitError: error));
      return false;
    }
  }

  void resetSubmission() {
    emit(
      state.copyWith(
        clearSubmitState: true,
        clearErrors: true,
        clearReview: true,
      ),
    );
  }

  Future<void> review(Map<String, dynamic> draft) async {
    if (state.submitting) return;
    emit(
      state.copyWith(
        submitting: true,
        clearErrors: true,
        clearSubmitState: true,
        clearReview: true,
      ),
    );
    try {
      final quote = await _repository.quoteTransfer(draft);
      final key = List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      if (!isClosed) {
        emit(
          state.copyWith(
            quote: quote,
            draft: Map.unmodifiable({
              ...draft,
              if (quote['fx_quote_id'] != null)
                'fx_quote_id': quote['fx_quote_id'],
            }),
            idempotencyKey: key,
            submitting: false,
          ),
        );
      }
    } on AppException catch (e) {
      if (!isClosed) emit(state.copyWith(submitting: false, submitError: e));
    }
  }

  Future<bool> submitReviewed(String token) async {
    final d = state.draft;
    if (d == null || state.submitting) return false;
    return submit(
      sourceAccountId: d['source_account_id'] as String,
      amount: double.parse(d['amount'].toString()),
      currency: d['currency'] as String,
      destinationAccountId: d['destination_account_id'] as String?,
      beneficiaryId: d['beneficiary_id'] as String?,
      purpose: d['purpose'] as String?,
      note: d['note'] as String?,
      authorizationToken: token,
      transferType: d['transfer_type'] as String?,
      recipient: d['recipient'] as Map<String, dynamic>?,
      fxQuoteId: d['fx_quote_id'] as String?,
    );
  }

  Future<bool> submit({
    required String sourceAccountId,
    required double amount,
    required String currency,
    String? destinationAccountId,
    String? beneficiaryId,
    String? purpose,
    String? note,
    String? authorizationToken,
    String? transferType,
    Map<String, dynamic>? recipient,
    String? fxQuoteId,
  }) async {
    if (isClosed || state.submitting) return false;
    final key =
        state.idempotencyKey ??
        'trf-${DateTime.now().microsecondsSinceEpoch}-${amount.toStringAsFixed(2)}';
    emit(
      state.copyWith(submitting: true, clearErrors: true, idempotencyKey: key),
    );
    try {
      final result = await _repository.createTransfer(
        sourceAccountId: sourceAccountId,
        amount: amount,
        currency: currency,
        destinationAccountId: destinationAccountId,
        beneficiaryId: beneficiaryId,
        purpose: purpose,
        note: note,
        idempotencyKey: key,
        authorizationToken: authorizationToken,
        transferType: transferType,
        recipient: recipient,
        fxQuoteId: fxQuoteId,
      );
      if (isClosed) return true;
      emit(
        state.copyWith(submitting: false, result: result, idempotencyKey: null),
      );
      return true;
    } on AppException catch (error) {
      if (!isClosed) {
        emit(state.copyWith(submitting: false, submitError: error));
      }
      return false;
    }
  }
}
