# Script para verificar SHA-1 e SHA-256 do release keystore
# Execute: .\verificar-sha-release.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACAO: SHA Release Keystore    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Procurar arquivo keystore
Write-Host "Procurando arquivo keystore..." -ForegroundColor Yellow
Write-Host ""

$keystoreFiles = @()
$keystoreFiles += Get-ChildItem -Path "android" -Filter "*.jks" -Recurse -ErrorAction SilentlyContinue
$keystoreFiles += Get-ChildItem -Path "android" -Filter "*.keystore" -Recurse -ErrorAction SilentlyContinue

if ($keystoreFiles.Count -eq 0) {
    Write-Host "ERRO: Nenhum arquivo keystore encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Procure manualmente por arquivos .jks ou .keystore" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Arquivo(s) encontrado(s):" -ForegroundColor Green
foreach ($file in $keystoreFiles) {
    Write-Host "   $($file.FullName)" -ForegroundColor White
}
Write-Host ""

# Usar o primeiro arquivo encontrado
$keystorePath = $keystoreFiles[0].FullName

Write-Host "Usando: $keystorePath" -ForegroundColor Cyan
Write-Host ""

# Verificar qual keystore está configurado no build.gradle
$buildGradlePath = "android\app\build.gradle"
if (Test-Path $buildGradlePath) {
    Write-Host "Verificando build.gradle..." -ForegroundColor Yellow
    $buildGradleContent = Get-Content $buildGradlePath -Raw
    
    if ($buildGradleContent -match "storeFile\s+file\('([^']+)'\)") {
        $configuredKeystore = $matches[1]
        Write-Host "   Keystore configurado: $configuredKeystore" -ForegroundColor White
    }
    Write-Host ""
}

# Encontrar keytool
Write-Host "Procurando keytool..." -ForegroundColor Yellow

$keytoolPath = $null

# Tentar encontrar keytool no JAVA_HOME
if ($env:JAVA_HOME) {
    $possiblePath = Join-Path $env:JAVA_HOME "bin\keytool.exe"
    if (Test-Path $possiblePath) {
        $keytoolPath = $possiblePath
        Write-Host "   Keytool encontrado em JAVA_HOME" -ForegroundColor Green
    }
}

# Se não encontrou, procurar em locais comuns
if (-not $keytoolPath) {
    $commonPaths = @(
        "C:\Program Files\Java\*\bin\keytool.exe",
        "C:\Program Files (x86)\Java\*\bin\keytool.exe",
        "$env:LOCALAPPDATA\Android\Sdk\*\bin\keytool.exe"
    )
    
    foreach ($pattern in $commonPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $keytoolPath = $found.FullName
            Write-Host "   Keytool encontrado: $($found.Directory.Parent.Name)" -ForegroundColor Green
            break
        }
    }
}

if (-not $keytoolPath) {
    Write-Host ""
    Write-Host "ERRO: keytool nao encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "O keytool vem com o Java JDK. Opcoes:" -ForegroundColor Yellow
    Write-Host "   1. Instale o Java JDK se nao tiver" -ForegroundColor White
    Write-Host "   2. Configure a variavel JAVA_HOME apontando para a pasta do JDK" -ForegroundColor White
    Write-Host ""
    Write-Host "Para verificar se tem Java instalado, execute: java -version" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "Extraindo certificados SHA..." -ForegroundColor Yellow
Write-Host ""
Write-Host "ATENCAO: Voce sera solicitado a digitar a senha do keystore" -ForegroundColor Yellow
Write-Host ""

try {
    # Executar keytool
    $output = & $keytoolPath -list -v -keystore $keystorePath 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO ao executar keytool!" -ForegroundColor Red
        Write-Host $output
        exit 1
    }
    
    # Extrair SHA-1 e SHA-256
    $sha1 = ""
    $sha256 = ""
    
    foreach ($line in $output) {
        if ($line -match "SHA1:\s*(.+)") {
            $sha1 = $matches[1].Trim()
        }
        if ($line -match "SHA256:\s*(.+)") {
            $sha256 = $matches[1].Trim()
        }
    }
    
    if ($sha1 -and $sha256) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  CERTIFICADOS EXTRAIDOS COM SUCESSO   " -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "SHA-1:" -ForegroundColor Cyan
        Write-Host "   $sha1" -ForegroundColor White
        Write-Host ""
        
        Write-Host "SHA-256:" -ForegroundColor Cyan
        Write-Host "   $sha256" -ForegroundColor White
        Write-Host ""
        
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "  COMPARACAO COM CHAVES CADASTRADAS    " -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        
        $cadastradaSHA1 = "18:ea:f9:c1:2c:61:48:27:c6:8c:e6:30:bc:58:17:24:a0:e5:7b:53"
        $cadastradaSHA256 = "82:7a:fa:18:96:d4:b2:92:ee:1e:1f:5b:c7:96:2a:e5:15:66:d2:13:1d:9d:e1:61:de:85:b3:8e:9d:4e:06:03"
        
        Write-Host "Cadastrada no Firebase (SHA-1):" -ForegroundColor Cyan
        Write-Host "   $cadastradaSHA1" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Extraida do Keystore (SHA-1):" -ForegroundColor Cyan
        Write-Host "   $sha1" -ForegroundColor White
        Write-Host ""
        
        if ($sha1.ToUpper() -eq $cadastradaSHA1.ToUpper()) {
            Write-Host "SUCESSO: SHA-1 BATE! Chave correta cadastrada!" -ForegroundColor Green
        } else {
            Write-Host "ERRO: SHA-1 NAO BATE! Chave errada cadastrada!" -ForegroundColor Red
            Write-Host ""
            Write-Host "ACAO NECESSARIA:" -ForegroundColor Yellow
            Write-Host "   1. Acesse Firebase Console" -ForegroundColor White
            Write-Host "   2. Va em Configuracoes do Projeto" -ForegroundColor White
            Write-Host "   3. Adicione a SHA-1 correta (mostrada acima)" -ForegroundColor White
            Write-Host "   4. Gere novo APK" -ForegroundColor White
        }
        Write-Host ""
        
        Write-Host "Cadastrada no Firebase (SHA-256):" -ForegroundColor Cyan
        Write-Host "   $cadastradaSHA256" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Extraida do Keystore (SHA-256):" -ForegroundColor Cyan
        Write-Host "   $sha256" -ForegroundColor White
        Write-Host ""
        
        if ($sha256.ToUpper() -eq $cadastradaSHA256.ToUpper()) {
            Write-Host "SUCESSO: SHA-256 BATE! Chave correta cadastrada!" -ForegroundColor Green
        } else {
            Write-Host "ERRO: SHA-256 NAO BATE! Chave errada cadastrada!" -ForegroundColor Red
            Write-Host ""
            Write-Host "ACAO NECESSARIA:" -ForegroundColor Yellow
            Write-Host "   1. Acesse Firebase Console" -ForegroundColor White
            Write-Host "   2. Va em Configuracoes do Projeto" -ForegroundColor White
            Write-Host "   3. Adicione a SHA-256 correta (mostrada acima)" -ForegroundColor White
            Write-Host "   4. Gere novo APK" -ForegroundColor White
        }
        Write-Host ""
        
    } else {
        Write-Host "ERRO: Nao foi possivel extrair os certificados!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Saida completa do keytool:" -ForegroundColor Yellow
        Write-Host $output
    }
    
} catch {
    Write-Host "ERRO ao executar keytool!" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host ""
Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
