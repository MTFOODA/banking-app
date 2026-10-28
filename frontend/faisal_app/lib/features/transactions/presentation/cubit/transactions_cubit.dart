import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/transaction_entities.dart';
import '../../domain/repositories/transactions_repository.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    this.filter = const TransactionFilter(),
    this.items = const <BankTransaction>[],
    this.loading = true,
    this.loadingMore = false,
    this.page = 1,
    this.total = 0,
    this.hasNext = false,
    this.error,
  });

  final TransactionFilter filter;
  final List<BankTransaction> items;
  final bool loading;
  final bool loadingMore;
  final int page;
  final int total;
  final bool hasNext;
  final AppException? error;

  bool get isEmpty => !loading && items.isEmpty && error == null;

  TransactionsState copyWith({
    TransactionFilter? filter,
    List<BankTransaction>? items,
    bool? loading,
    bool? loadingMore,
    int? page,
    int? total,
    bool? hasNext,
    AppException? error,
    bool clearError = false,
  }) {
    return TransactionsState(
      filter: filter ?? this.filter,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      page: page ?? this.page,
      total: total ?? this.total,
      hasNext: hasNext ?? this.hasNext,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    filter,
    items,
    loading,
    loadingMore,
    page,
    total,
    hasNext,
    error?.code,
  ];
}

class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit(
    this._repository, {
    this.scope = TransactionScope.all,
    this.scopeId,
    TransactionFilter filter = const TransactionFilter(),
    this.pageSize = 20,
  }) : super(TransactionsState(filter: filter));

  final TransactionsRepository _repository;
  final TransactionScope scope;
  final String? scopeId;
  final int pageSize;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final result = await _fetch(1);
      emit(
        state.copyWith(
          items: result.items,
          page: result.page,
          total: result.total,
          hasNext: result.hasNext,
          loading: false,
          loadingMore: false,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(loading: false, error: error));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          error: const AppException(code: AppErrorCode.unknown),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasNext || state.loadingMore || state.loading) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _fetch(state.page + 1);
      emit(
        state.copyWith(
          items: [...state.items, ...result.items],
          page: result.page,
          total: result.total,
          hasNext: result.hasNext,
          loadingMore: false,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(loadingMore: false, error: error));
    }
  }

  Future<void> applyFilter(TransactionFilter filter) async {
    emit(state.copyWith(filter: filter));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(filter: const TransactionFilter()));
    await load();
  }

  Future<TransactionPage> _fetch(int page) {
    final filter = state.filter;
    return switch (scope) {
      TransactionScope.account => _repository.fetchAccountTransactions(
        scopeId!,
        filter: filter,
        page: page,
        pageSize: pageSize,
      ),
      TransactionScope.card => _repository.fetchCardTransactions(
        scopeId!,
        filter: filter,
        page: page,
        pageSize: pageSize,
      ),
      TransactionScope.all => _repository.fetchTransactions(
        filter: filter,
        page: page,
        pageSize: pageSize,
      ),
    };
  }
}
