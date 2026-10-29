# Saved banks and per-account biometric sign-in

Delivered 2026-10-29. Flutter version **1.3.0+4**.

## Behavior

Successful customer sign-in, registration, or mandatory first-login completion remembers the verified user ID, username and issuing bank on this device. Startup shows **My banks / بنوكي** instead of silently restoring the last customer. Each account has its official bank logo and bank theme; two different usernames at the same bank remain separate cards. Add a new bank follows the existing introductions/bank selection and username login or card/OTP registration.

A card without enabled biometrics opens its bank's existing username/password page with the username prefilled. A biometric card requires one native verification and a valid server refresh response for that exact user and bank. Expired, revoked, locked or mismatched identities never open the account. A password fallback is always available; cancelled verification and network errors allow retry.

More -> My banks parks the active session without revoking saved accounts. Explicit Sign out revokes/removes the current saved credential while retaining its chooser card. Other identities are preserved. Administrators and incomplete enrollments are excluded from customer cards; staff role checks and mandatory first-login setup remain intact.

## Architecture and security

The existing Clean Architecture, GetIt, BLoC/Cubit, Dio client, GoRouter, themes, compiled official bank logos, shared preferences, secure storage, and server login/refresh/logout APIs are reused. No dependencies or parallel authentication service were added.

- `SavedBank` contains only non-secret chooser metadata. SharedPreferences never receives passwords, cards, JWTs or OTPs.
- `LocalSavedBanksRepository` stores each rotating refresh credential in the existing encrypted platform SessionStore. Per-account access tokens are not retained. Web credentials remain memory-only.
- `SavedBanksCubit` observes repository metadata; AuthBloc owns biometric re-entry and session transitions. Pending username prefills stay in memory and never appear in URLs.
- The server response must match the selected user AND bank before session persistence. Session generations and serialized active-store writes prevent late refresh/registration responses from replacing a newly selected customer. Background refresh events cannot authenticate a signed-out chooser.
- Registration completion has its own authenticated-session event. Existing card/OTP/unique username/password creation and legacy first-login contracts remain unchanged.
- Android uses a small platform bridge with a separate enrollment-bound AndroidKeyStore AES-GCM key per user. Every enable/unlock creates a new BiometricPrompt CryptoObject with a per-use strong-biometric key; neither decrypted cipher state nor biometric success is cached. No banking secret passes through this channel. Backend refresh remains mandatory. Duplicate taps cannot create parallel verification prompts.
- This replaces the previous Android protected-marker path because actual emulator testing exposed a warmed cipher after secure-storage algorithm migration. An existing Android biometric preference therefore needs one password-authorized re-enablement in Profile. No customer password is changed. Android biometric re-entry requires Android 9/API 28+; unsupported devices retain password login.
- iOS keeps the existing biometryCurrentSet Keychain marker, now scoped per identity. Web biometrics remain disabled. Legacy iOS preferences migrate only to the backend-verified legacy customer.

Android platform references: [biometric authentication](https://developer.android.com/identity/sign-in/biometric-auth), [per-use and enrollment-invalidated keys](https://developer.android.com/reference/android/security/keystore/KeyGenParameterSpec.Builder).

## Database and preserved behavior

**No backend source, API contract, schema, migration, launcher identity, or existing branding asset changed. No migration is needed.**

The persistent local demo database was verified read-only against the preceding baseline: 35 accounts, 22 cards, 94 transactions, 118 ledger entries, 5 beneficiaries, 5 repayments, 6 investment holdings, 19 profiles and 20 credential/enrollment records retain identical SHA-256 content digests. Existing administrator username login, protected dashboard, anonymous rejection, logout and backend health were also exercised successfully. No password or permission was reset; ignored admin/admin.txt is unchanged.

Automated backend tests use their guarded isolated *_ci_test database with rollback fixtures. Android registration trials use the existing additive local-only `banking_app_qa_test` server, not the persistent demo or production database. Only fictional QA registrations were added; previous QA records were preserved.

## Actual verification

| Check | Executed result |
|---|---|
| Backend suite | **310 passed**, 50 existing dependency deprecation warnings |
| Flutter suite | **155 passed**, including 22 new saved-bank tests |
| Flutter analyze | **No issues found** |
| Dart format | **253 files, 0 changes**, exit 0 |
| Android emulator integration | **Passed**, one complete end-to-end test |
| Native biometric touches | Exactly one for enable, one for sign-in, one for revoked-session verification |
| Normal debug APK | Built, installed and cold-launched on emulator-5554 |
| Web debug JavaScript | Built; locally served main.dart.js SHA-256 equals build artifact |
| Wasm | Compiler dry run succeeded; no Wasm build/runtime claim |
| Physical Android / iOS | Not exercised in this delivery |

The emulator test registered fresh NBE/CIB/Banque Misr customers through card -> development OTP -> unique username/password, preserved all three cards, signed into each with the right bank theme, enabled CIB biometrics through current-password step-up, recreated the actual dependency root from device preferences/keystore, unlocked CIB with one fingerprint, switched to NBE by password, rendered Arabic/RTL dark cards, revoked the CIB session through the real backend, and confirmed fingerprint success still falls back to password after server rejection. Seven actual screenshots are in `screenshots/saved_banks/2026-10-29`.

During development, the earlier emulator attempt exposed the cached-cipher issue and was corrected. A subsequent harness issue matched only English prompt titles; the runner now supports Arabic too. These attempts are not counted as successful tests. The final full emulator run exited 0. A legacy widget test was updated to inject its biometric vault fake instead of waiting for an unconfigured native channel; its backend-expiration assertions remain in place.

## Run and reproduce

From project root, keep backend terminal open:

```powershell
.\admin\start_server.cmd
.\admin\run_web.cmd
```

Or run the emulator from `frontend/faisal_app`:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
flutter analyze
flutter test --reporter expanded --concurrency 1
dart format --output=none --set-exit-if-changed lib test integration_test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1
```

Backend tests from `backend`:

```powershell
$env:DEBUG='false'
.venv/Scripts/python.exe -m pytest -q
```

Opt-in emulator QA from project root:

```powershell
$env:DEBUG='false'
$env:RUN_BRANDING_QA='1'
backend/.venv/Scripts/python.exe backend/serve_branding_qa.py
# Second terminal; debug package installed and emulator finger 1 enrolled:
backend/.venv/Scripts/python.exe scripts/run_saved_banks_emulator.py
```

The runner stages random local QA fixtures privately with Android run-as, never as Dart build flags or public logs. Each QA-server restart adds fresh fictional unregistered fixtures without resetting previous users. Development OTP appears on the existing OTP screen; there is still no real SMS/email delivery configured. Real delivery instructions remain in the existing security documentation.

## Limits and operational notes

Saved bank ownership is based on this fictional backend's verified customer data, not a live connection to commercial bank networks. Re-entry needs a live backend and an unexpired refresh session; it never logs in offline. Web chooser metadata survives reloads but tokens do not, so browsers use password login after restart. Physical-device fingerprint enrollment changes and iOS Keychain behavior still need hardware validation. Launcher icons/names remain fixed Banking App branding. No production deployment, main-branch merge, credentials upload or migration execution is part of this change.

## Exact files

See `SAVED_BANKS_CHANGED_FILES.txt` for every added/modified public file and purpose. Local fixtures, private credentials, build artifacts and tool logs are excluded from source control.

## Build fingerprints

```json
{
  "apk": {
    "path": "frontend/faisal_app/build/app/outputs/flutter-apk/app-debug.apk",
    "bytes": 174067471,
    "sha256": "48dcaffdb1e815942666c5ed1cbb4bc5588ef0e0ff4885a8ef436b4c927cbf94"
  },
  "web_js": {
    "path": "frontend/faisal_app/build/web/main.dart.js",
    "bytes": 15818888,
    "sha256": "315e12eb91a759a5771078aaf13e358b0c184da426dc4aa7044fd74aee410c09"
  }
}
```
