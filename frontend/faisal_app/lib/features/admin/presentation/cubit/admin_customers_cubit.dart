import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminCustomersState extends Equatable {
  const AdminCustomersState({
    this.items = const <AdminCustomer>[],
    this.loading = true,
    this.search,
    this.error,
  });

  final List<AdminCustomer> items;
  final bool loading;
  final String? search;
  final AppException? error;

  AdminCustomersState copyWith({
    List<AdminCustomer>? items,
    bool? loading,
    String? search,
    AppException? error,
    bool clearError = false,
  }) {
    return AdminCustomersState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      search: search ?? this.search,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [items, loading, search, error?.code];
}

class AdminCustomersCubit extends Cubit<AdminCustomersState> {
  AdminCustomersCubit(this._repository) : super(const AdminCustomersState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final page = await _repository.fetchCustomers(search: state.search);
      emit(state.copyWith(items: page.items, loading: false));
    } on AppException catch (error) {
      emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<void> search(String? query) async {
    emit(state.copyWith(search: query));
    await load();
  }
}

class AdminCustomerDetailsState extends Equatable {
  const AdminCustomerDetailsState({
    this.customer,
    this.loading = true,
    this.error,
  });

  final AdminCustomer? customer;
  final bool loading;
  final AppException? error;

  @override
  List<Object?> get props => [customer, loading, error?.code];
}

class AdminCustomerDetailsCubit extends Cubit<AdminCustomerDetailsState> {
  AdminCustomerDetailsCubit(this._repository, this.customerId)
    : super(const AdminCustomerDetailsState());

  final AdminRepository _repository;
  final String customerId;

  Future<void> load() async {
    emit(const AdminCustomerDetailsState(loading: true));
    try {
      emit(
        AdminCustomerDetailsState(
          customer: await _repository.fetchCustomer(customerId),
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(AdminCustomerDetailsState(loading: false, error: error));
    }
  }
}
