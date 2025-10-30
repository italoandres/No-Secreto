# Script para deploy das regras Firestore corrigidas
# Execute: .\deploy-rules-corrigidas.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY: Regras Firestore Corrigidas  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 CORREÇÕES APLICADAS:" -ForegroundColor Yellow
Write-Host "  ✅ Stories: resource.data corrigido" -ForegroundColor Green
Write-Host "  ✅ Match Messages: Update permite isRead" -ForegroundColor Green
Write-Host "  ✅ Match Messages: Read simplificado" -ForegroundColor Green
Write-Host "  ⚠️  Catch-all temporária adicionada" -ForegroundColor Yellow
Write-Host ""

Write-Host "🚀 Fazendo deploy das regras..." -ForegroundColor Yellow
Write-Host ""

try {
    firebase deploy --only firestore:rules
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✅ DEPLOY CONCLUÍDO COM SUCESSO!     " -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "📊 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1️⃣  TESTAR NO EMULADOR:" -ForegroundColor Yellow
        Write-Host "   flutter run --release" -ForegroundColor White
        Write-Host "   Verifique se os erros permission-denied sumiram" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "2️⃣  VERIFICAR LOGS:" -ForegroundColor Yellow
        Write-Host "   adb logcat | Select-String 'permission-denied'" -ForegroundColor White
        Write-Host "   Não deve aparecer nenhum erro" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "3️⃣  RESOLVER SHA-1/SHA-256:" -ForegroundColor Yellow
        Write-Host "   Continue com o keytool para extrair as chaves" -ForegroundColor White
        Write-Host "   Cadastre no Firebase Console" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "4️⃣  TESTAR NO CELULAR REAL:" -ForegroundColor Yellow
        Write-Host "   Após cadastrar SHA, gere novo APK e teste" -ForegroundColor White
        Write-Host ""
        
        Write-Host "✨ As regras Firestore agora estão corrigidas!" -ForegroundColor Green
        Write-Host ""
        
    } else {
        Write-Host ""
        Write-Host "❌ Erro ao fazer deploy!" -ForegroundColor Red
        Write-Host "Verifique os erros acima." -ForegroundColor Yellow
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

Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
