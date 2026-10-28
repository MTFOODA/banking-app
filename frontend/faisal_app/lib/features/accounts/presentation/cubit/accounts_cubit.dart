import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/account_entities.dart';
import '../../domain/repositories/accounts_repository.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => const [];
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountsLoaded extends AccountsState {
  const AccountsLoaded(this.overview);

  final AccountsOverview overview;

  @override
  List<Object?> get props => [overview];
}

class AccountsFailure extends AccountsState {
  const AccountsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error.code, error.statusCode];
}

class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repository) : super(const AccountsLoading());

  final AccountsRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    if (!silent) {
      emit(const AccountsLoading());
    }
    try {
      final overview = await _repository.fetchOverview();
      if (!isClosed) emit(AccountsLoaded(overview));
    } on AppException catch (error) {
      if (!isClosed) emit(AccountsFailure(error));
    } catch (_) {
      if (!isClosed) {
        emit(const AccountsFailure(AppException(code: AppErrorCode.unknown)));
      }
    }
  }
}

sealed class AccountDetailsState extends Equatable {
  const AccountDetailsState();

  @override
  List<Object?> get props => const [];
}

class AccountDetailsLoading extends AccountDetailsState {
  const AccountDetailsLoading();
}

class AccountDetailsLoaded extends AccountDetailsState {
  const AccountDetailsLoaded(this.account);

  final Account account;

  @override
  List<Object?> get props => [account];
}

class AccountDetailsFailure extends AccountDetailsState {
  const AccountDetailsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error.code, error.statusCode];
}

class AccountDetailsCubit extends Cubit<AccountDetailsState> {
  AccountDetailsCubit(this._repository, this.accountId)
    : super(const AccountDetailsLoading());

  final AccountsRepository _repository;
  final String accountId;

  Future<void> load() async {
    emit(const AccountDetailsLoading());
    try {
      emit(AccountDetailsLoaded(await _repository.fetchAccount(accountId)));
    } on AppException catch (error) {
      emit(AccountDetailsFailure(error));
    } catch (_) {
      emit(
        const AccountDetailsFailure(AppException(code: AppErrorCode.unknown)),
      );
    }
  }
}

sealed class AccountRequestState extends Equatable {
  const AccountRequestState();

  @override
  List<Object?> get props => const [];
}

class AccountRequestInitial extends AccountRequestState {
  const AccountRequestInitial();
}

class AccountRequestProductsLoaded extends AccountRequestState {
  const AccountRequestProductsLoaded(this.products);

  final List<AccountProduct> products;

  @override
  List<Object?> get props => [products];
}

class AccountRequestSubmitting extends AccountRequestState {
  const AccountRequestSubmitting();
}

class AccountRequestSubmitted extends AccountRequestState {
  const AccountRequestSubmitted(this.reference);

  final String reference;

  @override
  List<Object?> get props => [reference];
}

class AccountRequestFailure extends AccountRequestState {
  const AccountRequestFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error.code, error.statusCode];
}

class AccountRequestCubit extends Cubit<AccountRequestState> {
  AccountRequestCubit(this._repository) : super(const AccountRequestInitial());

  final AccountsRepository _repository;

  Future<void> loadProducts() async {
    try {
      emit(AccountRequestProductsLoaded(await _repository.fetchProducts()));
    } on AppException catch (error) {
      emit(AccountRequestFailure(error));
    }
  }

  Future<void> submitOpen({required String productCode, String? reason}) async {
    emit(const AccountRequestSubmitting());
    try {
      final reference = await _repository.requestAccountChange(
        requestType: 'account_open',
        productCode: productCode,
        reason: reason,
      );
      emit(AccountRequestSubmitted(reference));
    } on AppException catch (error) {
      emit(AccountRequestFailure(error));
    }
  }

  Future<void> submitClose({required String accountId, String? reason}) async {
    emit(const AccountRequestSubmitting());
    try {
      final reference = await _repository.requestAccountChange(
        requestType: 'account_close',
        accountId: accountId,
        reason: reason,
      );
      emit(AccountRequestSubmitted(reference));
    } on AppException catch (error) {
      emit(AccountRequestFailure(error));
    }
  }
}
