import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../accounts/domain/entities/account_entities.dart';
import '../../../accounts/domain/repositories/accounts_repository.dart';
import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

class InvestmentsState {
  const InvestmentsState({
    this.products = const [],
    this.holdings = const [],
    this.accounts = const [],
    this.busy = false,
    this.error,
    this.quote,
    this.receipt,
  });
  final List<InvestmentRecord> products, holdings;
  final List<Account> accounts;
  final bool busy;
  final AppException? error;
  final InvestmentRecord? quote, receipt;
}

class InvestmentsCubit extends Cubit<InvestmentsState> {
  InvestmentsCubit(this._repository, this._accounts, {this.productType})
    : super(const InvestmentsState());
  final InvestmentRepository _repository;
  final AccountsRepository _accounts;
  final String? productType;
  Map<String, dynamic>? _draft;
  String? _retryKey;
  Map<String, dynamic>? get draft => _draft;
  InvestmentsState _state({
    bool busy = false,
    AppException? error,
    InvestmentRecord? quote,
    InvestmentRecord? receipt,
  }) => InvestmentsState(
    products: state.products,
    holdings: state.holdings,
    accounts: state.accounts,
    busy: busy,
    error: error,
    quote: quote,
    receipt: receipt,
  );

  Future<void> load() async {
    emit(_state(busy: true));
    try {
      final products = await _repository.products();
      final holdings = await _repository.holdings();
      final accounts = await _accounts.fetchOverview();
      if (isClosed) return;
      emit(
        InvestmentsState(
          products: products
              .where(
                (p) =>
                    productType == null ||
                    p.text('product_type') == productType,
              )
              .toList(),
          holdings: holdings
              .where(
                (h) =>
                    productType == null ||
                    h.text('product_type') == productType,
              )
              .toList(),
          accounts: accounts.accounts
              .where((a) => a.isActive && a.currency == 'EGP')
              .toList(),
        ),
      );
    } on AppException catch (e) {
      if (!isClosed) emit(_state(error: e));
    }
  }

  Future<void> review(Map<String, dynamic> action) async {
    if (state.busy) return;
    emit(_state(busy: true));
    try {
      final quote = await _repository.quote(action);
      if (isClosed) return;
      _draft = Map.unmodifiable(action);
      _retryKey = List.generate(
        16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      emit(_state(quote: quote));
    } on AppException catch (e) {
      if (!isClosed) emit(_state(error: e));
    }
  }

  Future<void> submit(String token) async {
    final quote = state.quote;
    if (state.busy || quote == null || _draft == null) return;
    emit(_state(busy: true, quote: quote));
    try {
      final receipt = await _repository.execute(_draft!, token, _retryKey!);
      if (!isClosed) emit(_state(receipt: receipt));
    } on AppException catch (e) {
      // Keep the reviewed action and retry key after uncertain network outcomes.
      if (!isClosed) emit(_state(quote: quote, error: e));
    }
  }

  void edit() {
    _draft = null;
    _retryKey = null;
    emit(_state());
  }
}
