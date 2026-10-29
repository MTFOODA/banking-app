# Bank-aware entry and public services — 2026-10-29

This report supersedes the fixed **in-app** Banking App identity and sign-in entry described in BANKING_APP_REPORT.md. Native launcher branding remains unchanged. Version: **1.2.0+3**.

## Findings and implementation

The old entry screen had optional bank selection, and login still advertised card/account identifiers. Only Faisal had a bundled branch list; other banks opened a website. A bank theme was applied only after authentication, while the compiled app wordmark remained visible.

The existing Clean Architecture, Dio client, GetIt, GoRouter and BLoC/Cubit architecture is preserved. There are now two introduction pages followed by a searchable bank grid. Selecting a bank opens the username/password form directly, with branches, ATMs, customer service and public announcements below it. The selection persists locally. Changing banks closes the old login page and clears its form.

Official artwork for all 37 catalogue banks is bundled with HTTPS provenance and SHA-256 in backend/app/data/bank_public_assets.json. Sources are bank websites or official bank-published app listings. SVG CSS presentation rules are flattened to attributes for Flutter compatibility, retaining original path geometry and bank colors. Arabic names use Arabic lettering plus a common abbreviation in parentheses. Thirty-five retail banks are selectable; existing corporate-only restrictions remain.

The selected bank scopes pre-login appearance. After login or during mandatory password setup, the backend profile owns bank affiliation and overrides local preferences. Customer screens, logos and wordmarks use that affiliation. Existing per-bank admin appearance publications remain supported; administrators cannot replace bank identities or native launcher branding.

Flutter sends identifier_type=username through the existing login endpoint. That additive contract resolves only the existing username hash and retains password, lockout, JWT, first-login and role enforcement. Legacy API clients retain the existing card/account login contract. Self-registration uses the selected bank and card-only lookup, then the existing OTP, username suggestions and password creation flow. No passwords were reset.

Public notices reuse AnnouncementAudience with the existing string fields: bank audiences are validated, public bank reads include only general notices and notices addressed to that bank, and authenticated reads use the server profile. Private audiences remain excluded before login. Admins can choose a bank when creating/editing a public notice; existing general notices remain general.

## Directories and coverage

GET /api/v1/banks/{bank_code}/directory returns reviewed public data with a version and conditional unchanged response. It never accesses customer information or fetches a client-supplied URL. The existing Flutter directory repository/controller now supports bank/type isolation, bundled offline snapshots, cached updates, search, governorate filters and lazy lists for large networks. Failed refreshes retain the last valid snapshot. Map links use reviewed coordinates when credible, otherwise the full bank/address search. Rounded placeholders and obvious wrong-city pins are not presented as precise destinations.

Faisal's original 44 branches, second-position Giza administrative building and Dokki correction are retained. Branch and ATM lists are separate. Counts are snapshots, not claims of live full-network completeness.

| Bank code | Branches | ATMs | Branch / ATM coverage |
|---|---:|---:|---|
| nbe | 273 | 0 | partial / unavailable |
| banque_misr | 788 | 4609 | published / published |
| faisal | 44 | 308 | published / published |
| banque_caire | 0 | 499 | unavailable / published |
| aib | 26 | 0 | published / unavailable |
| albaraka | 47 | 252 | published / published |
| adib | 31 | 80 | published / published |
| suez_canal | 56 | 182 | published / published |
| kfh | 47 | 102 | published / partial |
| adcb | 50 | 221 | published / published |
| fab | 75 | 204 | published / published |
| credit_agricole | 84 | 529 | published / published |
| mashreq | 14 | 45 | published / published |
| bank_nxt | 38 | 153 | published / published |

Totals: 1573 branch entries and 7184 ATM entries across 14 banks. Verified customer service numbers: 19/37.

**Remaining coverage:** 23 banks have no verified imported address list yet: cib, qnb, aaib, arab_bank, alexbank, egbank, saib, ebank, attijariwafa, abk, hdb, nbk, ealbank, united_bank, hsbc, citi, emirates_nbd, abc, midbank, idb, agricultural, standard_chartered, onebank. Their screens explicitly report that limitation and provide an official bank link; Faisal locations or hotline are never substituted. Some official sources block automated access. NBE's 273 branches are the bank's published accessibility subset, and KFH's ATM table is offsite ATMs only. The UI labels these as partial. Live openings, closures and machine availability cannot be guaranteed by a reviewed snapshot.

Public source links and review dates accompany the snapshots. `scripts/build_bank_directories.py --sources <reviewed-response-folder>` compiles/validates reviewed sources, preserves prior valid data on failed imports and writes snapshots atomically. The original public responses are temporary research inputs, not application assets or customer data. `scripts/sync_bank_public_assets.py --plan backend/app/data/bank_public_assets.json` refreshes reviewed logo sources, and `scripts/build_bank_catalogue.py --check` verifies generated catalogue consistency.

## Database preservation

No new database schema change or migration is required. Existing bank affiliation migration history remains intact. Bank-targeted notices reuse existing audience columns. Public directory files contain no credentials or customer data.

Read-only before/after digests confirmed unchanged persistent demo credentials and business records: 20 users' credential/enrollment fields, 19 customer profiles, 35 accounts, 22 cards, 94 transactions, 118 ledger entries, 5 beneficiaries, 5 repayments and 6 investment holdings. QA registration created only fresh fictional customers in banking_app_qa_test; it did not consume persistent demo registration fixtures. No database reset or destructive cleanup was used against the demo database.

## Actual verification

- Backend regression suite: **310 tests passed**; isolated guarded *_ci_test database only.
- Flutter suite: 133 tests passed, including EN/AR, light/dark, RTL, direct bank entry, services, offline directories and all official artwork assets.
- flutter analyze: no issues found.
- Dart formatting: **246 files checked, zero changes**.
- Real emulator integration: **passed** on emulator-5554. Fresh card → visible development OTP → unique username/password → home for NBE, CIB and Banque Misr; subsequent username login for all three; bank-specific home identity; Misr branch search; Arabic RTL/dark appearance. Execution took 58 seconds after the integration APK build. Six non-secret screenshots were captured. No password, OTP or authorization token was printed or captured in those screenshots.
- Normal debug APK: built and installed, application launched and left open on the emulator using the preserved local API on port 8011. See final artifact metadata below.
- Main backend health, actual development-admin username login, staff permissions, protected dashboard, anonymous rejection and logout: passed using the ignored credential file.
- Native icon/name changes: none. Android/iOS launcher changes still require a release. Device biometric interaction and iOS builds were not rerun for this appearance/entry change.
- Legacy integration helpers were updated for bank selection; the newly executed native target is bank_entry_registration_test.dart. Existing security and admin behavior was covered by the backend/Flutter regression suites.

## Local run and test commands

From the project root, use two terminals:

```powershell
.\admin\start_server.cmd
.\admin\run_web.cmd
```

For Android emulator:

```powershell
cd frontend/faisal_app
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8011/api/v1
dart format --output=none --set-exit-if-changed lib test integration_test
```

Backend suite, from backend:

```powershell
$env:DEBUG='false'
.venv/Scripts/python.exe -m pytest
```

Opt-in native registration QA, from backend, in a dedicated terminal:

```powershell
$env:DEBUG='false'
$env:RUN_BRANDING_QA='1'
.venv/Scripts/python.exe serve_branding_qa.py
```

Then from the project root, with a debug app installed on emulator-5554:

```powershell
backend/.venv/Scripts/python.exe scripts/run_branding_emulator.py --flow entry
```

The runner stages private QA fixture data through run-as and does not compile passwords into Dart defines. Integration testing removes its test application afterwards; reinstall/run the normal app to continue manual use. Persistent development credentials and current admin username/password remain only in ignored admin/admin.txt. Admin initialization/recovery remains documented in admin/README.txt.

For new manual registration fixtures, use a **new** alphanumeric batch label (same labels never reset enrolled users):

```powershell
backend/.venv/Scripts/python.exe admin/initialize_registration_customers.py --batch ManualNew29 --count 2 --bank nbe
```

Choose the matching bank, use the fictional card from admin/admin.txt, verify the development code displayed below the OTP form, then create a unique username and password. OTP exposure is explicitly dev/test only. Real SMS/email credentials and real bank network integrations remain unconfigured; the development adapter says that no message was sent. Production keeps HTTPS/session/security policies and never exposes the OTP.

## Final artifact and delivery

Final verification: backend 310 passed (50 dependency deprecation warnings), Flutter 133 passed, analysis clean, formatting 246 files/zero changes, Android debug APK and JavaScript debug web build successful. The Wasm dry run succeeded; a Wasm bundle and iOS build were not produced. The SVG renderer prints a harmless diagnostic for empty definitions in some official artwork; all 37 assets render in tests and colors/path geometry are verified.

The normal APK is installed and open on emulator-5554. The local web app is available at http://127.0.0.1:8080, and its served JavaScript SHA-256 matches the current build. Main API health and actual development admin login were verified on port 8011. The existing credentials and business table digests still match the baseline.
 All source/resource changes are enumerated in BANK_ENTRY_CHANGED_FILES.txt. Native identity assets and existing data remain preserved. No live branding publication, production deployment or main-branch merge was performed.

- APK: `frontend/faisal_app/build/app/outputs/flutter-apk/app-debug.apk` (200960028 bytes).
- APK SHA-256: `8e60fcc5eabd250675ef7e6a1297d9260054cd5700803897554f1e08b7407bd0`.
- Web JavaScript SHA-256: `a942da97104d70db129fa2c6daa510d3f7078677f7ea3136d57dbdc5f1a1e476`.
- Screenshots: `screenshots/bank_entry/2026-10-29` (7 PNG files, including the normal app left running).
- Source delivery target: `https://github.com/MTFOODA/banking-app`, branch `feature/dynamic-branding-20261028`; main remains untouched.
