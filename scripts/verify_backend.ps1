#requires -version 5.1
<#
.SYNOPSIS
    Starts the Faisal App backend, runs the live API verification and stops it.

.DESCRIPTION
    Boots uvicorn on a loopback port, waits for /health, executes
    backend/_verify_api.py (health, admin login, wrong-password rejection and one
    authenticated endpoint), then always stops the server process.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify_backend.ps1
#>
[CmdletBinding()]
param(
    [int]$Port = 8010,
    [string]$Python,
    [string]$BackendDir
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $BackendDir) { $BackendDir = Join-Path $repoRoot 'backend' }
if (-not $Python) { $Python = Join-Path $BackendDir '.venv\Scripts\python.exe' }

if (-not (Test-Path -LiteralPath $Python)) {
    throw "Python interpreter not found: $Python"
}

$outLog = Join-Path $repoRoot '_uvicorn.out.log'
$errLog = Join-Path $repoRoot '_uvicorn.err.log'
$verifyLog = Join-Path $repoRoot '_backend_verify.log'

$server = Start-Process -FilePath $Python `
    -ArgumentList @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', "$Port") `
    -WorkingDirectory $BackendDir `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -PassThru -WindowStyle Hidden

try {
    $healthy = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Milliseconds 500
        if ($server.HasExited) { break }
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 3
            if ($response.StatusCode -eq 200) {
                $healthy = $true
                break
            }
        }
        catch {
            # Server is still starting.
        }
    }

    if (-not $healthy) {
        Write-Output 'health_endpoint=FAIL (server did not become healthy)'
        if (Test-Path -LiteralPath $errLog) {
            Get-Content -LiteralPath $errLog -Tail 40 | ForEach-Object { Write-Output "uvicorn: $_" }
        }
        exit 1
    }

    Push-Location $BackendDir
    try {
        & $Python '_verify_api.py' --base-url "http://127.0.0.1:$Port" | Tee-Object -FilePath $verifyLog
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    Write-Output "verify_exit=$exitCode"
    exit $exitCode
}
finally {
    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }
}
