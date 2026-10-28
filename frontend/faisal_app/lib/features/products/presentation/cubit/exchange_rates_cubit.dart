import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/investment_entities.dart';
import '../../domain/repositories/investment_repository.dart';

class ExchangeRatesState {
  const ExchangeRatesState({this.rates, this.loading = false, this.error});
  final ExchangeRates? rates;
  final bool loading;
  final AppException? error;
}

class ExchangeRatesCubit extends Cubit<ExchangeRatesState> {
  ExchangeRatesCubit(this._repository) : super(const ExchangeRatesState());
  final InvestmentRepository _repository;
  Timer? _timer;
  void start() {
    _timer?.cancel();
    load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => load());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> load() async {
    if (state.loading || isClosed) return;
    emit(ExchangeRatesState(rates: state.rates, loading: true));
    try {
      final result = await _repository.exchangeRates();
      if (!isClosed) emit(ExchangeRatesState(rates: result));
    } on AppException catch (e) {
      if (!isClosed) emit(ExchangeRatesState(rates: state.rates, error: e));
    }
  }

  @override
  Future<void> close() {
    pause();
    return super.close();
  }
}
