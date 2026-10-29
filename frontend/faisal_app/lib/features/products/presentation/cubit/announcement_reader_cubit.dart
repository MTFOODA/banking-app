import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/discover_entities.dart';
import '../../domain/repositories/discover_repository.dart';

class AnnouncementReaderState {
  const AnnouncementReaderState({
    this.items = const [],
    this.loading = true,
    this.error,
  });
  final List<Announcement> items;
  final bool loading;
  final AppException? error;
}

class AnnouncementReaderCubit extends Cubit<AnnouncementReaderState> {
  AnnouncementReaderCubit(this._repository, {this.id, this.bankCode})
    : super(const AnnouncementReaderState());
  final DiscoverRepository _repository;
  final String? id;
  final String? bankCode;
  Future<void> load() async {
    if (isClosed) return;
    emit(const AnnouncementReaderState());
    try {
      final items = id == null
          ? await _repository.fetchPublicAnnouncements(bankCode: bankCode)
          : [await _repository.fetchAnnouncement(id!)];
      if (!isClosed) {
        emit(AnnouncementReaderState(items: items, loading: false));
      }
    } on AppException catch (error) {
      if (!isClosed) {
        emit(AnnouncementReaderState(loading: false, error: error));
      }
    }
  }
}
