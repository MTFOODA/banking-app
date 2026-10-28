import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../products/domain/entities/discover_entities.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminContentState extends Equatable {
  const AdminContentState({
    this.announcements = const <Announcement>[],
    this.products = const <BankingProduct>[],
    this.offers = const <Offer>[],
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
  });

  final List<Announcement> announcements;
  final List<BankingProduct> products;
  final List<Offer> offers;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;

  @override
  List<Object?> get props => [
    announcements,
    products,
    offers,
    loading,
    busy,
    actionError?.code,
  ];
}

class AdminContentCubit extends Cubit<AdminContentState> {
  AdminContentCubit(this._repository) : super(const AdminContentState());

  final AdminRepository _repository;

  Future<void> loadAnnouncements() async {
    if (isClosed || state.busy) return;
    emit(const AdminContentState(loading: true));
    try {
      final items = await _repository.fetchAnnouncements();
      if (!isClosed) {
        emit(AdminContentState(announcements: items, loading: false));
      }
    } on AppException catch (error) {
      if (!isClosed) emit(AdminContentState(loading: false, error: error));
    }
  }

  Future<bool> updateAnnouncement(String id, Map<String, dynamic> payload) =>
      _mutate(() => _repository.updateAnnouncement(id, payload));

  Future<void> load() async {
    emit(const AdminContentState(loading: true));
    try {
      final results = await Future.wait([
        _repository.fetchAnnouncements(),
        _repository.fetchProducts(),
        _repository.fetchOffers(),
      ]);
      emit(
        AdminContentState(
          announcements: results[0] as List<Announcement>,
          products: results[1] as List<BankingProduct>,
          offers: results[2] as List<Offer>,
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(AdminContentState(loading: false, error: error));
    }
  }

  Future<bool> publish(String id) =>
      _mutate(() => _repository.publishAnnouncement(id));
  Future<bool> archive(String id) =>
      _mutate(() => _repository.archiveAnnouncement(id));
  Future<bool> duplicate(String id) =>
      _mutate(() => _repository.duplicateAnnouncement(id));

  Future<bool> createAnnouncement(Map<String, dynamic> payload) =>
      _mutate(() => _repository.createAnnouncement(payload));

  Future<bool> createProduct(Map<String, dynamic> payload) =>
      _mutateProduct(() => _repository.createProduct(payload));

  Future<bool> createOffer(Map<String, dynamic> payload) =>
      _mutateOffer(() => _repository.createOffer(payload));

  Future<bool> _mutate(Future<Announcement> Function() action) async {
    if (isClosed || state.busy) return false;
    emit(
      AdminContentState(
        announcements: state.announcements,
        products: state.products,
        offers: state.offers,
        loading: false,
        busy: true,
      ),
    );
    try {
      final receipt = await action();
      var items = [
        receipt,
        ...state.announcements.where((item) => item.id != receipt.id),
      ];
      AppException? refreshError;
      try {
        items = await _repository.fetchAnnouncements();
      } on AppException catch (error) {
        refreshError = error;
      }
      if (isClosed) return false;
      emit(
        AdminContentState(
          announcements: items,
          products: state.products,
          offers: state.offers,
          loading: false,
          actionError: refreshError,
        ),
      );
      return true;
    } on AppException catch (error) {
      if (!isClosed) {
        emit(
          AdminContentState(
            announcements: state.announcements,
            products: state.products,
            offers: state.offers,
            loading: false,
            actionError: error,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _mutateProduct(Future<BankingProduct> Function() action) async {
    try {
      await action();
      emit(
        AdminContentState(
          announcements: state.announcements,
          products: await _repository.fetchProducts(),
          offers: state.offers,
          loading: false,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        AdminContentState(
          announcements: state.announcements,
          products: state.products,
          offers: state.offers,
          loading: false,
          actionError: error,
        ),
      );
      return false;
    }
  }

  Future<bool> _mutateOffer(Future<Offer> Function() action) async {
    try {
      await action();
      emit(
        AdminContentState(
          announcements: state.announcements,
          products: state.products,
          offers: await _repository.fetchOffers(),
          loading: false,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        AdminContentState(
          announcements: state.announcements,
          products: state.products,
          offers: state.offers,
          loading: false,
          actionError: error,
        ),
      );
      return false;
    }
  }
}
