# Safe dev run — mock backend, no secrets in repo
Set-Location $PSScriptRoot\..

flutter pub get
flutter run `
  --dart-define=API_BASE_URL= `
  --dart-define=JWT_ISSUER= `
  --dart-define=GOOGLE_CLIENT_ID= `
  --dart-define=FACEBOOK_APP_ID=
