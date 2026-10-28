#requires -version 5.1
<#
.SYNOPSIS
    Starts the debug APK build as a detached process.

.DESCRIPTION
    Gradle/Kotlin builds take several minutes. Running the build through this
    script keeps it independent of the interactive terminal, so inspecting logs
    or running other commands cannot interrupt the compiler daemons mid-build.

    Progress: Get-Content <repo>\_apkbuild.log -Tail 20 -Wait
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$buildScript = Join-Path $PSScriptRoot 'build_apk.cmd'
$log = Join-Path $repoRoot '_apkbuild.log'

if (-not (Test-Path -LiteralPath $buildScript)) {
    throw "Build script not found: $buildScript"
}

if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }

$process = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList @('/c', "`"$buildScript`"") `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden `
    -PassThru

Write-Output "build_pid=$($process.Id)"
Write-Output "build_log=$log"
Write-Output 'build_started=true'
