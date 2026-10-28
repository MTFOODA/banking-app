FICTIONAL DEVELOPMENT BANK - ADMINISTRATION

MINIMAL LOCAL CREDENTIAL FILE
  admin/admin.txt contains only username, card number(s), verified known local
  password, account count, active certificate count and active fund count for
  every identity in the persistent phone database, plus one OTP explanation.
  Unenrolled identities choose their username and password after OTP. Unknown
  changed passwords are marked unavailable; export never resets credentials.
  Refresh this file without changing database records, from project root:
    $env:DEBUG = 'false'
    backend/.venv/Scripts/python.exe admin/export_demo_credentials.py
  The ignored credentials-source.local.json retains previously supplied local
  credentials for repeatable export. Never commit local credential files.
  OTP is random per request, not a fixed password: the opted-in development
  server shows it below the OTP form. Resend replaces it. No real SMS/email is
  sent by this adapter; production never returns development codes.

USERNAME / INVESTMENT CUSTOMER FIXTURES (25 October 2026)
  From project root:
    $env:DEBUG = 'false'
    backend/.venv/Scripts/python.exe admin/initialize_demo_customers.py
  This explicit local command assigns unique usernames to already enrolled
  identities in DATABASE_URL and TEST_DATABASE_URL, preserves credentials,
  roles and first-login requirements, and leaves unenrolled identities without
  a username so they choose it after OTP during registration.
  It adds two fictional funded investor customers through the existing secure
  subscription service: Mariam has 3Y, 4Y and Income; Tarek has 5Y, 7Y and Growth.
  Their starting cash is EGP 50,000 each; the subscribed amounts are actually
  debited with balanced ledger entries, leaving EGP 38,000 and EGP 47,000.
  Repeating setup does not debit again, recreate redeemed holdings, or reset a
  changed password. The complete seed rolls back if any subscription fails.
  Generated passwords live only in ignored admin/investor_credentials.local.json
  and the requested ignored admin/admin.txt. Never commit either file. If a
  password was changed or the private file lost, recover the identity explicitly;
  the script refuses to silently overwrite it.
  Customer navigation: Accounts > Accounts / Certificates / Investment funds.
  Investor usernames: mariaminvestor and tarekinvestor. Administrator username
  is shown in the private admin.txt, and does not grant roles by itself.

ALPHANUMERIC USERNAMES
  Usernames use 3-30 English letters and digits only, starting with a letter.
  Dots, underscores and other symbols are removed from existing local names by:
    $env:DEBUG = 'false'
    backend/.venv/Scripts/python.exe admin/normalize_usernames.py
  This updates both configured local databases and the private admin.txt.
  Name conflicts get a numeric suffix. Existing passwords, roles, sessions,
  account/card ownership and banking rows are preserved and checked before commit.
  No schema migration is required. Unenrolled customers still choose a name after OTP.

No administrator password belongs in source control, screenshots, logs or chat.
The existing development administrator is preserved by this implementation.
Bootstrap never replaces an existing password or grants roles to an existing
non-administrator. Initial passwords require the normal mandatory first-login
password setup before protected administrative endpoints can be used.

INITIALIZE (PowerShell, from project root)
  cd backend
  $env:DEBUG = 'false'
  .\.venv\Scripts\python.exe -m alembic upgrade head
  $env:DEMO_ADMIN_EMPLOYEE_NUMBER = 'EMP-DEV-ADMIN01'
  .\.venv\Scripts\python.exe -m app.cli bootstrap-admin

The CLI prompts without echoing for a temporary password. Use 12+ characters,
uppercase, lowercase, digit and special character; no triple repeated character.
Alternatively set DEMO_ADMIN_INITIAL_PASSWORD through your local secret manager
or a private backend/.env file (ignored). Avoid --password on the command line.
Do not replace the configured employee number just to recover an existing user.

ACCESS
  Transfer routes and delivery configuration: TRANSFER_TYPES_REPORT.md.
  Local API 8011 explicitly enables the development outbound simulation.
  Four outbound routes deduct fictional balances only; no real bank/wallet/
  InstaPay payment is sent. Default OUTBOUND_TRANSFER_PROVIDER is disabled.

  IMPORTANT: admin/admin.txt describes the persistent local demo database served
  by backend/serve_integration.py on port 8011. The separate development API on
  port 8000 uses DATABASE_URL and may have a different administrator password.
  Do not reset either administrator to compensate for using the wrong API.

  For the Android emulator, select the first VS Code Run configuration:
    Bank - emulator (admin/admin.txt database)
  It uses http://10.0.2.2:8011/api/v1, Android's emulator host alias (no LAN IP).
  Or from frontend/faisal_app:
    flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
  Start its backend from backend with DEBUG=false:
    .\.venv\Scripts\python.exe serve_integration.py
  Sign in with username devadmin and the current password in admin/admin.txt.

  For the SEPARATE development database API and operator bootstrap:
  .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
  API documentation: http://127.0.0.1:8000/docs
  POST /api/v1/auth/login with identifier=<employee number>, password=<temporary>
  POST /api/v1/auth/first-login/complete with Authorization: Bearer <setup_token>
    body: new_password and confirm_password
  Then use access_token with the Swagger Authorize button or your API client.
  GET /api/v1/admin/dashboard and GET /api/v1/admin/customers are protected by
  database-backed staff permissions. Ordinary customers receive HTTP 403.

ADMINISTRATIVE UI STATUS
Card categories update: see CARD_CATEGORIES_REPORT.md. Card issuance requests
now appear in the same queue. Approval rechecks ownership, currency, investment
account rules and verified age (Youth <21), then creates one pending-activation
card. Rejection requires the existing mandatory reason and issues no card.
Initialize missing fictional card/FX account products without overwriting rows:
  backend/.venv/Scripts/python.exe admin/initialize_card_catalogue.py

The Flutter /admin route provides an overview, a customer request queue and an
announcement library using the existing repositories, Cubits and permissions.
Sign in using the username in admin/admin.txt and its current password. Temporary
passwords still require mandatory first-login setup. The portal uses the shared
green/gold theme, English/Arabic, RTL, light/dark mode, retry and logout.

Request queue: search by reference, filter status, open details/history, then
explicitly confirm approval or rejection. Rejection requires a reason of at
least five non-whitespace characters. The server validates permission, locks the
request and applies the actual existing banking action; final decisions cannot
be repeated. Customer notifications and audit history record the result.

Announcements: create bilingual drafts, edit, publish or archive. Choose Home,
Before sign-in or Both, and a priority. Publishing requires confirmation.
Before-sign-in notices must target everyone: private customer/segment notices
cannot be published there. Only published, currently valid notices are shown;
the public API exposes a restricted content-only response. The pre-login page
always shows Sign in, Branches, ATMs and Call center cards, with public notices
below them. It remains visible when no notices are active.

Database migration: e4a61d02b980 adds announcement display_location; existing
announcements default to Home. See ADMIN_PORTAL_REPORT.md for test results and
screenshots/admin_portal/2026-10-26 for emulator captures.

LOCAL RECOVERY
On a trusted local development machine, use the existing operator CLI:
  .\.venv\Scripts\python.exe -m app.cli issue-reset-token --card-number <employee-number>
This displays a one-time recovery code once (30-minute lifetime). Do not log it.
POST /api/v1/auth/reset-password with card_number=<employee-number>,
reset_reference=<code>, new_password and confirm_password. Existing sessions are
revoked. This operator-assisted recovery is not a public admin provisioning API.
Do not run recovery against production without your bank's approved procedure.

VERIFICATION
  python -m pytest
Tests use only a separately named *_ci_test database, with rollback fixtures.
Default: TEST_DATABASE_URL database name without its _test suffix, followed by
_feature_ci_test (for example faisal_bank_feature_ci_test). Create that EMPTY
database once with your local PostgreSQL administrator. CI_TEST_DATABASE_URL may
override it; the _ci_test suffix is mandatory. Never point automated tests at
the persistent phone database holding admin/admin.txt fixtures.
Admin bootstrap, first-login setup, login, preserved credentials, dashboard access
and rejection of customers are tested there without resetting the real admin.

OWN-ACCOUNT FX UPDATE
See OWN_ACCOUNT_FX_REPORT.md for the current quote migration, configuration,
commands, native screenshots and validation. No existing password was changed.

PERMANENT PUBLIC PORTAL
See PUBLIC_PORTAL_REPORT.md for the branch workbook import, public service
routes, native link testing, screenshots and latest validation. No credentials
were changed by this update.

BRANCH DIRECTORY CORRECTIONS
branch_directory_overrides.json retains the approved Giza/Dokki labels, direct
official map pins and second-position Giza ordering when importing the workbook.
The original workbook and all customer/admin credentials remain unchanged.

CURRENT DEMO/WEB STARTUP AND FRESH REGISTRATION
Run admin/start_server.cmd and admin/run_web.cmd from the project root.
Web: http://127.0.0.1:8080 ; matching demo API: 8011.
All commands are in RUN_COMMANDS.txt and appended to ignored admin.txt.
NEW_REGISTRATION_USERS.txt contains four currently unenrolled fictional users.
They choose username/password after the development OTP; no real SMS/email.
Use initialize_registration_customers.py --batch NewUniqueLabel --count 4 to
prepare a later batch. Reusing a label never resets enrolled credentials.
See ADMIN_WEB_SETUP_REPORT.md for actual browser/emulator test results.


DYNAMIC APP BRANDING AND APPEARANCE
  Dashboard > Settings > App Branding & Appearance. Existing content-management
  permission is enforced on every editing, history and private-image endpoint.
  Save draft and preview first; Publish applies the SAVED draft explicitly.
  Defaults and history restore as drafts and require a separate publish action.
  No custom branding is automatically published by setup or migrations.
  Android/iOS launcher labels, icons and native splash screens require a release.
  Migration (run from backend):
    $env:DEBUG='false'
    .\.venv\Scripts\python.exe -m alembic upgrade head
  This uses DATABASE_URL; the existing demo uses its separate test database.
  Select the target deliberately. Never reset an existing database.
  Keep the branding upload directory on persistent shared storage when running
  multiple API workers/hosts; include it in backups with publication history.
  See DYNAMIC_BRANDING_REPORT.md and BRANDING_CHANGED_FILES.txt at project root.

  Optional isolated real-emulator test, from project root (local PostgreSQL only):
    $env:DEBUG='false'
    $env:RUN_BRANDING_QA='1'
    backend/.venv/Scripts/python.exe backend/serve_branding_qa.py
  In a second terminal, with emulator-5554 and a debug app already installed:
    backend/.venv/Scripts/python.exe scripts/run_branding_emulator.py
  Uses ONLY faisal_branding_qa_test on port 8017, random private fixture credentials
  in ignored .tmp, and screenshots/branding/manual. Existing credentials and
  persistent demo data are never reset. It refuses production/remote DB hosts.
