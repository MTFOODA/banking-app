import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

const String _languageKey = 'faisal.preference.language';
const String _themeKey = 'faisal.preference.theme';

/// App-wide language preference (persisted locally, synced when signed in).
///
/// [preferences] is nullable so start-up can continue with built-in defaults
/// when the platform preference store is unavailable.
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit(this._preferences, this._repository)
    : super(const Locale('en'));

  final SharedPreferences? _preferences;
  final SettingsRepository _repository;

  Future<void> load() async {
    final stored = _preferences?.getString(_languageKey);
    if (stored == 'ar' || stored == 'en') {
      emit(Locale(stored!));
    }
  }

  Future<void> change(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ar') {
      return;
    }
    emit(Locale(languageCode));
    await _preferences?.setString(_languageKey, languageCode);
    await _syncToServer({'language': languageCode});
  }

  Future<void> adoptServerPreference(String languageCode) async {
    if ((languageCode == 'ar' || languageCode == 'en') &&
        languageCode != state.languageCode) {
      emit(Locale(languageCode));
      await _preferences?.setString(_languageKey, languageCode);
    }
  }

  Future<void> _syncToServer(Map<String, dynamic> changes) async {
    try {
      await _repository.updatePreferences(changes);
    } catch (_) {
      // Local preference remains authoritative while offline.
    }
  }
}

/// App-wide theme preference using a dedicated immutable theme mode.
///
/// [preferences] is nullable for the same start-up hardening reason as
/// [LanguageCubit].
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences, this._repository) : super(ThemeMode.system);

  final SharedPreferences? _preferences;
  final SettingsRepository _repository;

  Future<void> load() async {
    final stored = _preferences?.getString(_themeKey);
    emit(_themeMode(stored));
  }

  Future<void> change(ThemeMode mode) async {
    emit(mode);
    await _preferences?.setString(_themeKey, _themeName(mode));
    try {
      await _repository.updatePreferences({'theme': _themeName(mode)});
    } catch (_) {
      // Ignore sync failures; the local choice is still applied.
    }
  }

  Future<void> adoptServerPreference(String theme) async {
    final mode = _themeMode(theme);
    if (mode != state) {
      emit(mode);
      await _preferences?.setString(_themeKey, _themeName(mode));
    }
  }

  static ThemeMode _themeMode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _themeName(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
