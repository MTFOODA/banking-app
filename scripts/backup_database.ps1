#requires -version 5.1
<#
.SYNOPSIS
    Creates a verified PostgreSQL backup of the Faisal App database.

.DESCRIPTION
    Reads DATABASE_URL from backend/.env (credentials are never printed), runs
    pg_dump in custom format and validates the artifact with pg_restore --list.

.PARAMETER EnvFile
    Environment file that contains DATABASE_URL. Defaults to backend/.env.

.PARAMETER OutputDir
    Directory that receives the .dump file. Defaults to <repo>/backups.

.PARAMETER PgBin
    Directory containing pg_dump.exe / pg_restore.exe.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\backup_database.ps1
#>
[CmdletBinding()]
param(
    [string]$EnvFile,
    [string]$OutputDir,
    [string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $EnvFile) { $EnvFile = Join-Path $repoRoot 'backend\.env' }
if (-not $OutputDir) { $OutputDir = Join-Path $repoRoot 'backups' }

if (-not (Test-Path -LiteralPath $EnvFile)) {
    throw "Environment file not found: $EnvFile"
}

$databaseUrl = $null
foreach ($line in Get-Content -LiteralPath $EnvFile) {
    if ($line -match '^\s*DATABASE_URL\s*=\s*(?<value>.+)$') {
        $databaseUrl = $Matches['value'].Trim()
        break
    }
}
if (-not $databaseUrl) {
    throw 'DATABASE_URL is missing from the environment file'
}

$pattern = '^postgresql\+(?<driver>[a-z0-9]+)://(?<user>[^:]+):(?<password>[^@]+)@(?<host>[^:/]+):(?<port>\d+)/(?<database>[^?]+)'
$match = [regex]::Match($databaseUrl, $pattern)
if (-not $match.Success) {
    throw 'DATABASE_URL is not a supported PostgreSQL connection URL'
}

$dbUser = $match.Groups['user'].Value
$dbPassword = $match.Groups['password'].Value
$dbHost = $match.Groups['host'].Value
$dbPort = $match.Groups['port'].Value
$dbName = $match.Groups['database'].Value

$pgDump = Join-Path $PgBin 'pg_dump.exe'
$pgRestore = Join-Path $PgBin 'pg_restore.exe'
foreach ($tool in @($pgDump, $pgRestore)) {
    if (-not (Test-Path -LiteralPath $tool)) {
        throw "Required PostgreSQL tool not found: $tool"
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$target = Join-Path $OutputDir ("{0}_pre_schema_recovery_{1}.dump" -f $dbName, $stamp)

$previousPassword = $env:PGPASSWORD
$env:PGPASSWORD = $dbPassword
try {
    & $pgDump --host $dbHost --port $dbPort --username $dbUser --dbname $dbName --format=custom --file $target
    if ($LASTEXITCODE -ne 0) {
        throw "pg_dump failed with exit code $LASTEXITCODE"
    }
}
finally {
    if ($null -eq $previousPassword) {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
    else {
        $env:PGPASSWORD = $previousPassword
    }
}

$item = Get-Item -LiteralPath $target
if ($item.Length -le 0) {
    throw "Backup artifact is empty: $target"
}

$toc = & $pgRestore --list $target
if ($LASTEXITCODE -ne 0) {
    throw "pg_restore could not read the backup artifact: $target"
}
$tocEntries = @($toc).Count
if ($tocEntries -le 0) {
    throw "Backup artifact has an empty table-of-contents: $target"
}

Write-Output "backup_path=$($item.FullName)"
Write-Output "backup_bytes=$($item.Length)"
Write-Output "backup_toc_entries=$tocEntries"
Write-Output 'backup_verified=true'
