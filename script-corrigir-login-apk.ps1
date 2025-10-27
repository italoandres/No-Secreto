# Script para corrigir login no APK após adicionar SHA-1

Write-Host "🔧 CORREÇÃO LOGIN APK - Após adicionar SHA-1" -ForegroundColor Cyan
Write-Host ""

# Passo 1: Backup
Write-Host "📦 PASSO 1: Fazendo backup do google-services.json atual..." -ForegroundColor Yellow
if (Test-Path "android\app\google-services.json") {
    Copy-Item "android\app\google-services.json" "android\app\google-services.json.backup"
    Write-Host "✅ Backup criado: android\app\google-services.json.backup" -ForegroundColor Green
} else {
    Write-Host "⚠️ Arquivo google-services.json não encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "⏸️ AÇÃO NECESSÁRIA:" -ForegroundColor Yellow
Write-Host "1. Acesse: https://console.firebase.google.com" -ForegroundColor White
Write-Host "2. Selecione seu projeto" -ForegroundColor White
Write-Host "3. Configurações do projeto > Seus apps > Android" -ForegroundColor White
Write-Host "4. Baixe o novo google-services.json" -ForegroundColor White
Write-Host "5. Substitua o arquivo em: android\app\google-services.json" -ForegroundColor White
Write-Host ""

$resposta = Read-Host "Você já baixou e substituiu o google-services.json? (s/n)"

if ($resposta -ne "s") {
    Write-Host "❌ Por favor, baixe e substitua o arquivo primeiro!" -ForegroundColor Red
    exit
}

# Passo 2: Limpar cache Flutter
Write-Host ""
Write-Host "🧹 PASSO 2: Limpando cache do Flutter..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Cache Flutter limpo" -ForegroundColor Green

# Passo 3: Limpar cache Gradle
Write-Host ""
Write-Host "🧹 PASSO 3: Limpando cache do Gradle..." -ForegroundColor Yellow
Push-Location android
.\gradlew clean
Pop-Location
Write-Host "✅ Cache Gradle limpo" -ForegroundColor Green

# Passo 4: Rebuild APK
Write-Host ""
Write-Host "🔨 PASSO 4: Rebuilding APK debug..." -ForegroundColor Yellow
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ APK debug criado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao criar APK" -ForegroundColor Red
    exit
}

# Passo 5: Instalar
Write-Host ""
Write-Host "📱 PASSO 5: Instalando APK no dispositivo..." -ForegroundColor Yellow
adb install build\app\outputs\flutter-apk\app-debug.apk

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ APK instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao instalar APK" -ForegroundColor Red
    Write-Host "💡 Certifique-se de que o dispositivo está conectado" -ForegroundColor Yellow
    exit
}

# Passo 6: Instruções finais
Write-Host ""
Write-Host "🎉 PRONTO! Agora teste o login no dispositivo" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Para ver os logs em tempo real:" -ForegroundColor Yellow
Write-Host "adb logcat | findstr flutter" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Logs esperados:" -ForegroundColor Yellow
Write-Host "✅ Firebase Auth OK" -ForegroundColor Green
Write-Host "✅ Firestore Query OK" -ForegroundColor Green
Write-Host "🎉 LOGIN COMPLETO COM SUCESSO!" -ForegroundColor Green
