# Script para Deploy das Regras do Firebase Storage
# Corrige erro de upload de stories

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY FIREBASE STORAGE RULES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Verificando projeto ativo..." -ForegroundColor Yellow
firebase projects:list
Write-Host ""

Write-Host "[2/3] Fazendo deploy das regras do Storage..." -ForegroundColor Yellow
Write-Host ""
firebase deploy --only storage

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEPLOY CONCLUIDO!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "OK - Regras do Storage aplicadas!" -ForegroundColor Green
Write-Host ""
Write-Host "PROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Abrir o app" -ForegroundColor White
Write-Host "  2. Tentar publicar um story" -ForegroundColor White
Write-Host "  3. Verificar logs - NAO deve ter erro storage/unknown" -ForegroundColor White
Write-Host ""
Write-Host "VERIFICAR NO CONSOLE:" -ForegroundColor Yellow
Write-Host "  Firebase Console > Storage > Files" -ForegroundColor White
Write-Host "  Deve aparecer pasta stories_files/ com a imagem" -ForegroundColor White
Write-Host ""
