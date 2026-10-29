import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A local preference plus an enrollment-bound, hardware-protected marker.
/// Backend sessions remain authoritative; this marker is never a login token.
class BiometricService {
  BiometricService(
    this.preferences, {
    LocalAuthentication? auth,
    FlutterSecureStorage? vault,
  }) : _nativeAndroid = vault == null,
       _auth = auth ?? LocalAuthentication(),
       _vault =
           vault ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions.biometric(
               enforceBiometrics: true,
               requireBiometricsPerOperation: true,
               biometricType: AndroidBiometricType.strongBiometricOnly,
               resetOnError: false,
               storageNamespace: 'faisal_biometric_guard',
             ),
             iOptions: IOSOptions(
               accountName: 'faisal_biometric_guard',
               accessibility: KeychainAccessibility.unlocked_this_device,
               accessControlFlags: [AccessControlFlag.biometryCurrentSet],
             ),
           );
  final SharedPreferences? preferences;
  final LocalAuthentication _auth;
  final FlutterSecureStorage _vault;
  final bool _nativeAndroid;
  bool get _androidGuard =>
      _nativeAndroid &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;
  static const _channel = MethodChannel('banking/biometric_guard_v2');
  Future<bool> _native(
    String method,
    String? identity, [
    String? reason,
  ]) async =>
      await _channel.invokeMethod<bool>(method, {
        'identity': identity,
        'reason': reason,
      }) ??
      false;
  static const _preference = 'faisal.biometric_enabled';
  static const _marker = 'enrollment_guard';
  String? _identity;
  bool authenticating = false;
  void bindIdentity(String? id) => _identity = id;
  bool enabledFor(String id) => _androidGuard
      ? (preferences?.getBool('$_preference.$id.android_keystore_v2') ?? false)
      : preferences?.getBool('$_preference.$id') ??
            (preferences?.getString('$_preference.legacy_owner') == id &&
                (preferences?.getBool(_preference) ?? false));
  bool get enabled => _identity == null
      ? (!_androidGuard && (preferences?.getBool(_preference) ?? false))
      : enabledFor(_identity!);
  String get _scopedPreference =>
      _identity == null ? _preference : '$_preference.${_identity!}';
  String get _scopedMarker =>
      _identity == null ||
          preferences?.getString('$_preference.legacy_owner') == _identity
      ? _marker
      : '$_marker.${_identity!}';

  /// Only called after the server identifies the one legacy active customer.
  Future<void> migrateLegacyIdentity(String id) async {
    // Android's old storage cipher can stay warm after a migration. Re-enable
    // once with the existing server password step-up to create a per-use key.
    if (_androidGuard) return;
    if ((preferences?.getBool(_preference) ?? false) &&
        preferences?.getString('$_preference.legacy_owner') == null) {
      await preferences?.setString('$_preference.legacy_owner', id);
    }
  }

  AndroidOptions _promptOptions(String reason) => _vault.aOptions.copyWith(
    biometricPromptTitle: reason,
    biometricPromptSubtitle: reason,
  );

  Future<bool> available() async {
    if (kIsWeb ||
        preferences == null ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return false;
    }
    try {
      if (_androidGuard && !await _native('supported', null)) return false;
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable(String reason) async {
    final identity = _identity;
    final marker = _scopedMarker, preference = _scopedPreference;
    if (!await available()) return false;
    authenticating = true;
    try {
      if (_androidGuard) {
        if (identity == null || !await _native('enable', identity, reason)) {
          return false;
        }
        await preferences!.setBool('$preference.android_keystore_v2', true);
        return true;
      }
      // Android's protected write already authenticates its CryptoObject.
      // Keychain insertion on iOS needs its own enrollment confirmation.
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          !await _auth.authenticate(
            localizedReason: reason,
            biometricOnly: true,
          )) {
        return false;
      }
      await _vault.write(
        key: marker,
        value: 'enabled',
        aOptions: _promptOptions(reason),
      );
      await preferences!.setBool(preference, true);
      return true;
    } catch (_) {
      return false;
    } finally {
      authenticating = false;
    }
  }

  Future<bool> unlock(String reason) async {
    final identity = _identity;
    final marker = _scopedMarker;
    if (!enabled || !await available()) return false;
    authenticating = true;
    try {
      if (_androidGuard) {
        return identity != null && await _native('unlock', identity, reason);
      }
      // Reading the enrollment-bound marker is the single native challenge.
      // A separate local_auth prompt cannot authorize this protected read.
      return await _vault.read(key: marker, aOptions: _promptOptions(reason)) ==
          'enabled';
    } catch (_) {
      // An invalidated key never silently becomes an unlocked session.
      return false;
    } finally {
      authenticating = false;
    }
  }

  Future<void> disable() async {
    final marker = _scopedMarker, preference = _scopedPreference;
    if (_androidGuard) {
      await preferences?.setBool('$preference.android_keystore_v2', false);
      try {
        await _native('disable', _identity);
      } catch (_) {
        /* Missing key. */
      }
      return;
    }
    await preferences?.setBool(preference, false);
    try {
      await _vault.delete(key: marker);
    } catch (_) {
      /* Already invalidated keys can be discarded. */
    }
  }
}
