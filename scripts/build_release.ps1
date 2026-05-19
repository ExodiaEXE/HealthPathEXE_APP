# Store release — pass secrets via CI env / local dart-define only
param(
  [string]$ApiBaseUrl = "",
  [string]$JwtIssuer = "",
  [string]$GoogleClientId = "",
  [string]$FacebookAppId = ""
)

Set-Location $PSScriptRoot\..

$defines = @(
  "API_BASE_URL=$ApiBaseUrl",
  "JWT_ISSUER=$JwtIssuer",
  "GOOGLE_CLIENT_ID=$GoogleClientId",
  "FACEBOOK_APP_ID=$FacebookAppId"
)

$defineArgs = $defines | ForEach-Object { "--dart-define=$_" }

flutter pub get
flutter build appbundle @defineArgs
flutter build ipa @defineArgs
