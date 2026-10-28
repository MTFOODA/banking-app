@echo off
rem Builds the debug APK from a clean build directory and writes a log.
rem Run detached (scripts\start_apk_build.ps1) so terminal polling cannot
rem interrupt the Kotlin/Gradle daemons.
setlocal
set "REPO_ROOT=%~dp0.."
cd /d "%REPO_ROOT%\frontend\faisal_app" || exit /b 1

call android\gradlew.bat --stop > "%REPO_ROOT%\_gradle_stop.log" 2>&1
if exist build rmdir /s /q build

call flutter build apk --debug > "%REPO_ROOT%\_apkbuild.log" 2>&1
set "APK_EXIT=%errorlevel%"
echo apk_exit=%APK_EXIT%>> "%REPO_ROOT%\_apkbuild.log"

if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo apk_path=build\app\outputs\flutter-apk\app-debug.apk>> "%REPO_ROOT%\_apkbuild.log"
) else (
    echo apk_path=missing>> "%REPO_ROOT%\_apkbuild.log"
)

endlocal & exit /b %APK_EXIT%
