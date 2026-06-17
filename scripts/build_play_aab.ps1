# Build AAB for Google Play Internal testing.
# Flutter post-check (apkanalyzer) may fail on Windows - Gradle output is valid.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$android = Join-Path $root "android"
$keyProps = Join-Path $android "key.properties"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

if (-not (Test-Path $keyProps)) {
    Write-Host "No upload keystore - creating one..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "create_upload_keystore.ps1")
}

# Gradle-only builds do not refresh flutter.version* in local.properties - sync from pubspec.yaml.
$pubspec = Join-Path $root "pubspec.yaml"
$versionLine = (Select-String -Path $pubspec -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$versionName, $versionCode = $versionLine -split '\+', 2
$localProps = Join-Path $android "local.properties"
$props = Get-Content $localProps -ErrorAction SilentlyContinue
if (-not $props) { throw "Missing android/local.properties - run flutter pub get once." }
$props = $props | Where-Object { $_ -notmatch '^flutter\.version(Name|Code)=' }
$props += "flutter.versionName=$versionName"
$props += "flutter.versionCode=$versionCode"
[System.IO.File]::WriteAllLines($localProps, $props)
Write-Host "Version sync: $versionName (code $versionCode)" -ForegroundColor Cyan

Write-Host "Building release app bundle..." -ForegroundColor Cyan
Push-Location $android
try {
    & .\gradlew.bat :app:bundleRelease
    if ($LASTEXITCODE -ne 0) { throw "Gradle bundleRelease failed with exit $LASTEXITCODE" }
} finally {
    Pop-Location
}

$src = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $src)) {
    throw "AAB not found: $src"
}

$destDir = Join-Path $root "release"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$version = (Select-String -Path (Join-Path $root "pubspec.yaml") -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$dest = Join-Path $destDir "healthpath-$version-release.aab"
Copy-Item $src $dest -Force

$mb = [math]::Round((Get-Item $dest).Length / 1MB, 2)
Write-Host ""
Write-Host "Done. Upload this file to Play Console:" -ForegroundColor Green
Write-Host "  $dest - $mb MiB" -ForegroundColor Yellow
Write-Host ""
Write-Host "Play Console: Release > Testing > Internal testing > Create release > Upload AAB"
Write-Host "Package: com.exodiateam.healthpath"
