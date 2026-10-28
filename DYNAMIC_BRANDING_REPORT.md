# Dynamic App Branding & Appearance ? delivery report

28 October 2026 ? fictional development environment.

## Architecture and preserved behavior

The initial audit is in [BRANDING_AUDIT.md](BRANDING_AUDIT.md). Existing feature
layers, DioClient, GetIt, BLoC/Cubit, GoRouter, localization, JWT/RBAC, user
appearance preferences and banking services are retained. No authentication,
transfer, registration, investment, card or profile service was replaced.
The original ThemeData path is returned when branding/typography customization
is disabled. Original logos/native resources are preserved.

New feature layers live in `lib/features/branding`: immutable domain contract,
repository, Dio implementation, public BrandingCubit, admin editor Cubit and
widgets. BrandingTheme combines the existing ThemeData, ColorScheme, TextTheme
and FaisalPalette extension. The same router and AuthBloc instances remain in
place during updates. Tests preserve an entered form and navigation stack and
verify unchanged configurations do not rebuild the application.

## Administrator controls

Dashboard ? Settings ? App Branding & Appearance. Uses the existing AdminFrame,
components and `admin.content.manage` permission. Includes display/short name,
welcome text, optional tagline, light/dark logo and in-app splash image; previews
and individual asset defaults; HEX plus HSV/preset picker; twelve color tokens
for each mode; bundled System/NotoSans/NotoSansArabic choices, language-specific
fonts, scale 0.90?1.15, heading/body weights and appearance policy. `user` retains
the existing customer/system theme choice. Fixed financial card artwork and
some intentionally sized widget styles are preserved.

Live preview is scoped to the editor, with its own light/dark selector. Save
Draft changes nothing for customers. Publish requires a saved, valid draft and
explicit confirmation. Defaults/history become drafts and require a separate
publish. Dirty edits are retained on failures/conflicts, and navigation/reload
asks before discarding unsaved editor work. History is cursor-paginated, 50 per
page. The native-branding section clearly says Requires New Application Release.

## Storage, migration and rollback

Additive migration `b317a90d66e1`, parent `ab71e439d205`, creates only:

* `branding_settings`: constrained singleton, revision counter, draft JSONB,
  active publication FK, update timestamp and acting-user FK.
* `branding_publications`: immutable API-managed version/config snapshots,
  timestamp and acting-user FK. No API allows deleting/editing history.

Applied successfully to the existing local `faisal_bank_test` used by port 8011.
Running upgrade a second time was a no-op. All **38 pre-existing non-migration
tables** had matching row counts and row-content digests before/after migration.
The demo still has **no custom publication (version 0)**. No production database,
credentials, customers, balances, card ownership or banking history were reset.

Normal migration for a separately selected DATABASE_URL, from `backend`:

```powershell
$env:DEBUG='false'
.\.venv\Scripts\python.exe -m alembic upgrade head
```

Choose the environment deliberately; the 8011 demo uses TEST_DATABASE_URL.
Operational rollback is Restore Defaults or Restore Version ? review ? Publish,
which creates a **new** monotonic version, never rewrites an earlier version.
Schema downgrade exists but was **not executed**: export branding history/assets
first, roll application code back, then explicitly downgrade to ab71e439d205.
That removes only the two new branding tables, never banking tables. Preserving
those tables while rolling code back is the safer backward-compatible option.

## API and security

Public GET `/api/v1/branding` exposes only a version and public-safe configuration.
`known_version` returns a small unchanged response when appropriate. Public
branding assets are readable only after inclusion in a published version;
historical assets remain readable for cached/rollback configurations.

All `/api/v1/admin/branding` reads/writes/history/private images enforce existing
staff RBAC and active-session requirements. Draft/history responses use no-store.
Writes validate strict schemas, plain bounded text, supported bundled fonts,
opaque HEX values and minimum 4.5:1 foreground/button contrast in both modes.
Arbitrary external, SVG, data or traversal asset URLs are rejected.

Uploads accept PNG/JPEG only, at most 2 MB, 16?4096 px per side and 4 megapixels.
Multipart body limits cover declared and streamed bodies. Pillow verifies and
re-encodes a single raster frame, strips metadata/trailing content and uses
SHA-256 names and atomic file replacement under the existing upload directory.
The existing PostgreSQL-backed limiter is reused across workers. Audit entries
record draft/publication/upload actions and actor/time without credentials.

SELECT FOR UPDATE serializes updates; expected revision checks reject stale
saves/publishes. Publication, active pointer, version increment, draft consumption
and audit record commit atomically. Tests prove one winner for concurrent
publishers, failed-publication rollback, missing-asset rejection and ordinary
customer/unprivileged-staff denial.

## Flutter synchronization and offline behavior

Validated cached settings load synchronously through SharedPreferences. Startup
and foreground resume fetch the latest published configuration without blocking
startup, with request coalescing and a 30-second resume debounce. Publishing in
the admin app forces an immediate refresh. Existing backend infrastructure has
no push service, so other foreground apps refresh on startup/resume rather than
receiving fabricated real-time notifications. There is no recurring polling.

Only valid monotonic snapshots replace the active configuration. Offline/error
responses retain the last valid snapshot; no cache falls back to the original
appearance. Immutable images use memory plus best-effort local preference cache,
with concurrent requests coalesced and stale image entries pruned. Failed
storage/download/decode uses original bundled artwork instead of a broken image.
Browser storage quotas/platform storage failure can prevent durable image
caching; banking still works with bundled fallback artwork.

Selected Noto fonts and original OFL licenses are bundled, not downloaded at
runtime. Sources: [Google Noto Sans](https://github.com/google/fonts/tree/main/ofl/notosans),
[Google Noto Sans Arabic](https://github.com/google/fonts/tree/main/ofl/notosansarabic).
In-app names, logo widget, home name, welcome text, route fallback title, shared
headers and in-app splash use the central configuration. Layouts/routes remain.

## Actual verification

* Baseline: backend 214 passed; Flutter 101 passed; analyzer clean.
* Final backend: **250 passed**, 48 pre-existing-category Starlette/422 deprecation
  warnings. Runs only in guarded `_ci_test`, with per-test rollback fixtures.
* Final Flutter: **115 passed**, including 14 new branding tests.
* `flutter analyze --no-pub`: **No issues found**.
* Dart formatting: **229 files, 0 changes** (checked before the final test-only
  dark-selector refinement, which was itself formatted and compiled on device).
* Real Android emulator workflow: **1 passed, 57 seconds** in the latest run.
  Actual password login, staff authorization, multipart logo upload, private
  preview/draft isolation, explicit UI publishing, live theme/name updates,
  English/Arabic bundled fonts, RTL, both app and preview dark mode, defaults,
  immutable-history restoration and final QA reset to defaults were verified.
* Normal APK built from **lib/main.dart**, debug, API 8011: **34.7 seconds**.
  Installed and launched successfully after the temporary test APK was removed
  by Flutter's integration cleanup. It requires normal sign-in again.
* Normal web compiled from **lib/main.dart**, debug, API 8011. Compiler exit **0**;
  optional Wasm dry-run success text on stderr was informational, not a failure.
  The existing local port 8080 files were refreshed without removing data.
* Live 8011 health/admin login/dashboard/branding/history: HTTP 200; anonymous
  admin: 401; web PATCH preflight: 200. Administrator password was not changed.
* APK and served web output were scanned: no current private administrator or QA
  password; normal APK has both fonts and no QA API URL.

APK: `frontend/faisal_app/build/app/outputs/flutter-apk/app-debug.apk`

Size: **232436887 bytes** ? SHA-256:
`bd9ca3e70ca0ae647506aa180049b4aa3b71ae1059f339635da55953ed51a3ec`

Actual, visually reviewed emulator screenshots:
[Saved private draft](screenshots/branding/2026-10-28/01_saved_draft_en.png),
[Published English](screenshots/branding/2026-10-28/02_published_en.png),
[Arabic dark preview/app](screenshots/branding/2026-10-28/03_ar_dark.png).

Existing regression suites cover legacy first login/authentication, registration
and OTP, ownership/RBAC, transfers/authorization/idempotency/concurrency,
profile/password flows, admin requests/announcements, cards, investments/FX,
seed idempotency/rollback and public portal navigation. Their passing results
are evidence of tested preservation, not a claim that every physical-device or
production-provider scenario was exercised.

## Native and deployment limitations

Android launcher name/icon and native splash remain build resources. Activity
aliases would need predefined, tested manifest entries; none were introduced.
iOS alternate icons require predefined bundle assets and supportsAlternateIcons;
arbitrary remote display names are unsupported. No manifest, native launcher or
Info.plist change was made. Web manifest/favicon are also build-time metadata.
See [Android aliases](https://developer.android.com/guide/topics/manifest/activity-alias-element)
and [Apple alternate icons](https://developer.apple.com/documentation/uikit/uiapplication/setalternateiconname(_:completionhandler:)).

iOS builds/device verification were not available on this Windows host. This
feature was tested on the Android emulator, not a physical phone. Native image
picker interaction and a new full browser branding workflow were not automated;
web compilation, API/CORS and shared Flutter widget behavior were verified.
Real-time push is not configured; documented lifecycle refresh is used.
For multiple API hosts, mount the existing upload directory on persistent shared
storage and back it up with the database. Local file storage is the existing
project mechanism; no cloud storage or production deployment is implied.

## Commands and isolated reproduction

Existing development instance, from project root, separate terminals:

```powershell
.\admin\start_server.cmd
.\admin\run_web.cmd
```

App: http://127.0.0.1:8080 ? API: http://127.0.0.1:8011/health

From frontend/faisal_app:

```powershell
flutter analyze --no-pub
flutter test --no-pub
dart format --output=none --set-exit-if-changed lib test integration_test
flutter build apk --debug --no-pub --target lib/main.dart --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
flutter build web --debug --no-pub --target lib/main.dart --dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1
```

From backend: install requirements-dev.txt, set DEBUG=false, run
`.venv/Scripts/python.exe -m pytest`. Tests require a separate `_ci_test` database.
For real emulator publishing QA, see admin/README.txt and the opt-in
`backend/serve_branding_qa.py` + `scripts/run_branding_emulator.py`. These use only
local `faisal_branding_qa_test` / API 8017, random ignored private credentials and
no resets. A debuggable app must be installed before staging the private fixture;
Flutter's test cleanup removes its test APK, so reinstall the normal APK after.

## Files and source delivery

Every added/modified file and purpose is listed in
[BRANDING_CHANGED_FILES.txt](BRANDING_CHANGED_FILES.txt). Local settings, .env,
admin credentials, database dumps, upload data, logs, caches and build outputs
are excluded from Git. Only reviewed fictional branding screenshots are included.

Requested repository: [MTFOODA/banking-app](https://github.com/MTFOODA/banking-app).
Delivery branch: [feature/dynamic-branding-20261028](https://github.com/MTFOODA/banking-app/tree/feature/dynamic-branding-20261028).
The original workspace was not a Git checkout; source delivery uses the separate
`.tmp/branding-publish` checkout to preserve remote history and local files.
Main is not force-pushed or merged, and no website/backend is deployed remotely.
