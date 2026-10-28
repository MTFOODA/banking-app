import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/bank_branch.dart';
import '../../domain/repositories/bank_directory_repository.dart';

String branchSearchKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي');

class BranchDirectoryState {
  const BranchDirectoryState({
    this.branches = const [],
    this.loading = true,
    this.error,
    this.query = '',
    this.governorate,
  });
  final List<BankBranch> branches;
  final bool loading;
  final AppException? error;
  final String query;
  final String? governorate;
  List<String> get governorates =>
      (branches.map((b) => b.governorate).toSet().toList()..sort());
  List<BankBranch> get visible => branches
      .where(
        (b) =>
            (governorate == null || b.governorate == governorate) &&
            branchSearchKey('${b.name} ${b.governorate} ${b.address}')
                .contains(branchSearchKey(query)),
      )
      .toList();
}

class BranchDirectoryCubit extends Cubit<BranchDirectoryState> {
  BranchDirectoryCubit(this._repository) : super(const BranchDirectoryState());
  final BankDirectoryRepository _repository;
  Future<void> load() async {
    if (isClosed) return;
    final previous = state;
    emit(
      BranchDirectoryState(
        branches: previous.branches,
        query: previous.query,
        governorate: previous.governorate,
      ),
    );
    try {
      final branches = await _repository.loadBranches();
      if (!isClosed) {
        emit(
          BranchDirectoryState(
            branches: branches,
            loading: false,
            query: state.query,
            governorate: state.governorate,
          ),
        );
      }
    } on AppException catch (error) {
      if (!isClosed) {
        emit(
          BranchDirectoryState(
            branches: state.branches,
            loading: false,
            error: error,
            query: state.query,
            governorate: state.governorate,
          ),
        );
      }
    }
  }

  void filter({
    String? query,
    String? governorate,
    bool clearGovernorate = false,
  }) => emit(
    BranchDirectoryState(
      branches: state.branches,
      loading: state.loading,
      error: state.error,
      query: query ?? state.query,
      governorate: clearGovernorate ? null : governorate ?? state.governorate,
    ),
  );
}
