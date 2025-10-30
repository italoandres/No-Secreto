# Script para corrigir e gerar novo APK release
# Execute: .\corrigir-e-buildar.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CORREÇÃO CRASH RELEASE - AUTOMÁTICO  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Passo 1: Deploy das regras Firestore
Write-Host "PASSO 1/3: Fazendo deploy das regras Firestore..." -ForegroundColor Yellow
Write-Host ""

try {
    firebase deploy --only firestore:rules
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Regras do Firestore atualizadas com sucesso!" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ Erro ao fazer deploy das regras!" -ForegroundColor Red
        Write-Host "Execute manualmente: firebase deploy --only firestore:rules" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ Erro ao executar firebase deploy!" -ForegroundColor Red
    Write-Host "Verifique se o Firebase CLI está instalado." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Passo 2: Limpar build anterior
Write-Host "PASSO 2/3: Limpando build anterior..." -ForegroundColor Yellow
Write-Host ""

flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build anterior limpo!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Erro ao limpar build!" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# Passo 3: Gerar novo APK release
Write-Host "PASSO 3/3: Gerando novo APK release..." -ForegroundColor Yellow
Write-Host "⏳ Isso pode levar 2-5 minutos..." -ForegroundColor Cyan
Write-Host ""

flutter build apk --release
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ SUCESSO! APK GERADO COM CORREÇÕES  " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📱 APK localizado em:" -ForegroundColor Cyan
    Write-Host "   build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "🚀 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "   1. Transfira o APK para o celular" -ForegroundColor White
    Write-Host "   2. Desinstale a versão antiga (se houver)" -ForegroundColor White
    Write-Host "   3. Instale o novo APK" -ForegroundColor White
    Write-Host "   4. Teste o app!" -ForegroundColor White
    Write-Host ""
    Write-Host "✨ O app agora deve funcionar perfeitamente no celular real!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Erro ao gerar APK!" -ForegroundColor Red
    Write-Host "Verifique os erros acima." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Mostrar tamanho do APK
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host "📊 Tamanho do APK: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
