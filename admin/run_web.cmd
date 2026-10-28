@echo off
setlocal
pushd "%~dp0..\frontend\faisal_app"
"..\..\backend\.venv\Scripts\python.exe" "..\..\admin\check_local_web.py"
if errorlevel 2 (
  echo Port 8080 belongs to another service. Close it or choose another web port manually.
  popd
  exit /b 2
)
if not errorlevel 1 (
  echo Bank web app already running: http://127.0.0.1:8080
  call :open_bank_web
  if errorlevel 1 (
    popd
    exit /b 1
  )
  popd
  exit /b 0
)
where flutter >nul 2>nul
if errorlevel 1 (
  echo Add the Flutter SDK bin directory to PATH.
  popd
  exit /b 1
)
call flutter run -d edge --web-hostname=127.0.0.1 --web-port=8080 --dart-define=API_BASE_URL=http://127.0.0.1:8011/api/v1
set bank_exit=%errorlevel%
popd
exit /b %bank_exit%

:open_bank_web
echo Opening the bank web app in Edge...
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --new-window "http://127.0.0.1:8080"
  if errorlevel 1 (
    echo Could not open Edge. Open http://127.0.0.1:8080 manually.
    exit /b 1
  )
  exit /b 0
)
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" --new-window "http://127.0.0.1:8080"
  if errorlevel 1 (
    echo Could not open Edge. Open http://127.0.0.1:8080 manually.
    exit /b 1
  )
  exit /b 0
)
start "" "microsoft-edge:http://127.0.0.1:8080"
if errorlevel 1 (
  echo Could not open Edge. Open http://127.0.0.1:8080 manually.
  exit /b 1
)
exit /b 0
