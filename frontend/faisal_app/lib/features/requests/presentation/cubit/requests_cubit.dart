import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/request_entities.dart';
import '../../domain/repositories/requests_repository.dart';

class RequestsState extends Equatable {
  const RequestsState({
    this.items = const <ServiceRequestEntity>[],
    this.loading = true,
    this.page = 1,
    this.total = 0,
    this.hasNext = false,
    this.statusFilter,
    this.error,
  });

  final List<ServiceRequestEntity> items;
  final bool loading;
  final int page;
  final int total;
  final bool hasNext;
  final String? statusFilter;
  final AppException? error;

  bool get isEmpty => !loading && items.isEmpty && error == null;

  RequestsState copyWith({
    List<ServiceRequestEntity>? items,
    bool? loading,
    int? page,
    int? total,
    bool? hasNext,
    String? statusFilter,
    bool clearStatus = false,
    AppException? error,
    bool clearError = false,
  }) {
    return RequestsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      total: total ?? this.total,
      hasNext: hasNext ?? this.hasNext,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    items,
    loading,
    page,
    total,
    hasNext,
    statusFilter,
    error?.code,
  ];
}

class RequestsCubit extends Cubit<RequestsState> {
  RequestsCubit(this._repository) : super(const RequestsState());

  final RequestsRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(loading: true, clearError: true));
    }
    try {
      final page = await _repository.fetchRequests(
        page: 1,
        status: state.statusFilter,
      );
      emit(
        state.copyWith(
          items: page.items,
          page: page.page,
          total: page.total,
          hasNext: page.hasNext,
          loading: false,
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<void> filterByStatus(String? status) async {
    emit(state.copyWith(statusFilter: status, clearStatus: status == null));
    await load();
  }
}
