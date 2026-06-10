# Chạy app — đọc cấu hình từ file .env (không cần --dart-define)
Set-Location $PSScriptRoot\..

& "$PSScriptRoot\setup_env.ps1"

flutter pub get
flutter run
