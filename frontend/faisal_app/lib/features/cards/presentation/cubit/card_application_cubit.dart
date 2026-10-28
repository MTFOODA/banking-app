import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../requests/domain/entities/request_entities.dart';
import '../../../requests/domain/repositories/requests_repository.dart';
import '../../domain/entities/card_product.dart';
import '../../domain/repositories/cards_repository.dart';

class CardApplicationState {
  const CardApplicationState({
    this.products = const [],
    this.requests = const [],
    this.loading = false,
    this.busy = false,
    this.error,
    this.receipt,
    this.hasNext = false,
    this.page = 1,
  });
  final List<CardProduct> products;
  final List<ServiceRequestEntity> requests;
  final bool loading, busy, hasNext;
  final int page;
  final AppException? error;
  final ServiceRequestEntity? receipt;
  bool get hasOpen => requests.any((r) => r.isOpen);
}

class CardApplicationCubit extends Cubit<CardApplicationState> {
  CardApplicationCubit(this._cards, this._requests)
    : super(const CardApplicationState());
  final CardsRepository _cards;
  final RequestsRepository _requests;
  Future<void> load() async {
    if (isClosed || state.busy) return;
    emit(
      CardApplicationState(
        loading: true,
        products: state.products,
        requests: state.requests,
      ),
    );
    try {
      final result = await Future.wait<Object>([
        _cards.fetchProducts(),
        _requests.fetchRequests(type: 'card_issue'),
      ]);
      if (isClosed) return;
      final page = result[1] as RequestPage;
      emit(
        CardApplicationState(
          products: result[0] as List<CardProduct>,
          requests: page.items,
          hasNext: page.hasNext,
        ),
      );
    } on AppException catch (e) {
      if (!isClosed) {
        emit(
          CardApplicationState(
            products: state.products,
            requests: state.requests,
            error: e,
          ),
        );
      }
    }
  }

  Future<void> more() async {
    if (state.busy || !state.hasNext || isClosed) return;
    final before = state;
    emit(
      CardApplicationState(
        products: before.products,
        requests: before.requests,
        busy: true,
        hasNext: true,
        page: before.page,
      ),
    );
    try {
      final next = await _requests.fetchRequests(
        type: 'card_issue',
        page: before.page + 1,
      );
      if (!isClosed) {
        emit(
          CardApplicationState(
            products: before.products,
            requests: [...before.requests, ...next.items],
            hasNext: next.hasNext,
            page: next.page,
          ),
        );
      }
    } on AppException catch (e) {
      if (!isClosed) {
        emit(
          CardApplicationState(
            products: before.products,
            requests: before.requests,
            error: e,
            hasNext: true,
            page: before.page,
          ),
        );
      }
    }
  }

  Future<bool> submit(CardProduct product, String accountId) async {
    if (isClosed ||
        state.busy ||
        state.hasOpen ||
        !product.eligible ||
        !product.accounts.any((a) => a.id == accountId)) {
      return false;
    }
    final before = state;
    emit(
      CardApplicationState(
        products: before.products,
        requests: before.requests,
        busy: true,
      ),
    );
    try {
      final receipt = await _requests.createRequest(
        requestType: 'card_issue',
        formData: {'card_product_code': product.code, 'account_id': accountId},
      );
      if (isClosed) return true;
      emit(
        CardApplicationState(
          products: before.products,
          requests: [receipt, ...before.requests],
          receipt: receipt,
          hasNext: before.hasNext,
          page: before.page,
        ),
      );
      return true;
    } on AppException catch (e) {
      if (!isClosed) {
        emit(
          CardApplicationState(
            products: before.products,
            requests: before.requests,
            error: e,
            hasNext: before.hasNext,
            page: before.page,
          ),
        );
      }
      return false;
    }
  }
}
