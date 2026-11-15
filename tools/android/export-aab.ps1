<#
.SYNOPSIS
  Exporta el AAB firmado de Defensa ESCOM (preset "Android" de export_presets.cfg).

.DESCRIPTION
  Pide la contrasena de la llave de subida (no se guarda en ningun archivo), la pasa a
  Godot por variables de entorno solo durante la exportacion y muestra la huella del
  certificado con el que quedo firmado el AAB.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\android\export-aab.ps1
#>
param(
  [string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe",
  [string]$Keystore = "$env:USERPROFILE\.android\keystores\defensa-escom-upload.jks",
  [string]$Alias = "upload-defensa-escom",
  [string]$Output = ""
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if (-not (Test-Path $Godot)) { throw "No encuentro Godot en '$Godot'. Usa -Godot <ruta>." }
if (-not (Test-Path $Keystore)) { throw "No encuentro la llave en '$Keystore'. Usa -Keystore <ruta>." }

$version = (Select-String -Path (Join-Path $project "project.godot") -Pattern '^config/version="(.+)"').Matches[0].Groups[1].Value
if (-not $Output) {
  $Output = Join-Path (Split-Path $project -Parent) "defensa-escom-builds\defensa-escom-v$version.aab"
}
New-Item -ItemType Directory -Force (Split-Path $Output -Parent) | Out-Null

$godotArgs = @("--headless", "--path", $project)
if (-not (Test-Path (Join-Path $project "android\build"))) { $godotArgs += "--install-android-build-template" }
$godotArgs += @("--export-release", "Android", $Output)

$secure = Read-Host "Contrasena de la llave ($Keystore)" -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $Keystore
  $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $Alias
  $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  & $Godot @godotArgs
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $Output)) { throw "La exportacion fallo (codigo $LASTEXITCODE)." }
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  Remove-Item Env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD, Env:GODOT_ANDROID_KEYSTORE_RELEASE_USER, Env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "AAB listo: $Output (version $version)"
& keytool -printcert -jarfile $Output | Select-String "Owner:|SHA256:"
