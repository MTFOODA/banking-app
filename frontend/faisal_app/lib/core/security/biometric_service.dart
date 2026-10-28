import 'package:flutter/foundation.dart';
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
  }) : _auth = auth ?? LocalAuthentication(),
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
  static const _preference = 'faisal.biometric_enabled';
  static const _marker = 'enrollment_guard';
  bool get enabled => preferences?.getBool(_preference) ?? false;
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
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable(String reason) async {
    if (!await available()) return false;
    try {
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
        key: _marker,
        value: 'enabled',
        aOptions: _promptOptions(reason),
      );
      await preferences!.setBool(_preference, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlock(String reason) async {
    if (!enabled || !await available()) return false;
    try {
      // Reading the enrollment-bound marker is the single native challenge.
      // A separate local_auth prompt cannot authorize this protected read.
      return await _vault.read(
            key: _marker,
            aOptions: _promptOptions(reason),
          ) ==
          'enabled';
    } catch (_) {
      // An invalidated key never silently becomes an unlocked session.
      return false;
    }
  }

  Future<void> disable() async {
    await preferences?.setBool(_preference, false);
    try {
      await _vault.delete(key: _marker);
    } catch (_) {
      /* Already invalidated keys can be discarded. */
    }
  }
}
