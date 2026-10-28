import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded(this.overview);

  final HomeOverview overview;

  @override
  List<Object?> get props => [overview];
}

class HomeFailure extends HomeState {
  const HomeFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error.code];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeLoading());

  final HomeRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (isClosed) return;
    if (!silent) {
      emit(const HomeLoading());
    }
    try {
      final overview = await _repository.load();
      if (!isClosed) emit(HomeLoaded(overview));
    } on AppException catch (error) {
      if (!isClosed) emit(HomeFailure(error));
    } catch (_) {
      if (!isClosed) {
        emit(const HomeFailure(AppException(code: AppErrorCode.unknown)));
      }
    }
  }
}
