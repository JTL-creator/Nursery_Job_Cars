# =====================================================================
# GDM Job Cars - PATCH / OTA (Shorebird)
# ---------------------------------------------------------------------
# Envia uma ATUALIZACAO por cima da ultima release, SEM reinstalar o app.
# Os celulares baixam o patch automaticamente ao abrir o app.
# Use para a maioria das mudancas (telas, regras, correcoes de Dart).
#
# Precisa existir uma release anterior compativel (scripts/release.ps1)
# com a MESMA versao (versionName+versionCode) do pubspec.yaml.
#
# Uso:
#   ./scripts/patch.ps1
#   ./scripts/patch.ps1 -ApiUrl "https://outro-backend/api/v1"
# =====================================================================
param(
    [string]$ApiUrl = "https://gdm-job-cars-backend.onrender.com/api/v1"
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "==> Shorebird patch (OTA) apontando para: $ApiUrl" -ForegroundColor Cyan
shorebird patch android --artifact=apk -- --dart-define=API_BASE_URL=$ApiUrl

Write-Host "`nOK. O patch sera aplicado nos celulares na proxima abertura do app." -ForegroundColor Green
