import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.dashboard,
    this.auditEntries = const <AuditEntry>[],
    this.loading = true,
    this.error,
  });

  final AdminDashboard? dashboard;
  final List<AuditEntry> auditEntries;
  final bool loading;
  final AppException? error;

  AdminDashboardState copyWith({
    AdminDashboard? dashboard,
    List<AuditEntry>? auditEntries,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) {
    return AdminDashboardState(
      dashboard: dashboard ?? this.dashboard,
      auditEntries: auditEntries ?? this.auditEntries,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [dashboard, auditEntries, loading, error?.code];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardState());

  final AdminRepository _repository;
  bool _loading = false;

  Future<void> load() async {
    if (isClosed || _loading) return;
    _loading = true;
    emit(const AdminDashboardState(loading: true));
    try {
      final dashboard = await _repository.fetchDashboard();
      if (isClosed) return;
      emit(
        AdminDashboardState(
          dashboard: dashboard,
          auditEntries: dashboard.recentActions,
          loading: false,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(AdminDashboardState(loading: false, error: error));
    } finally {
      _loading = false;
    }
  }
}

class AdminAuditState extends Equatable {
  const AdminAuditState({
    this.entries = const <AuditEntry>[],
    this.loading = true,
    this.error,
  });

  final List<AuditEntry> entries;
  final bool loading;
  final AppException? error;

  @override
  List<Object?> get props => [entries, loading, error?.code];
}

class AdminAuditCubit extends Cubit<AdminAuditState> {
  AdminAuditCubit(this._repository) : super(const AdminAuditState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const AdminAuditState(loading: true));
    try {
      emit(
        AdminAuditState(
          entries: await _repository.fetchAuditLogs(),
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(AdminAuditState(loading: false, error: error));
    }
  }
}
