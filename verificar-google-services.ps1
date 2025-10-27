# Script para verificar google-services.json
# Execute: .\verificar-google-services.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACAO: google-services.json    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$googleServicesPath = "android\app\google-services.json"

if (-not (Test-Path $googleServicesPath)) {
    Write-Host "ERRO: google-services.json nao encontrado!" -ForegroundColor Red
    Write-Host "Caminho esperado: $googleServicesPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Arquivo encontrado: $googleServicesPath" -ForegroundColor Green
Write-Host ""

try {
    $content = Get-Content $googleServicesPath -Raw | ConvertFrom-Json
    
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  INFORMACOES DO PROJETO               " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $projectId = $content.project_info.project_id
    $projectNumber = $content.project_info.project_number
    
    Write-Host "Project ID:" -ForegroundColor Cyan
    Write-Host "   $projectId" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Project Number:" -ForegroundColor Cyan
    Write-Host "   $projectNumber" -ForegroundColor White
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  OAUTH CLIENTS CONFIGURADOS           " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $androidApp = $content.client | Where-Object { $_.android_client_info -ne $null } | Select-Object -First 1
    
    if ($androidApp) {
        $packageName = $androidApp.android_client_info.package_name
        Write-Host "Package Name:" -ForegroundColor Cyan
        Write-Host "   $packageName" -ForegroundColor White
        Write-Host ""
        
        if ($androidApp.oauth_client) {
            Write-Host "OAuth Clients encontrados:" -ForegroundColor Green
            Write-Host ""
            
            $oauthClients = $androidApp.oauth_client
            if ($oauthClients -is [System.Array]) {
                for ($i = 0; $i -lt $oauthClients.Count; $i++) {
                    $client = $oauthClients[$i]
                    Write-Host "   Cliente $($i + 1):" -ForegroundColor Yellow
                    Write-Host "      Client ID: $($client.client_id)" -ForegroundColor White
                    Write-Host "      Client Type: $($client.client_type)" -ForegroundColor White
                    Write-Host ""
                }
            } else {
                Write-Host "   Cliente 1:" -ForegroundColor Yellow
                Write-Host "      Client ID: $($oauthClients.client_id)" -ForegroundColor White
                Write-Host "      Client Type: $($oauthClients.client_type)" -ForegroundColor White
                Write-Host ""
            }
        } else {
            Write-Host "AVISO: Nenhum OAuth Client configurado!" -ForegroundColor Red
            Write-Host ""
            Write-Host "Isso pode causar problemas no Google Sign-In!" -ForegroundColor Yellow
            Write-Host ""
        }
    }
    
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  API KEYS                              " -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    if ($androidApp.api_key) {
        $apiKeys = $androidApp.api_key
        if ($apiKeys -is [System.Array]) {
            for ($i = 0; $i -lt $apiKeys.Count; $i++) {
                $key = $apiKeys[$i]
                Write-Host "   API Key $($i + 1):" -ForegroundColor Cyan
                Write-Host "      Current Key: $($key.current_key)" -ForegroundColor White
                Write-Host ""
            }
        } else {
            Write-Host "   API Key:" -ForegroundColor Cyan
            Write-Host "      Current Key: $($apiKeys.current_key)" -ForegroundColor White
            Write-Host ""
        }
    }
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  DIAGNOSTICO                          " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    $hasOAuth = $androidApp.oauth_client -ne $null
    $hasApiKey = $androidApp.api_key -ne $null
    
    if ($hasOAuth -and $hasApiKey) {
        Write-Host "STATUS: Configuracao parece OK" -ForegroundColor Green
        Write-Host ""
        Write-Host "Proximos passos:" -ForegroundColor Cyan
        Write-Host "   1. Verifique se o OAuth Client ID esta configurado no Google Cloud Console" -ForegroundColor White
        Write-Host "   2. Confirme que a SHA-1 do release keystore esta cadastrada" -ForegroundColor White
        Write-Host "   3. Se o problema persistir, baixe um novo google-services.json" -ForegroundColor White
    } else {
        Write-Host "STATUS: Configuracao INCOMPLETA" -ForegroundColor Red
        Write-Host ""
        Write-Host "ACAO NECESSARIA:" -ForegroundColor Yellow
        Write-Host "   1. Acesse Firebase Console" -ForegroundColor White
        Write-Host "   2. Va em Project Settings > Your apps > Android" -ForegroundColor White
        Write-Host "   3. Baixe o google-services.json mais recente" -ForegroundColor White
        Write-Host "   4. Substitua o arquivo em android/app/" -ForegroundColor White
        Write-Host ""
        Write-Host "   Ou configure o OAuth Client ID:" -ForegroundColor White
        Write-Host "   1. Acesse https://console.cloud.google.com/apis/credentials" -ForegroundColor White
        Write-Host "   2. Crie um OAuth 2.0 Client ID para Android" -ForegroundColor White
        Write-Host "   3. Use a SHA-1: 18:EA:F9:C1:2C:61:48:27:C6:8C:E6:30:BC:58:17:24:A0:E5:7B:53" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  LINKS UTEIS                          " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Firebase Console:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/project/$projectId" -ForegroundColor White
    Write-Host ""
    Write-Host "Google Cloud Console (Credentials):" -ForegroundColor Yellow
    Write-Host "   https://console.cloud.google.com/apis/credentials?project=$projectId" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "ERRO ao ler google-services.json!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "O arquivo pode estar corrompido ou com formato invalido." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
