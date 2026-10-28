import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/support_entities.dart';
import '../../domain/repositories/support_repository.dart';

class SupportState extends Equatable {
  const SupportState({
    this.tickets = const <SupportTicketEntity>[],
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
  });

  final List<SupportTicketEntity> tickets;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;

  @override
  List<Object?> get props => [
    tickets,
    loading,
    busy,
    error?.code,
    actionError?.code,
  ];
}

class SupportCubit extends Cubit<SupportState> {
  SupportCubit(this._repository) : super(const SupportState());

  final SupportRepository _repository;

  Future<void> load() async {
    emit(const SupportState(loading: true));
    try {
      emit(
        SupportState(tickets: await _repository.fetchTickets(), loading: false),
      );
    } on AppException catch (error) {
      emit(SupportState(loading: false, error: error));
    }
  }

  Future<bool> createTicket({
    required String subject,
    required String message,
  }) async {
    emit(SupportState(tickets: state.tickets, loading: false, busy: true));
    try {
      final ticket = await _repository.createTicket(
        subject: subject,
        message: message,
      );
      emit(SupportState(tickets: [ticket, ...state.tickets], loading: false));
      return true;
    } on AppException catch (error) {
      emit(
        SupportState(
          tickets: state.tickets,
          loading: false,
          actionError: error,
        ),
      );
      return false;
    }
  }

  Future<bool> sendMessage(String ticketId, String message) async {
    try {
      final updated = await _repository.sendMessage(ticketId, message);
      emit(
        SupportState(
          tickets: state.tickets
              .map((ticket) => ticket.id == ticketId ? updated : ticket)
              .toList(growable: false),
          loading: false,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        SupportState(
          tickets: state.tickets,
          loading: false,
          actionError: error,
        ),
      );
      return false;
    }
  }
}
