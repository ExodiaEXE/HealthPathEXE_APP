# Build AAB for Google Play — luôn embed API production (dart-define + .env asset).

param(
    [switch]$Clean,
    [string]$ApiBaseUrl = "https://api.healthpath.com.vn"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$android = Join-Path $root "android"
$keyProps = Join-Path $android "key.properties"
$localProps = Join-Path $android "local.properties"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

if (-not (Test-Path $keyProps)) {
    Write-Host "No upload keystore - creating one..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "create_upload_keystore.ps1")
}

if (-not (Test-Path $localProps)) {
    throw "Missing android/local.properties"
}

$flutterSdk = (Select-String -Path $localProps -Pattern '^flutter\.sdk=(.+)$').Matches[0].Groups[1].Value.Trim()
$flutter = Join-Path $flutterSdk "bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    throw "Flutter SDK not found: $flutter"
}
$env:PATH = "$(Split-Path $flutter -Parent);$env:PATH"
Write-Host "Flutter: $flutterSdk" -ForegroundColor Cyan

# .env được bundle vào AAB (pubspec assets) — ghi production trước khi build
$dotEnv = Join-Path $root ".env"
$googleId = ""
$facebookId = ""
if (Test-Path $dotEnv) {
    $googleId = (Select-String -Path $dotEnv -Pattern '^\s*GOOGLE_CLIENT_ID\s*=\s*(.+)\s*$' -ErrorAction SilentlyContinue | Select-Object -First 1).Matches[0].Groups[1].Value.Trim()
    $facebookId = (Select-String -Path $dotEnv -Pattern '^\s*FACEBOOK_APP_ID\s*=\s*(.+)\s*$' -ErrorAction SilentlyContinue | Select-Object -First 1).Matches[0].Groups[1].Value.Trim()
}
if (-not $googleId) { $googleId = "340998906895-9vtgmn1h93kfl19nndfp9h2rr90eovkq.apps.googleusercontent.com" }
if (-not $facebookId) { $facebookId = "1271647791434810" }

$envContent = @"
# Play release — auto by build_play_aab.ps1
API_BASE_URL=$ApiBaseUrl
JWT_ISSUER=healthpath
GOOGLE_CLIENT_ID=$googleId
FACEBOOK_APP_ID=$facebookId
"@
Set-Content -Path $dotEnv -Value $envContent -Encoding utf8
Write-Host "Wrote .env for release: API_BASE_URL=$ApiBaseUrl" -ForegroundColor Cyan

$pubspec = Join-Path $root "pubspec.yaml"
$versionLine = (Select-String -Path $pubspec -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$versionName, $versionCode = $versionLine -split '\+', 2
$props = Get-Content $localProps | Where-Object { $_ -notmatch '^flutter\.version(Name|Code)=' }
$props += "flutter.versionName=$versionName"
$props += "flutter.versionCode=$versionCode"
[System.IO.File]::WriteAllLines($localProps, $props)
Write-Host "Version sync: $versionName (code $versionCode)" -ForegroundColor Cyan

if ($Clean) {
    Write-Host "Clean: removing build/ ..." -ForegroundColor Yellow
    Remove-Item -LiteralPath (Join-Path $root "build") -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "flutter pub get..." -ForegroundColor Cyan
Push-Location $root
& $flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

$targetPlatform = "android-arm64"
Write-Host "flutter build appbundle ($targetPlatform)..." -ForegroundColor Cyan

$defineArgs = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    "--dart-define=JWT_ISSUER=healthpath",
    "--dart-define=GOOGLE_CLIENT_ID=$googleId",
    "--dart-define=FACEBOOK_APP_ID=$facebookId"
)

& $flutter build appbundle --release --target-platform $targetPlatform @defineArgs
$buildExit = $LASTEXITCODE
Pop-Location

$src = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $src)) {
    throw "Build failed (exit $buildExit). No AAB at: $src"
}

if ($buildExit -ne 0) {
    Write-Host "Exit code $buildExit (often apkanalyzer) - AAB exists, copying." -ForegroundColor Yellow
}

$destDir = Join-Path $root "release"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$dest = Join-Path $destDir "healthpath-$versionLine-prod-release.aab"
Copy-Item $src $dest -Force

$mb = [math]::Round((Get-Item $dest).Length / 1MB, 2)
Write-Host ""
Write-Host "Done. Upload this file to Play Console:" -ForegroundColor Green
Write-Host "  $dest - $mb MiB" -ForegroundColor Yellow
Write-Host "Package: com.exodiateam.healthpath"
Write-Host "API: $ApiBaseUrl"
