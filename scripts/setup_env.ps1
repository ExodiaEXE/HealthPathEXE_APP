# Create .env from .env.example if missing (same as backend workflow)
Set-Location $PSScriptRoot\..

if (Test-Path .env) {
    Write-Host ".env already exists - kept as is." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path .env.example)) {
    Write-Error ".env.example not found!"
    exit 1
}

Copy-Item .env.example .env
Write-Host "Created .env from .env.example - edit API_BASE_URL for your machine." -ForegroundColor Green
