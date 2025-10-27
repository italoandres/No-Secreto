# Script para obter SHA-1 e SHA-256 da chave release

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OBTENDO SHA-1 E SHA-256 DA RELEASE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "android\app\release-key.jks"
$keyAlias = "release"
$storePassword = "123456"

Write-Host "Keystore: $keystorePath" -ForegroundColor Yellow
Write-Host "Alias: $keyAlias" -ForegroundColor Yellow
Write-Host ""

if (Test-Path $keystorePath) {
    Write-Host "✓ Keystore encontrado!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Executando keytool..." -ForegroundColor Cyan
    Write-Host ""
    
    # Executar keytool
    keytool -list -v -keystore $keystorePath -alias $keyAlias -storepass $storePassword
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  PRÓXIMOS PASSOS:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. COPIE os valores de SHA1 e SHA256 acima" -ForegroundColor Yellow
    Write-Host "2. Acesse: https://console.firebase.google.com" -ForegroundColor Yellow
    Write-Host "3. Vá em Configurações do Projeto > Seus apps" -ForegroundColor Yellow
    Write-Host "4. Clique no app Android" -ForegroundColor Yellow
    Write-Host "5. Role até 'Impressões digitais do certificado SHA'" -ForegroundColor Yellow
    Write-Host "6. Adicione AMBOS os hashes (SHA-1 e SHA-256)" -ForegroundColor Yellow
    Write-Host "7. Baixe o novo google-services.json" -ForegroundColor Yellow
    Write-Host "8. Substitua em android/app/google-services.json" -ForegroundColor Yellow
    Write-Host ""
    
} else {
    Write-Host "✗ Keystore NÃO encontrado em: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifique se o caminho está correto!" -ForegroundColor Yellow
}
