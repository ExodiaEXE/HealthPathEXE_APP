# Creates Play Console upload keystore + android/key.properties (local only, gitignored).

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$android = Join-Path $root "android"
$keystore = Join-Path $android "app\upload-keystore.jks"
$keyProps = Join-Path $android "key.properties"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"

if (-not (Test-Path $keytool)) {
    throw "keytool not found at $keytool"
}

if ((Test-Path $keystore) -and (Test-Path $keyProps)) {
    Write-Host "Keystore already exists:" -ForegroundColor Yellow
    Write-Host "  $keystore"
    Write-Host "  $keyProps"
    exit 0
}

$password = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
$alias = "healthpath-upload"
$dname = "CN=HealthPath, OU=Mobile, O=Exodia Team, L=Ho Chi Minh, ST=HCM, C=VN"

Write-Host "Creating upload keystore..." -ForegroundColor Cyan
& $keytool -genkeypair -v `
    -keystore $keystore `
    -alias $alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $password `
    -keypass $password `
    -dname $dname

$propsContent = @"
storePassword=$password
keyPassword=$password
keyAlias=$alias
storeFile=app/upload-keystore.jks
"@
[System.IO.File]::WriteAllText($keyProps, $propsContent.TrimStart(), [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Created:" -ForegroundColor Green
Write-Host "  $keystore"
Write-Host "  $keyProps"
Write-Host ""
Write-Host "BACK UP keystore + key.properties - required for every Play update." -ForegroundColor Red
Write-Host "Password is stored in android/key.properties (gitignored)."
