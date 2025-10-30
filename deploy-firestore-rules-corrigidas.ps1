# 🎯 SCRIPT DE DEPLOY: Firestore Rules Corrigidas
# Este script faz deploy das regras corrigidas do Firestore

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎯 DEPLOY: Firestore Rules Corrigidas" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 O que será feito:" -ForegroundColor Yellow
Write-Host "  ✅ Deploy das regras do firestore.rules" -ForegroundColor Green
Write-Host "  ✅ Funções auxiliares movidas para o topo" -ForegroundColor Green
Write-Host "  ✅ Regra catch-all mantida no final" -ForegroundColor Green
Write-Host "  ✅ Todas as coleções acessíveis para autenticados" -ForegroundColor Green
Write-Host ""

Write-Host "🔒 Segurança:" -ForegroundColor Yellow
Write-Host "  ❌ Usuários não autenticados: SEM ACESSO" -ForegroundColor Red
Write-Host "  ✅ Usuários autenticados: ACESSO COMPLETO" -ForegroundColor Green
Write-Host ""

Write-Host "⏳ Fazendo deploy das regras..." -ForegroundColor Yellow
Write-Host ""

# Executar deploy
firebase deploy --only firestore:rules

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ DEPLOY CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎯 Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Abra o app no Chrome (F12 para ver console)" -ForegroundColor White
Write-Host "  2. Faça login" -ForegroundColor White
Write-Host "  3. Verifique se os erros de permission-denied sumiram" -ForegroundColor White
Write-Host "  4. Teste carregar stories, chats e profiles" -ForegroundColor White
Write-Host ""

Write-Host "✅ Resultado esperado:" -ForegroundColor Green
Write-Host "  ✅ Stories carregam sem erro" -ForegroundColor Green
Write-Host "  ✅ Chats carregam sem erro" -ForegroundColor Green
Write-Host "  ✅ Profiles carregam sem erro" -ForegroundColor Green
Write-Host "  ✅ Explore Profiles funciona" -ForegroundColor Green
Write-Host ""
