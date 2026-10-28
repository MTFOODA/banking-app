# Faisal development banking app

The six transfer routes, simulation policy, migration and latest normal APK are
documented in `../../TRANSFER_TYPES_REPORT.md`.

Cards now include a six-category application catalogue with bank approval;
see `../../CARD_CATEGORIES_REPORT.md` for account/age/currency rules and tests.

For the demo identities listed in `../../admin/admin.txt`, start
`backend/serve_integration.py` from the backend directory with `DEBUG=false`.
This uses the persistent configured demo database on port **8011**.

Run from this directory on the Android emulator:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
```

Or select **Bank - emulator (admin/admin.txt database)** in the root VS Code
Run configuration. `10.0.2.2` is Android's emulator host alias and requires no
Wi-Fi address or USB reverse. The administrator username is `devadmin`; its
current local password is in the ignored credentials file.

The separate default development API on port 8000 uses `DATABASE_URL` and can
have different credentials. Use the matching database instead of resetting an
administrator to compensate for an endpoint mismatch.

For a physical phone, configure your own reachable endpoint or use
`adb reverse tcp:8011 tcp:8011` with
`--dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1`.
Release builds require an explicit HTTPS `API_BASE_URL`.

See `../../admin/README.txt` for initialization/recovery and
`../../ADMIN_PORTAL_REPORT.md` for workflow and test results.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Own-account currency conversion

Only transfers between the signed-in customer's own accounts support conversion.
Review freezes the indicative simulated rate, credit and expiry before password
authorization. Other transfer routes retain their source-currency policy.
See [implementation and executed tests](../../OWN_ACCOUNT_FX_REPORT.md).

## Permanent public landing page

Signed-out startup always opens the public portal with Sign in, Branches, ATMs
and Call center. Public announcements appear below the cards. The branch
directory is bundled offline from the supplied workbook, with search and map
links. See [executed checks and native screenshots](../../PUBLIC_PORTAL_REPORT.md).

## Web and admin login

Debug platform defaults now use the persistent demo API on 8011, matching
admin/admin.txt. From the root, run admin/start_server.cmd then admin/run_web.cmd
and open http://127.0.0.1:8080. The installed Edge browser is used by the launcher
and the Bank - web VS Code configuration. Port 8000 remains a separate database.
No administrator password was reset. See ../../ADMIN_WEB_SETUP_REPORT.md.
