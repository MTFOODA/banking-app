import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRequestDetailState extends Equatable {
  const AdminRequestDetailState({
    this.detail,
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
  });

  final AdminRequestDetail? detail;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;

  AdminRequestDetailState copyWith({
    AdminRequestDetail? detail,
    bool? loading,
    bool? busy,
    AppException? error,
    AppException? actionError,
    bool clearErrors = false,
  }) {
    return AdminRequestDetailState(
      detail: detail ?? this.detail,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearErrors ? null : (error ?? this.error),
      actionError: clearErrors ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [detail, loading, busy, actionError?.code];
}

class AdminRequestDetailCubit extends Cubit<AdminRequestDetailState> {
  AdminRequestDetailCubit(this._repository, this.requestId)
    : super(const AdminRequestDetailState());

  final AdminRepository _repository;
  final String requestId;

  Future<void> load() async {
    if (isClosed || state.busy) return;
    emit(const AdminRequestDetailState(loading: true));
    try {
      final detail = await _repository.fetchRequest(requestId);
      if (!isClosed) {
        emit(AdminRequestDetailState(detail: detail, loading: false));
      }
    } on AppException catch (error) {
      if (!isClosed) {
        emit(AdminRequestDetailState(loading: false, error: error));
      }
    }
  }

  Future<bool> decide({
    required bool approve,
    required String reason,
    String? explanation,
  }) async {
    if (isClosed || state.busy) return false;
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final receipt = approve
          ? await _repository.approveRequest(
              requestId,
              reason: reason.isEmpty ? null : reason,
              explanation: explanation,
            )
          : await _repository.rejectRequest(
              requestId,
              reason: reason,
              explanation: explanation,
            );
      var detail = AdminRequestDetail(
        request: receipt,
        customer: state.detail?.customer,
      );
      AppException? refreshError;
      try {
        detail = await _repository.fetchRequest(requestId);
      } on AppException catch (error) {
        refreshError = error;
      }
      if (isClosed) return false;
      emit(
        state.copyWith(detail: detail, busy: false, actionError: refreshError),
      );
      return true;
    } on AppException catch (error) {
      if (!isClosed) emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }

  Future<bool> requestInformation(String message) => _change(() async {
    await _repository.requestInformation(requestId, message: message);
  });

  Future<bool> addNote(String note) =>
      _change(() => _repository.addNote(requestId, note));

  Future<bool> _change(Future<void> Function() action) async {
    if (isClosed || state.busy) return false;
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      await action();
      final detail = await _repository.fetchRequest(requestId);
      if (isClosed) return false;
      emit(state.copyWith(detail: detail, busy: false));
      return true;
    } on AppException catch (error) {
      if (!isClosed) emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }
}
