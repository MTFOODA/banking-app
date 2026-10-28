@echo off
setlocal
pushd "%~dp0..\backend"
set DEBUG=false
set INTEGRATION_PORT=8011
set INTEGRATION_DATABASE_URL=
".venv\Scripts\python.exe" -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8011/health', timeout=3)" >nul 2>nul
if not errorlevel 1 (
  echo Demo API already running: http://127.0.0.1:8011
  popd
  exit /b 0
)
".venv\Scripts\python.exe" serve_integration.py
set bank_exit=%errorlevel%
popd
exit /b %bank_exit%
