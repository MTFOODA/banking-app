# Banking App: fixed identity and bank-scoped appearance

Implementation date: 2026-10-28. This supersedes the name/logo/free-color controls
described in the earlier dynamic-branding report; existing publication history
and assets are retained.

## Architecture and behavior

The existing Flutter Clean Architecture, repositories, Dio client, BLoC/Cubit,
router, localization, authentication and banking services remain in use.
`BankingIdentity` owns the compiled Banking App name and original generated logo.
Android launcher/splash, iOS app icons, web/PWA icons and desktop identity
resources use build-time assets; previous resources are archived under
`admin/branding_archive/faisal_original_20261028` with their original hashes.
Package IDs and native activity classes are unchanged to preserve upgrade paths.

Customers explicitly select an issuer bank before entering their existing card.
The server resolves card/account ownership and checks the existing verified
customer profile's bank. The client cannot assign or change affiliation.
Wrong-bank and unknown-card challenges follow the existing non-enumerating OTP
flow. No passwords, grant consumption, lockouts or session policies were bypassed.
Older API clients retain the default Faisal/card-or-account contract; the new
Flutter registration request explicitly selects card registration and a bank.
Sign-in also offers a bank selector, with automatic detection for existing
usernames/cards and staff login. If supplied, the server checks the selected bank
against the authenticated customer's profile using the same generic credential
failure path. It never trusts a selected color/bank as session authority.
One person can use independent usernames for different banks on the same app;
each login replaces the previous identity/theme with its own verified bank.

The reviewed catalogue contains 37 Egyptian-bank identity presets, with 35
available for fictional customer registration. Corporate-only Citi and Standard
Chartered Egypt are appearance presets without retail registration. Catalogues
are generated from one source, validated for contrast, bundled for offline use,
cached through the existing preferences mechanism and conditionally refreshed.
These are accessible original interpretations of bank colors, not certified
official design systems, endorsements, or connections to those banks.

`CustomerAppearance` applies each customer's bank palette only to authenticated
customer routes. The fixed external login/public/startup/admin theme remains
unchanged by publications. A stable Theme/BrandingScope surrounds the existing
router child; a test verifies Navigator identity and unsubmitted form values
survive a configuration update. Actual owned card visuals and product previews
use the bank palette while keeping card tier artwork and black platinum styles.

Admin Settings > Bank appearance settings provides a bank selector, read-only
fixed identity and palette swatches, light/dark preview, per-bank welcome/caption,
installed font choices, safe text scale/weights and appearance mode. Existing
draft/save/publish/version/history controls are reused. Restoring one bank leaves
other bank settings intact. Drafts never affect customers; publication uses the
existing locked revision check and transaction. The public response sanitizes
legacy identity/color overrides without rewriting old history. Identity uploads
are disabled server-side, including for administrators. Unauthorized users remain
denied by existing content-management permissions.

No websocket infrastructure exists. Startup and foreground resume perform
coalesced conditional refreshes, preserving valid cached settings when offline.
Supported internal content/typography settings therefore require no app download;
compiled name/logo/launcher changes require a new application release.

## Database safety

Additive migration `c94d28f1a710`, parent `b317a90d66e1`, creates the bank catalogue
and adds indexed `customer_profiles.bank_code` with a foreign key and the default
`faisal`. All existing customers retain ownership, balances, history, credentials
and enrollment state. The local persistent demo database was upgraded; original
row counts and SHA-256 digests across 40 pre-existing tables matched before/after
the migration, excluding only the deliberately added bank column.

Four additional fictional, unenrolled customers were provisioned (two NBE, two
CIB). Provisioning verifies old-row preservation and second-run idempotency.
Their cards and issuer banks are in ignored `admin/admin.txt`; no passwords were
reset. These customers choose username/password after OTP. The latest individual
batch is also in ignored `admin/NEW_REGISTRATION_USERS.txt`.

Rollback: prefer rolling back application code without removing the additive
schema. Alembic downgrade removes only the new bank affiliation column/catalogue;
it would lose newly recorded affiliation and must be deliberately planned and
backed up. No downgrade/reset was executed.

## Run and test

From the project root, `admin/start_server.cmd` starts/reuses the existing demo
API at 8011; `admin/run_web.cmd` opens/reuses the app at http://127.0.0.1:8080.
Full commands remain in `admin/RUN_COMMANDS.txt` and ignored `admin/admin.txt`.
For that local demo specifically, `backend/.venv/Scripts/python.exe admin/migrate_demo.py`
applies additive migrations to the guarded configured localhost `_test` database.
It refuses production, remote hosts, and stamping/resetting unversioned data.

```powershell
cd backend
$env:DEBUG='false'
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m pytest
```

Alembic uses DATABASE_URL. Select the intended database explicitly; automated
tests use the separately guarded `_ci_test` database, never the persistent demo.

```powershell
cd frontend/faisal_app
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test integration_test
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
flutter run -d edge --web-hostname=127.0.0.1 --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1
flutter build apk --debug --target lib/main.dart --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
flutter build web --debug --dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1
```

Fresh registration scenarios: select the exact Bank printed next to an unused
card in the private admin file, request OTP, use the visibly labeled development
code below the OTP form, choose an available alphanumeric username and compliant
password. Confirm the home header/theme and registered bank in Profile. Choosing
a different bank must not produce a usable OTP or mutate ownership. Real OTP
delivery still requires the existing verified-contact provider configuration;
the development adapter sends no SMS/email. Never enable OTP exposure in
production. Test internal transfers only between customers at the same bank;
own-account transfers and same-currency international simulation remain governed
by the existing services and authorization tokens.
For real email OTP delivery, configure `OTP_PROVIDER=smtp`, `SMTP_HOST`,
`SMTP_PORT`, `SMTP_FROM`, and where needed `SMTP_USERNAME`/`SMTP_PASSWORD` in a
local secret environment file. Set `OTP_DEV_EXPOSE=false`, use verified existing
customer emails and an HTTPS production API. The existing SMTP adapter uses
STARTTLS. No external SMTP credentials or real delivery were available to test.
An SMS provider can implement the existing `OtpProvider.send` interface; no SMS
network integration is claimed.

## Verification

Executed verification:

- Full backend suite: **262 passed**, 50 existing FastAPI/Starlette deprecation
  warnings, 61.78 seconds, guarded isolated PostgreSQL CI database.
- Flutter suite: **125 passed**, 9 seconds in the final run. `flutter analyze`
  reported **No issues found** (5.1 seconds). Dart formatting checked **239 files,
  zero changes** (1.06 seconds).
- Actual emulator bank workflow: **1 integration test passed**, 95 seconds after
  build/install. Real admin draft/save/publish; fixed external identity; three
  OTP/username/password registrations for NBE, CIB and Banque Misr; then normal
  selected-bank logins NBE → CIB → Banque Misr → NBE. Every authenticated profile
  and primary theme matched its server bank. Account/card/profile navigation,
  Arabic RTL, dark mode and restoring QA defaults also passed. Nine screenshots
  are in `screenshots/banking_app/2026-10-28` and were visually inspected.
- Existing real-API security workflow: **1 integration test passed**, 47 seconds
  after build/install. Registration/username suggestions, reviewed transfer,
  password authorization and token copy, committed simulated receipt, profile
  update request, password change/session revocation and subsequent login passed.
  No persistent demo customer's password or balance was changed by these tests.
- Real local-demo health, existing customer/admin logins, profile/accounts/cards/
  transfer-options reads and protected admin endpoints passed; ordinary customer
  access to the admin dashboard returned 403. Demo publication remains version 0.
- Migration preserved original row digests for all 40 existing tables; the local
  migration command was re-run successfully at head. Provisioning repeated
  without changing existing rows or adding duplicates. Catalogue regeneration
  check passed for all 37 presets and their accessible palette constraints.

Earlier emulator attempts failed with Windows-native QEMU access violations
`0xc0000005`. The completed runs used the existing normal Medium_Phone emulator
with host graphics, snapshots/Vulkan disabled and the **test-only**
`--no-enable-impeller` flag. No native application rendering policy was changed.
An earlier security run also exposed a missing username setup in the isolated QA
fixture; it now reuses the existing idempotent username initializer. No schema or
password was reset to make that test pass.

Final normal builds succeeded:

- Debug APK: `frontend/faisal_app/build/app/outputs/flutter-apk/app-debug.apk`,
  **1.1.0+2**, 197,479,205 bytes. SHA-256:
  `396d9e3bdfb200c47073c66c86c45a9d3ac97646b6d6d211c5d7d3291500bab2`.
  The normal APK was installed and launched on emulator-5554 against the existing
  demo API 8011; native package inspection confirmed versionName 1.1.0 and
  versionCode 2. Its startup screenshot is `10_normal_apk_start.png`.
- The APK contains the exact generated logo master and offline bank catalogue;
  no one-use QA credential file was packaged. The logo SHA-256 is
  `44172b2073cff7921d889f28f8ccf2265f698691f3462487a64d6372908b3c54`.
- Debug web build succeeded in **46.8 seconds**, including a successful Wasm
  dry-run informational message. The existing local server at
  **http://127.0.0.1:8080** now serves the new build. HTTP checks verified the
  Banking App document title and exact JavaScript/logo/catalogue build bytes.
  JavaScript SHA-256:
  `6c46c69b046e2e717e78a017bf524e8b16b13edaefb66e68301ff4c5aa615725`.
  Browser-specific interactive flows were not independently automated in this
  run; the Flutter UI workflows above were executed on Android.

The normal APK keeps the application's existing rendering policy; the Skia flag
used for emulator integration runs is not a production configuration change.
Physical phone/biometric and iOS device verification were not repeated for this
branding increment. Real OTP provider delivery still awaits external credentials.

See `BANKING_APP_CHANGED_FILES.txt` for every added/modified source/resource.

## Native and integration limitations

One issuer bank per username/customer identity is supported in this increment;
multiple usernames for one person's different banks work on the same app. Linking
several real bank identities to one person requires actual issuer integrations,
verified bank-side identity mapping and a separate product/security design.
All balances, cards, OTP contacts and payment movements remain fictional local
development fixtures. Catalogue inclusion does not make arbitrary real cards
registrable. Card numbers must already be provisioned in this backend.

The supplied 44-address directory and hotline belong to Faisal only. A service
bank selector keeps that directory correctly labeled. Other banks open their
official websites instead of invented addresses/hotlines. No external financial
network has been connected.

Android API/emulator verification is available on Windows. iOS native resources
were updated, but an iOS build/device test requires macOS/Xcode and is unverified.
No remote native icon switching or arbitrary launcher renaming was added.

## Public identity sources

Reviewed against [CBE IPN participants](https://www.cbe.org.eg/en/payment-systems-and-services/instant-payment-network),
[Standard Chartered Egypt](https://www.sc.com/eg/),
[onebank](https://www.onebank.eg/?c=en),
[KFH Egypt identity announcement](https://www.kfh.com/en/home/Personal/news/2025/KFH-Egypt-Unveils-New-Identity.html),
and [QNB Egypt](https://www.qnb.com.eg/sites/qnb/qnbegypt/page/en/enoverview.html).
Public official website/CSS checks informed the presets, including
[Banque Misr](https://www.banquemisr.com/), [BANK NXT](https://www.banknxteg.com/),
[onebank's official logo](https://www.onebank.eg/resources/img/logo_onebank.svg),
and [CIB's blue/orange material](https://www.cibeg.com/-/media/project/downloads/business/business-online/botf-guides-en.pdf).
Unreachable pages did not result in downloading or executing untrusted assets.
