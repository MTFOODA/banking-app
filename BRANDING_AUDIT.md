# Branding audit — 2026-10-27

Inspected before implementation: backend models, current schema and migration head,
FastAPI routers/services/RBAC, uploads/audit helpers, Flutter features, DI, router,
theme components/extensions, preferences, logos/names/colors, localization, assets,
Android/iOS manifests, dependencies, unit/integration tests and build commands.

* Backend: FastAPI → services → SQLAlchemy 2 → PostgreSQL. Existing JWT session and
  permission dependencies must remain unchanged. File uploads already use local
  `settings.upload_dir`; no object storage, general configuration store or push
  subscription service exists.
* Local demo DB: `faisal_bank_test`, migration `ab71e439d205`, 39 tables. Read-only
  baseline: 16 users, 27 accounts, 18 cards, 86 transactions, 102 entries, 16
  preferences, 1 announcement. No branding/configuration table exists.
* Flutter: feature layers, Repository contracts, DioClient, GetIt, BLoC/Cubit,
  GoRouter. LanguageCubit/ThemeCubit persist local preferences. Branding must not
  change route identity, AuthBloc, session storage or existing appearance choices.
* Default branding: `core/theme/{app_theme,app_theme_components,app_theme_extras,
  app_colors,faisal_palette}.dart`; `core/widgets/faisal_logo.dart`; bundled
  `assets/branding/logo.png`; app names in logo, home header, route error and
  localized title. Product card artwork deliberately has fixed identity colors.
  Login uses FaisalGradients. No custom TTF/OTF assets are declared.
* Native Android label/icon and iOS display name/icon/launch screen are build
  resources. No existing aliases or alternate icons. Leave native files alone;
  display a release requirement, not remote launcher controls.
* Baseline executed: Flutter 101 tests passed; analyze: no issues. Backend suite
  runs only in guarded `_ci_test`, with rollback fixtures, separately from demo.
* Compatibility risks: invalid/low-contrast palettes, unavailable Arabic fonts,
  text overflow, stale simultaneous saves, unsafe image URLs/files, startup
  blocking and rebuilding navigation. Keep original ThemeData path exactly when
  customization is disabled; validate both modes; bound scale; bundle licensed
  fonts; use version checks, row locking, immutable publications and safe raster
  uploads. Never overwrite original assets.
* Implementation: additive singleton settings + publication history tables,
  existing admin-content permission, private draft APIs/assets and public active
  configuration; cache/version-based conditional retrieval; existing Cubit and
  SharedPreferences; scoped editor preview; explicit save/publish/restore. Refresh
  at startup/resume and allow manual refresh, without recurring polling. No
  deployment or publication of a custom configuration is part of implementation.

Native references: [Android aliases](https://developer.android.com/guide/topics/manifest/activity-alias-element),
[Apple alternate icons](https://developer.apple.com/documentation/uikit/uiapplication/setalternateiconname(_:completionhandler:)).
