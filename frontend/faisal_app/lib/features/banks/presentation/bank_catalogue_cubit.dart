import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/bank_definition.dart';
import '../domain/repositories/bank_catalogue_repository.dart';

class BankCatalogueCubit extends Cubit<BankCatalogue> {
  BankCatalogueCubit(this.repository, this.preferences)
    : super(_cached(preferences));
  final BankCatalogueRepository repository;
  final SharedPreferences? preferences;
  static const cacheKey = 'banking.catalogue.v2';
  Future<void>? _inFlight;
  DateTime? _last;
  static BankCatalogue _cached(SharedPreferences? preferences) {
    try {
      final raw = preferences?.getString(cacheKey);
      if (raw != null) {
        return BankCatalogue.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
    return BankCatalogue.bundled;
  }

  Future<void> refresh({bool force = false}) {
    if (_inFlight != null) {
      return _inFlight!;
    }
    if (isClosed ||
        (!force &&
            _last != null &&
            DateTime.now().difference(_last!) < const Duration(seconds: 30))) {
      return Future.value();
    }
    _last = DateTime.now();
    return _inFlight = _fetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _fetch() async {
    try {
      final next = await repository.fetch(knownVersion: state.version);
      if (next == null || isClosed || next == state) {
        return;
      }
      emit(next);
      final banks = next.banks
          .map(
            (b) => {
              'code': b.code,
              'name_en': b.nameEn,
              'name_ar': b.nameAr,
              'website': b.website,
              'identity_primary': b.primary,
              'identity_accent': b.accent,
              'registration_enabled': b.registrationEnabled,
              'abbreviation': b.abbreviation,
              'logo_asset': b.logoAsset,
              'light': b.light,
              'dark': b.dark,
            },
          )
          .toList();
      try {
        await preferences?.setString(
          cacheKey,
          jsonEncode({'version': next.version, 'banks': banks}),
        );
      } catch (_) {}
    } catch (_) {
      /* Valid cached/bundled catalogue remains available. */
    }
  }
}
