# In SHA-1 + Facebook Key Hash cho Google Cloud / Meta (debug keystore).
$kt = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
$ks = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $kt)) {
    Write-Error "Không tìm thấy keytool tại $kt"
    exit 1
}
if (-not (Test-Path $ks)) {
    Write-Error "Không tìm thấy debug keystore tại $ks"
    exit 1
}

Write-Host "=== Debug keystore ($ks) ===" -ForegroundColor Cyan
& $kt -list -v -keystore $ks -alias androiddebugkey -storepass android -keypass android

$tmp = [System.IO.Path]::GetTempFileName()
& $kt -exportcert -alias androiddebugkey -keystore $ks -storepass android -keypass android -file $tmp | Out-Null
$bytes = [System.IO.File]::ReadAllBytes($tmp)
Remove-Item $tmp -Force
$fbHash = [Convert]::ToBase64String([System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes))

Write-Host ""
Write-Host "Facebook Key Hash (debug):" -ForegroundColor Green
Write-Host $fbHash
Write-Host ""
Write-Host "Google Cloud: OAuth client Android" -ForegroundColor Yellow
Write-Host "  Package: com.exodiateam.healthpath"
Write-Host "  SHA-1:   (copy dòng SHA1 ở trên)"
