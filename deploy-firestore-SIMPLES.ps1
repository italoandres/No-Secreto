# Script para Deploy das Regras Corrigidas do Firestore
# Corrige erros de permission-denied

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY FIRESTORE RULES - CORRIGIDO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Fazer backup do arquivo atual
Write-Host "[1/4] Fazendo backup do firestore.rules atual..." -ForegroundColor Yellow
Copy-Item "firestore.rules" "firestore.rules.BACKUP_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
Write-Host "OK - Backup criado!" -ForegroundColor Green
Write-Host ""

# 2. Copiar arquivo corrigido
Write-Host "[2/4] Aplicando correcoes..." -ForegroundColor Yellow
Copy-Item "firestore.rules.CORRIGIDO" "firestore.rules" -Force
Write-Host "OK - Arquivo corrigido aplicado!" -ForegroundColor Green
Write-Host ""

# 3. Mostrar diferenças principais
Write-Host "[3/4] Principais mudancas aplicadas:" -ForegroundColor Yellow
Write-Host "  OK - sistema/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host "  OK - stories/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host "  OK - interests/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host "  OK - interest_notifications/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host "  OK - match_chats/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host "  OK - profiles/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host "  OK - spiritual_profiles/{document=**} - Cobre subcolecoes" -ForegroundColor White
Write-Host ""

# 4. Deploy
Write-Host "[4/4] Fazendo deploy para o Firebase..." -ForegroundColor Yellow
Write-Host ""
firebase deploy --only firestore:rules

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY CONCLUIDO!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "OK - Regras corrigidas aplicadas com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "PROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Fazer login no app" -ForegroundColor White
Write-Host "  2. Verificar logs - NAO deve ter permission-denied" -ForegroundColor White
Write-Host "  3. Confirmar que dados carregam:" -ForegroundColor White
Write-Host "     - Sistema" -ForegroundColor White
Write-Host "     - Stories" -ForegroundColor White
Write-Host "     - Interesses" -ForegroundColor White
Write-Host ""
Write-Host "Se ainda houver erros, verifique:" -ForegroundColor Yellow
Write-Host "  - Usuario esta autenticado (request.auth != null)" -ForegroundColor White
Write-Host "  - Nome da colecao esta correto" -ForegroundColor White
Write-Host ""
