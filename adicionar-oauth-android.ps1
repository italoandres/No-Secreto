# Script para adicionar OAuth Client Android manualmente ao google-services.json
# Execute: .\adicionar-oauth-android.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ADICIONAR OAUTH CLIENT ANDROID       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$googleServicesPath = "android\app\google-services.json"

if (-not (Test-Path $googleServicesPath)) {
    Write-Host "ERRO: google-services.json nao encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "Lendo google-services.json..." -ForegroundColor Yellow
$content = Get-Content $googleServicesPath -Raw | ConvertFrom-Json

Write-Host "Verificando OAuth clients existentes..." -ForegroundColor Yellow
Write-Host ""

$androidApp = $content.client | Where-Object { $_.android_client_info -ne $null } | Select-Object -First 1

if ($androidApp.oauth_client) {
    Write-Host "OAuth Clients atuais:" -ForegroundColor Cyan
    foreach ($client in $androidApp.oauth_client) {
        Write-Host "   Client Type: $($client.client_type)" -ForegroundColor White
        Write-Host "   Client ID: $($client.client_id)" -ForegroundColor White
        Write-Host ""
    }
    
    # Verificar se já existe client_type 3
    $hasAndroidClient = $false
    foreach ($client in $androidApp.oauth_client) {
        if ($client.client_type -eq 3) {
            $hasAndroidClient = $true
            break
        }
    }
    
    if ($hasAndroidClient) {
        Write-Host "JA EXISTE um OAuth Client tipo Android (client_type: 3)!" -ForegroundColor Green
        Write-Host ""
        Write-Host "O problema pode ser outro. Verifique:" -ForegroundColor Yellow
        Write-Host "   1. O Client ID esta correto?" -ForegroundColor White
        Write-Host "   2. A SHA-1 esta correta?" -ForegroundColor White
        Write-Host "   3. O package name esta correto?" -ForegroundColor White
        Write-Host ""
        Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
}

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  ATENCAO                              " -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este script vai adicionar um OAuth Client Android ao google-services.json" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Red
Write-Host "   1. Voce DEVE ter criado o OAuth Client ID no Google Cloud Console primeiro" -ForegroundColor White
Write-Host "   2. Tipo: Android" -ForegroundColor White
Write-Host "   3. Package: com.no.secreto.com.deus.pai" -ForegroundColor White
Write-Host "   4. SHA-1: 18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53" -ForegroundColor White
Write-Host ""
Write-Host "Voce criou o OAuth Client ID no Google Cloud Console? (S/N)" -ForegroundColor Cyan
$resposta = Read-Host

if ($resposta -ne "S" -and $resposta -ne "s") {
    Write-Host ""
    Write-Host "Por favor, crie o OAuth Client ID primeiro:" -ForegroundColor Yellow
    Write-Host "   https://console.cloud.google.com/apis/credentials?project=app-no-secreto-com-o-pai" -ForegroundColor White
    Write-Host ""
    Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host ""
Write-Host "Digite o Client ID do OAuth Client Android que voce criou:" -ForegroundColor Cyan
Write-Host "(Exemplo: 490614568896-abc123xyz.apps.googleusercontent.com)" -ForegroundColor Gray
$clientId = Read-Host

if ([string]::IsNullOrWhiteSpace($clientId)) {
    Write-Host ""
    Write-Host "ERRO: Client ID nao pode ser vazio!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "Fazendo backup do arquivo original..." -ForegroundColor Yellow
Copy-Item $googleServicesPath "$googleServicesPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "   Backup criado: $googleServicesPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -ForegroundColor Green
Write-Host ""

Write-Host "Adicionando OAuth Client Android..." -ForegroundColor Yellow

# Criar novo OAuth client Android
$newOAuthClient = @{
    client_id = $clientId
    client_type = 3
    android_info = @{
        package_name = "com.no.secreto.com.deus.pai"
        certificate_hash = "18eaf9c12c614827c68ce630bc581724a0e57b53"
    }
}

# Adicionar ao array de oauth_client
if ($androidApp.oauth_client -is [System.Array]) {
    $androidApp.oauth_client += $newOAuthClient
} else {
    $androidApp.oauth_client = @($androidApp.oauth_client, $newOAuthClient)
}

Write-Host "Salvando arquivo atualizado..." -ForegroundColor Yellow
$content | ConvertTo-Json -Depth 10 | Set-Content $googleServicesPath -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SUCESSO                              " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "OAuth Client Android adicionado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Client ID adicionado:" -ForegroundColor Cyan
Write-Host "   $clientId" -ForegroundColor White
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "   1. Verifique: .\verificar-google-services.ps1" -ForegroundColor White
Write-Host "   2. Rebuild: flutter build apk --release" -ForegroundColor White
Write-Host "   3. Teste no celular" -ForegroundColor White
Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
