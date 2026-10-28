import 'dart:convert';
import 'dart:async';

import '../../data/branding_asset_cache.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/branding_config.dart';
import '../../domain/repositories/branding_repository.dart';

const brandingCacheKey = 'faisal.branding.v1';

class BrandingCubit extends Cubit<BrandingSnapshot> {
  BrandingCubit(this.repository, this.preferences, {this.assetCache})
    : super(_cached(preferences));
  final BrandingAssetCache? assetCache;
  final BrandingRepository repository;
  final SharedPreferences? preferences;
  Future<void>? _inFlight;
  DateTime? _lastAttempt;
  static BrandingSnapshot _cached(SharedPreferences? preferences) {
    try {
      final cache = preferences?.getString(brandingCacheKey);
      if (cache != null) {
        return BrandingSnapshot.fromJson(
          jsonDecode(cache) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      /* Ignore invalid/old cache, preserve original UI. */
    }
    return BrandingSnapshot(0, BrandingConfig.defaults);
  }

  Future<void> refresh({bool force = false}) {
    if (_inFlight != null) {
      return _inFlight!;
    }
    if (isClosed ||
        (!force &&
            _lastAttempt != null &&
            DateTime.now().difference(_lastAttempt!) <
                const Duration(seconds: 30))) {
      return Future.value();
    }
    _lastAttempt = DateTime.now();
    return _inFlight = _refresh().whenComplete(() => _inFlight = null);
  }

  Future<void> _refresh() async {
    try {
      final next = await repository.fetch(knownVersion: state.version);
      if (isClosed ||
          next == null ||
          next.version < state.version ||
          next == state) {
        return;
      }
      emit(next);
      try {
        await preferences?.setString(
          brandingCacheKey,
          jsonEncode(next.toJson()),
        );
      } catch (_) {
        /* In-memory configuration remains valid. */
      }
    } catch (_) {
      /* Offline/unavailable/invalid configuration never interrupts banking. */
    } finally {
      if (!isClosed) {
        unawaited(assetCache?.retain(state.config).catchError((_) {}));
      }
    }
  }
}
