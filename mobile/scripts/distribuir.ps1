# =====================================================================
# GDM Job Cars - DISTRIBUIR (Firebase App Distribution)
# ---------------------------------------------------------------------
# Envia o APK para os testadores via Firebase App Distribution.
# Eles recebem um e-mail com o link de instalacao (sem loja).
#
# Projeto Firebase: nursery-job-cars
# App Android:      com.gdm.gdm_job_cars_mobile
#
# Pre-requisito (uma vez): firebase login
#
# Uso:
#   ./scripts/distribuir.ps1 -Testadores "a@x.com,b@y.com"
#   ./scripts/distribuir.ps1 -Grupos "portaria" -Notas "Corrige X"
# =====================================================================
param(
    [string]$AppId = "1:889811836954:android:ca0f0f2add88d94938b1a3",
    [string]$Projeto = "nursery-job-cars",
    [string]$Apk = "build/app/outputs/flutter-apk/app-release.apk",
    [string]$Testadores = "",
    [string]$Grupos = "",
    [string]$Notas = "Nova versao do GDM Job Cars"
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Test-Path $Apk)) {
    Write-Error "APK nao encontrado em '$Apk'. Rode antes: flutter build apk --release --dart-define=API_BASE_URL=https://gdm-job-cars-backend.onrender.com/api/v1"
    exit 1
}
if (-not $Testadores -and -not $Grupos) {
    Write-Host "Informe -Testadores 'email' ou -Grupos 'alias'." -ForegroundColor Yellow
    exit 1
}

$fbArgs = @("appdistribution:distribute", $Apk, "--app", $AppId, "--project", $Projeto, "--release-notes", $Notas)
if ($Testadores) { $fbArgs += @("--testers", $Testadores) }
if ($Grupos) { $fbArgs += @("--groups", $Grupos) }

Write-Host "==> Distribuindo $Apk (app $AppId)..." -ForegroundColor Cyan
firebase @fbArgs

Write-Host "`nOK. Os testadores receberao o link de instalacao por e-mail." -ForegroundColor Green
