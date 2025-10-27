# Script simples para corrigir build do Gradle
Write-Host "Corrigindo build do Gradle..." -ForegroundColor Cyan
Write-Host ""

# Matar processos
Write-Host "1. Matando processos Java e Gradle..." -ForegroundColor Yellow
taskkill /F /IM java.exe 2>$null
taskkill /F /IM gradle.exe 2>$null
Start-Sleep -Seconds 2

# Deletar pasta build
Write-Host "2. Deletando pasta build..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
}

# Flutter clean
Write-Host "3. Flutter clean..." -ForegroundColor Yellow
flutter clean

# Flutter pub get
Write-Host "4. Flutter pub get..." -ForegroundColor Yellow
flutter pub get

# Build APK
Write-Host "5. Compilando APK..." -ForegroundColor Yellow
flutter build apk --release

Write-Host ""
Write-Host "Concluido!" -ForegroundColor Green
