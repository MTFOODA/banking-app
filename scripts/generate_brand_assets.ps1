#requires -version 5.1
<#
.SYNOPSIS
    Derives every launcher icon, splash image and web icon from the repository's
    existing logo artwork.

.DESCRIPTION
    `logo.jpg` in the repository root is the single source of truth. This script
    only rescales it (high-quality bicubic, aspect ratio preserved, centred on a
    canvas). The artwork is never redrawn, recoloured, stretched or cropped.

    Outputs:
      * frontend/faisal_app/assets/branding/logo.jpg + logo.png (Flutter UI)
      * android/app/src/main/res/mipmap-*/ic_launcher.png (+ round + adaptive
        foreground, and mipmap-anydpi-v26 adaptive icon XML)
      * android/app/src/main/res/drawable-*/splash_logo.png (splash screen)
      * ios AppIcon set
      * web favicon + PWA icons

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\generate_brand_assets.ps1
#>
[CmdletBinding()]
param(
    [string]$Source,
    [string]$FlutterApp
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Source) { $Source = Join-Path $repoRoot 'logo.jpg' }
if (-not $FlutterApp) { $FlutterApp = Join-Path $repoRoot 'frontend\faisal_app' }

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Logo artwork not found: $Source"
}

$image = [System.Drawing.Image]::FromFile($Source)
$generated = New-Object System.Collections.Generic.List[string]
$white = [System.Drawing.Color]::White

function New-LogoBitmap {
    param(
        [int]$Size,
        [double]$Scale,
        [bool]$Transparent,
        [System.Drawing.Color]$Background
    )

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

        if ($Transparent) {
            $graphics.Clear([System.Drawing.Color]::Transparent)
        }
        else {
            $graphics.Clear($Background)
        }

        $target = [double]$Size * $Scale
        $ratio = [Math]::Min($target / $image.Width, $target / $image.Height)
        $width = [int][Math]::Round($image.Width * $ratio)
        $height = [int][Math]::Round($image.Height * $ratio)
        $x = [int][Math]::Round(($Size - $width) / 2)
        $y = [int][Math]::Round(($Size - $height) / 2)

        $destination = New-Object System.Drawing.Rectangle $x, $y, $width, $height
        $graphics.DrawImage($image, $destination)
    }
    finally {
        $graphics.Dispose()
    }
    return $bitmap
}

function Save-Png {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path
    )
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $Bitmap.Dispose()
    $script:generated.Add($Path)
}

function Write-Logo {
    param(
        [string]$Path,
        [int]$Size,
        [double]$Scale = 1.0,
        [bool]$Transparent = $false,
        [System.Drawing.Color]$Background = [System.Drawing.Color]::White
    )
    $bitmap = New-LogoBitmap -Size $Size -Scale $Scale -Transparent $Transparent -Background $Background
    Save-Png -Bitmap $bitmap -Path $Path
}

$resRoot = Join-Path $FlutterApp 'android\app\src\main\res'

# --- 1. Flutter UI branding (bundled asset) --------------------------------
$brandingDir = Join-Path $FlutterApp 'assets\branding'
Copy-Item -LiteralPath $Source -Destination (Join-Path $brandingDir 'logo.jpg') -Force
$generated.Add((Join-Path $brandingDir 'logo.jpg'))
Write-Logo -Path (Join-Path $brandingDir 'logo.png') -Size 512

# --- 2. Android launcher icons (legacy, round, adaptive foreground) --------
$launcherSizes = [ordered]@{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
foreach ($density in $launcherSizes.Keys) {
    $size = $launcherSizes[$density]
    $folder = Join-Path $resRoot "mipmap-$density"
    Write-Logo -Path (Join-Path $folder 'ic_launcher.png') -Size $size
    Write-Logo -Path (Join-Path $folder 'ic_launcher_round.png') -Size $size
}

# Adaptive icons: 108dp canvas; artwork inset so the mark stays inside the
# 66dp safe zone and is never clipped by an OEM mask.
$adaptiveSizes = [ordered]@{ mdpi = 108; hdpi = 162; xhdpi = 216; xxhdpi = 324; xxxhdpi = 432 }
foreach ($density in $adaptiveSizes.Keys) {
    $size = $adaptiveSizes[$density]
    $folder = Join-Path $resRoot "mipmap-$density"
    Write-Logo -Path (Join-Path $folder 'ic_launcher_foreground.png') -Size $size -Scale 0.66 -Transparent $true
}

# --- 3. Splash screen logo (centred, never stretched) ----------------------
$splashSizes = [ordered]@{ mdpi = 96; hdpi = 144; xhdpi = 192; xxhdpi = 288; xxxhdpi = 384 }
foreach ($density in $splashSizes.Keys) {
    $size = $splashSizes[$density]
    Write-Logo -Path (Join-Path $resRoot "drawable-$density\splash_logo.png") -Size $size
}


# --- 4. Web / PWA icons ----------------------------------------------------
$webDir = Join-Path $FlutterApp 'web'
Write-Logo -Path (Join-Path $webDir 'favicon.png') -Size 32
Write-Logo -Path (Join-Path $webDir 'icons\Icon-192.png') -Size 192
Write-Logo -Path (Join-Path $webDir 'icons\Icon-512.png') -Size 512
Write-Logo -Path (Join-Path $webDir 'icons\Icon-maskable-192.png') -Size 192 -Scale 0.8
Write-Logo -Path (Join-Path $webDir 'icons\Icon-maskable-512.png') -Size 512 -Scale 0.8

# --- 5. iOS app icons (opaque - the App Store rejects alpha) ---------------
$iosIconDir = Join-Path $FlutterApp 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
$iosIcons = [ordered]@{
    'Icon-App-20x20@1x.png'     = 20
    'Icon-App-20x20@2x.png'     = 40
    'Icon-App-20x20@3x.png'     = 60
    'Icon-App-29x29@1x.png'     = 29
    'Icon-App-29x29@2x.png'     = 58
    'Icon-App-29x29@3x.png'     = 87
    'Icon-App-40x40@1x.png'     = 40
    'Icon-App-40x40@2x.png'     = 80
    'Icon-App-40x40@3x.png'     = 120
    'Icon-App-60x60@2x.png'     = 120
    'Icon-App-60x60@3x.png'     = 180
    'Icon-App-76x76@1x.png'     = 76
    'Icon-App-76x76@2x.png'     = 152
    'Icon-App-83.5x83.5@2x.png' = 167
    'Icon-App-1024x1024@1x.png' = 1024
}
foreach ($name in $iosIcons.Keys) {
    Write-Logo -Path (Join-Path $iosIconDir $name) -Size $iosIcons[$name]
}

$sourceWidth = $image.Width
$sourceHeight = $image.Height
$image.Dispose()

Write-Output "source=$Source"
Write-Output "source_pixels=${sourceWidth}x${sourceHeight}"
Write-Output "generated_count=$($generated.Count)"
foreach ($path in $generated) {
    Write-Output "generated=$($path.Replace($repoRoot + [IO.Path]::DirectorySeparatorChar, ''))"
}
