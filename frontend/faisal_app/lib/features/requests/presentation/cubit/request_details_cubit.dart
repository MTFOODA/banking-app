import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/request_entities.dart';
import '../../domain/repositories/requests_repository.dart';

class RequestDetailsState extends Equatable {
  const RequestDetailsState({
    this.request,
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
  });

  final ServiceRequestEntity? request;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;

  RequestDetailsState copyWith({
    ServiceRequestEntity? request,
    bool? loading,
    bool? busy,
    AppException? error,
    AppException? actionError,
    bool clearErrors = false,
  }) {
    return RequestDetailsState(
      request: request ?? this.request,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearErrors ? null : (error ?? this.error),
      actionError: clearErrors ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [request, loading, busy, actionError?.code];
}

class RequestDetailsCubit extends Cubit<RequestDetailsState> {
  RequestDetailsCubit(this._repository, this.requestId)
    : super(const RequestDetailsState());

  final RequestsRepository _repository;
  final String requestId;

  Future<void> load() async {
    emit(const RequestDetailsState(loading: true));
    try {
      emit(
        RequestDetailsState(
          request: await _repository.fetchRequest(requestId),
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(RequestDetailsState(loading: false, error: error));
    }
  }

  Future<bool> provideInformation(
    String message,
    Map<String, dynamic> fields,
  ) async {
    return _mutate(
      () => _repository.provideInformation(
        requestId,
        message: message,
        fields: fields,
      ),
    );
  }

  Future<bool> cancel() => _mutate(() => _repository.cancelRequest(requestId));

  Future<bool> _mutate(Future<ServiceRequestEntity> Function() action) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final request = await action();
      emit(state.copyWith(request: request, busy: false));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }
}
