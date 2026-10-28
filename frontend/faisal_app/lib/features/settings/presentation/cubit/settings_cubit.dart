import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/settings_entities.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.profile,
    this.preferences,
    this.sessions = const <TrustedSession>[],
    this.loading = true,
    this.busy = false,
    this.error,
    this.actionError,
    this.saved = false,
    this.pendingReference,
  });

  final ProfileDetails? profile;
  final CustomerPreferences? preferences;
  final List<TrustedSession> sessions;
  final bool loading;
  final bool busy;
  final AppException? error;
  final AppException? actionError;
  final bool saved;
  final String? pendingReference;

  SettingsState copyWith({
    ProfileDetails? profile,
    CustomerPreferences? preferences,
    List<TrustedSession>? sessions,
    bool? loading,
    bool? busy,
    AppException? error,
    AppException? actionError,
    bool? saved,
    bool clearErrors = false,
    String? pendingReference,
  }) {
    return SettingsState(
      pendingReference: pendingReference ?? this.pendingReference,
      profile: profile ?? this.profile,
      preferences: preferences ?? this.preferences,
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearErrors ? null : (error ?? this.error),
      actionError: clearErrors ? null : (actionError ?? this.actionError),
      saved: clearErrors ? false : (saved ?? this.saved),
    );
  }

  @override
  List<Object?> get props => [
    profile,
    preferences,
    sessions,
    loading,
    busy,
    error,
    actionError,
    saved,
    pendingReference,
  ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> load() async {
    emit(const SettingsState(loading: true));
    try {
      final profile = await _repository.fetchProfile();
      final preferences = await _repository.fetchPreferences();
      final sessions = await _repository.fetchSessions();
      emit(
        SettingsState(
          profile: profile,
          pendingReference: profile.pendingReference,
          preferences: preferences,
          sessions: sessions,
          loading: false,
        ),
      );
    } on AppException catch (error) {
      emit(SettingsState(loading: false, error: error));
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> changes) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final preferences = await _repository.updatePreferences(changes);
      emit(state.copyWith(preferences: preferences, busy: false, saved: true));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> changes) async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      final reference = await _repository.updateProfile(changes);
      emit(
        state.copyWith(pendingReference: reference, busy: false, saved: true),
      );
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }

  Future<void> loadSessions() async {
    try {
      emit(state.copyWith(sessions: await _repository.fetchSessions()));
    } on AppException catch (error) {
      emit(state.copyWith(actionError: error));
    }
  }

  Future<bool> revokeOtherSessions() async {
    emit(state.copyWith(busy: true, clearErrors: true));
    try {
      await _repository.revokeOtherSessions();
      emit(state.copyWith(busy: false, saved: true));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(busy: false, actionError: error));
      return false;
    }
  }
}
