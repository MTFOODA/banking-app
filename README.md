# Faisal App — fictional banking development project

Flutter (mobile/web) + FastAPI + SQLAlchemy + PostgreSQL. All banking movements
are simulated. This project is not connected to a real bank or payment network.

## Local setup

Use Python 3.11+, PostgreSQL, and the Flutter SDK compatible with
`frontend/faisal_app/pubspec.yaml`. Install backend dependencies into a virtual
environment, copy `backend/.env.example` to `backend/.env`, and configure your
own local database and unique secrets. Never commit the `.env` or credentials.

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
$env:DEBUG='false'
.\.venv\Scripts\python.exe -m alembic upgrade head
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

In another terminal:

```powershell
cd frontend/faisal_app
flutter pub get
flutter run -d edge --web-hostname=127.0.0.1 --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Existing local demo installations use the separate test database/server at 8011:
run `admin/start_server.cmd`, then `admin/run_web.cmd` from the project root.
These scripts assume the local Python environment and database already exist.
See [admin/README.txt](admin/README.txt) and
[admin/RUN_COMMANDS.txt](admin/RUN_COMMANDS.txt) for initialization and fixtures.
Development OTPs are opt-in and visibly labeled; real SMS/email is not enabled
by the development adapter. Administrator credentials are initialized locally
through the existing CLI, never shipped with the repository.

## Dynamic branding

Authorized staff: **Dashboard → Settings → App Branding & Appearance**.
Save drafts, preview both appearance modes, then explicitly publish. Defaults
preserve the original theme. Restore defaults/history as drafts before publishing.
Launcher icons/names and native launch screens require a new native release.
See [BRANDING_AUDIT.md](BRANDING_AUDIT.md) and
[DYNAMIC_BRANDING_REPORT.md](DYNAMIC_BRANDING_REPORT.md).

## Verification

Backend tests require `pytest` and a **separate** PostgreSQL database whose name
ends in `_ci_test`, selected by `CI_TEST_DATABASE_URL`. Test fixtures rebuild only
that isolated schema and roll back per-test changes. Never point this at a
development or production database.
Install development requirements with `python -m pip install -r requirements-dev.txt`.

```powershell
cd backend
$env:DEBUG='false'
.\.venv\Scripts\python.exe -m pytest
```

```powershell
cd frontend/faisal_app
flutter analyze --no-pub
flutter test --no-pub
dart format --output=none --set-exit-if-changed lib test integration_test
flutter build apk --debug --target lib/main.dart --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
```

Release clients require an explicit HTTPS API_BASE_URL. Before production use,
configure HTTPS, production secrets, verified OTP delivery, backups, shared
upload storage and gateway rate limits. No deployment is performed by these
instructions. iOS builds require macOS/Xcode.
