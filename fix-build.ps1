# Script para corrigir erro de build do Gradle
# Execute como Administrador

Write-Host "🔧 Corrigindo erro de build do Gradle..." -ForegroundColor Cyan
Write-Host ""

# Passo 1: Matar processos Java/Gradle
Write-Host "1️⃣ Matando processos Java e Gradle..." -ForegroundColor Yellow
taskkill /F /IM java.exe 2>$null
taskkill /F /IM gradle.exe 2>$null
Start-Sleep -Seconds 2
Write-Host "✅ Processos finalizados" -ForegroundColor Green
Write-Host ""

# Passo 2: Deletar pasta build
Write-Host "2️⃣ Deletando pasta build..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
    Write-Host "✅ Pasta build deletada" -ForegroundColor Green
} else {
    Write-Host "⚠️ Pasta build não existe" -ForegroundColor Yellow
}
Write-Host ""

# Passo 3: Flutter clean
Write-Host "3️⃣ Executando flutter clean..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Flutter clean concluído" -ForegroundColor Green
Write-Host ""

# Passo 4: Flutter pub get
Write-Host "4️⃣ Executando flutter pub get..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependências instaladas" -ForegroundColor Green
Write-Host ""

# Passo 5: Build APK
Write-Host "5️⃣ Compilando APK (isso pode demorar 2-3 minutos)..." -ForegroundColor Yellow
flutter build apk --release

Write-Host ""
Write-Host "🎉 Processo concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Se o build foi bem-sucedido, o APK está em:" -ForegroundColor Cyan
Write-Host "   build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Próximo passo: Instalar no celular e testar o login!" -ForegroundColor Cyan
