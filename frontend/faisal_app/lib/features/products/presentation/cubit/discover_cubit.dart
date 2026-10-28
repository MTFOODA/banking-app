import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/discover_entities.dart';
import '../../domain/repositories/discover_repository.dart';

class DiscoverState extends Equatable {
  const DiscoverState({this.content, this.loading = true, this.error});

  final DiscoverContent? content;
  final bool loading;
  final AppException? error;

  @override
  List<Object?> get props => [content, loading, error?.code];
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit(this._repository) : super(const DiscoverState());

  final DiscoverRepository _repository;

  Future<void> load() async {
    emit(const DiscoverState(loading: true));
    try {
      emit(
        DiscoverState(
          content: await _repository.loadDiscover(),
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(DiscoverState(loading: false, error: error));
    }
  }
}
