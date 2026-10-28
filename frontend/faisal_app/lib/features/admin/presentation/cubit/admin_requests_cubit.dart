import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRequestsState extends Equatable {
  const AdminRequestsState({
    this.items = const <AdminRequestItem>[],
    this.reviewers = const <AdminReviewer>[],
    this.page = 1,
    this.total = 0,
    this.hasNext = false,
    this.loading = true,
    this.busy = false,
    this.statusFilter,
    this.search,
    this.error,
    this.actionError,
  });

  final List<AdminRequestItem> items;
  final List<AdminReviewer> reviewers;
  final int page, total;
  final bool hasNext;
  final bool loading;
  final bool busy;
  final String? statusFilter;
  final String? search;
  final AppException? error;
  final AppException? actionError;

  AdminRequestsState copyWith({
    List<AdminRequestItem>? items,
    List<AdminReviewer>? reviewers,
    int? page,
    int? total,
    bool? hasNext,
    bool? loading,
    bool? busy,
    String? statusFilter,
    bool clearStatus = false,
    String? search,
    AppException? error,
    AppException? actionError,
    bool clearErrors = false,
  }) {
    return AdminRequestsState(
      items: items ?? this.items,
      reviewers: reviewers ?? this.reviewers,
      page: page ?? this.page,
      total: total ?? this.total,
      hasNext: hasNext ?? this.hasNext,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      search: search ?? this.search,
      error: clearErrors ? null : (error ?? this.error),
      actionError: clearErrors ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    items,
    page,
    total,
    hasNext,
    reviewers,
    loading,
    busy,
    statusFilter,
    search,
    error?.code,
    actionError?.code,
  ];
}

class AdminRequestsCubit extends Cubit<AdminRequestsState> {
  AdminRequestsCubit(this._repository) : super(const AdminRequestsState());

  final AdminRepository _repository;

  int _generation = 0;
  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(state.copyWith(loading: true, busy: false, clearErrors: true));
    try {
      final page = await _repository.fetchRequests(
        status: state.statusFilter,
        search: state.search,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          items: page.items,
          page: page.page,
          total: page.total,
          hasNext: page.hasNext,
          loading: false,
        ),
      );
    } on AppException catch (error) {
      if (!isClosed && generation == _generation) {
        emit(state.copyWith(loading: false, error: error));
      }
    }
  }

  Future<void> loadMore() async {
    if (isClosed || state.loading || state.busy || !state.hasNext) return;
    final generation = _generation;
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final page = await _repository.fetchRequests(
        status: state.statusFilter,
        search: state.search,
        page: state.page + 1,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          page: page.page,
          total: page.total,
          hasNext: page.hasNext,
          busy: false,
        ),
      );
    } on AppException catch (error) {
      if (!isClosed && generation == _generation) {
        emit(state.copyWith(busy: false, actionError: error));
      }
    }
  }

  Future<void> filterByStatus(String? status) async {
    emit(state.copyWith(statusFilter: status, clearStatus: status == null));
    await load();
  }

  Future<void> searchBy(String? query) async {
    emit(state.copyWith(search: query));
    await load();
  }

  Future<bool> decide({
    required String requestId,
    required bool approve,
    required String reason,
    String? explanation,
  }) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      if (approve) {
        await _repository.approveRequest(
          requestId,
          reason: reason.isEmpty ? null : reason,
          explanation: explanation,
        );
      } else {
        await _repository.rejectRequest(
          requestId,
          reason: reason,
          explanation: explanation,
        );
      }
      final page = await _repository.fetchRequests(status: state.statusFilter);
      emit(state.copyWith(items: page.items, busy: false));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }

  Future<bool> requestInformation(String requestId, String message) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      await _repository.requestInformation(requestId, message: message);
      final page = await _repository.fetchRequests(status: state.statusFilter);
      emit(state.copyWith(items: page.items, busy: false));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }

  Future<bool> assign(String requestId, String? reviewerId) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      await _repository.assignRequest(requestId, reviewerId: reviewerId);
      final page = await _repository.fetchRequests(status: state.statusFilter);
      emit(state.copyWith(items: page.items, busy: false));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }
}
