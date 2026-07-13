# =====================================================================
# GDM Job Cars - RELEASE (Shorebird)
# ---------------------------------------------------------------------
# Cria uma NOVA versao do app (APK novo, com code push habilitado).
# Use quando: mudar dependencia nativa, permissoes, versao do app, ou
# na primeira publicacao. Depois distribua o APK com scripts/distribuir.ps1.
#
# Para mudancas so de codigo Dart/UI, prefira scripts/patch.ps1 (sem reinstalar).
#
# Uso:
#   ./scripts/release.ps1
#   ./scripts/release.ps1 -ApiUrl "https://outro-backend/api/v1"
# =====================================================================
param(
    [string]$ApiUrl = "https://gdm-job-cars-backend.onrender.com/api/v1"
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "==> Shorebird release (APK) apontando para: $ApiUrl" -ForegroundColor Cyan
shorebird release android --artifact=apk -- --dart-define=API_BASE_URL=$ApiUrl

Write-Host "`nOK. APK gerado em build\app\outputs\apk\release\app-release.apk" -ForegroundColor Green
Write-Host "Agora distribua com: ./scripts/distribuir.ps1 -AppId <FIREBASE_APP_ID>" -ForegroundColor Yellow
