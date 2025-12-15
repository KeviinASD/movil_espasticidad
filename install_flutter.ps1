# Script de instalación de Flutter SDK para Windows
# Ejecutar como administrador si es necesario

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalación de Flutter SDK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Flutter ya está instalado
$flutterPath = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if ($flutterPath) {
    Write-Host "Flutter ya está instalado en: $flutterPath" -ForegroundColor Green
    flutter doctor
    exit 0
}

# Directorio de instalación recomendado
$installDir = "$env:LOCALAPPDATA\flutter"
$flutterZip = "$env:TEMP\flutter_windows.zip"
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

Write-Host "1. Descargando Flutter SDK..." -ForegroundColor Yellow
Write-Host "   URL: $flutterUrl" -ForegroundColor Gray
Write-Host "   Destino: $installDir" -ForegroundColor Gray
Write-Host ""

# Crear directorio si no existe
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Descargar Flutter
try {
    Write-Host "   Descargando (esto puede tardar varios minutos)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterZip -UseBasicParsing
    Write-Host "   ✓ Descarga completada" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Error al descargar: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor, descarga Flutter manualmente desde:" -ForegroundColor Yellow
    Write-Host "https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
Write-Host "2. Extrayendo Flutter SDK..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $flutterZip -DestinationPath "$env:LOCALAPPDATA\" -Force
    Write-Host "   ✓ Extracción completada" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Error al extraer: $_" -ForegroundColor Red
    exit 1
}

# Limpiar archivo ZIP
Remove-Item $flutterZip -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "3. Agregando Flutter al PATH..." -ForegroundColor Yellow

# Agregar al PATH del usuario
$flutterBinPath = "$installDir\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$flutterBinPath*") {
    $newPath = "$currentPath;$flutterBinPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "   ✓ Flutter agregado al PATH del usuario" -ForegroundColor Green
    Write-Host ""
    Write-Host "   IMPORTANTE: Cierra y vuelve a abrir PowerShell para que los cambios surtan efecto" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ Flutter ya está en el PATH" -ForegroundColor Green
}

Write-Host ""
Write-Host "4. Verificando instalación..." -ForegroundColor Yellow
Write-Host ""

# Actualizar PATH en la sesión actual
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Verificar Flutter
$flutterCmd = "$flutterBinPath\flutter.bat"
if (Test-Path $flutterCmd) {
    Write-Host "   Ejecutando flutter doctor..." -ForegroundColor Yellow
    & $flutterCmd doctor
} else {
    Write-Host "   ✗ No se encontró flutter.bat" -ForegroundColor Red
    Write-Host ""
    Write-Host "Instalación completada, pero necesitas:" -ForegroundColor Yellow
    Write-Host "1. Cerrar y volver a abrir PowerShell" -ForegroundColor Cyan
    Write-Host "2. Ejecutar: flutter doctor" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalación completada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Cierra y vuelve a abrir PowerShell" -ForegroundColor White
Write-Host "2. Ejecuta: flutter doctor" -ForegroundColor White
Write-Host "3. Instala las dependencias faltantes que indique flutter doctor" -ForegroundColor White
Write-Host "4. Navega a tu proyecto y ejecuta: flutter pub get" -ForegroundColor White
Write-Host "5. Ejecuta: flutter run" -ForegroundColor White

