# ANALISADOR DE DEPENDÊNCIAS - PowerShell
# Identifica arquivos de debug/test/fix e suas dependências

Write-Host "🔍 ANALISADOR DE DEPENDÊNCIAS - Projeto Flutter" -ForegroundColor Cyan
Write-Host ("="*80) -ForegroundColor Cyan

# Navegar para o diretório lib
$libPath = ".\lib"
if (-not (Test-Path $libPath)) {
    Write-Host "❌ Erro: Diretório 'lib' não encontrado!" -ForegroundColor Red
    exit
}

Write-Host "`n📂 Escaneando arquivos..." -ForegroundColor Yellow

# Encontrar todos os arquivos de debug/test/fix
$debugFiles = Get-ChildItem -Path $libPath -Recurse -Filter "debug_*.dart" | Select-Object -ExpandProperty FullName
$testFiles = Get-ChildItem -Path $libPath -Recurse -Filter "test_*.dart" | Select-Object -ExpandProperty FullName
$fixFiles = Get-ChildItem -Path $libPath -Recurse -Filter "fix_*.dart" | Select-Object -ExpandProperty FullName
$forceFiles = Get-ChildItem -Path $libPath -Recurse -Filter "force_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles = @()
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "simulate_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "populate_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "emergency_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "execute_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "deep_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "simple_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "quick_*.dart" | Select-Object -ExpandProperty FullName
$otherTempFiles += Get-ChildItem -Path $libPath -Recurse -Filter "diagnose_*.dart" | Select-Object -ExpandProperty FullName

Write-Host "`n📊 RESUMO INICIAL:" -ForegroundColor Green
Write-Host "   - Arquivos debug_*.dart:  $($debugFiles.Count)" -ForegroundColor White
Write-Host "   - Arquivos test_*.dart:   $($testFiles.Count)" -ForegroundColor White
Write-Host "   - Arquivos fix_*.dart:    $($fixFiles.Count)" -ForegroundColor White
Write-Host "   - Arquivos force_*.dart:  $($forceFiles.Count)" -ForegroundColor White
Write-Host "   - Outros temporários:     $($otherTempFiles.Count)" -ForegroundColor White

$allTempFiles = $debugFiles + $testFiles + $fixFiles + $forceFiles + $otherTempFiles
Write-Host "`n   TOTAL: $($allTempFiles.Count) arquivos temporários/debug" -ForegroundColor Cyan

# Função para verificar se um arquivo é importado
function Get-ImportCount {
    param($filePath)
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $allDartFiles = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart"
    
    $importCount = 0
    $importers = @()
    
    foreach ($dartFile in $allDartFiles) {
        $content = Get-Content $dartFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "import.*$fileName\.dart") {
            $importCount++
            $importers += $dartFile.Name
        }
    }
    
    return @{
        Count = $importCount
        Importers = $importers
    }
}

Write-Host "`n🔎 Analisando dependências (isso pode demorar alguns segundos)..." -ForegroundColor Yellow

# Classificar arquivos por risco
$safeFiles = @()
$lowRiskFiles = @()
$mediumRiskFiles = @()
$highRiskFiles = @()

$processed = 0
foreach ($file in $allTempFiles) {
    $processed++
    $fileName = [System.IO.Path]::GetFileName($file)
    
    # Mostrar progresso a cada 10 arquivos
    if ($processed % 10 -eq 0) {
        Write-Host "   Processado: $processed / $($allTempFiles.Count)" -ForegroundColor DarkGray
    }
    
    $result = Get-ImportCount -filePath $file
    
    if ($result.Count -eq 0) {
        $safeFiles += @{
            Path = $file
            Name = $fileName
            ImportCount = $result.Count
            Importers = $result.Importers
        }
    } elseif ($result.Count -le 2) {
        $lowRiskFiles += @{
            Path = $file
            Name = $fileName
            ImportCount = $result.Count
            Importers = $result.Importers
        }
    } elseif ($result.Count -le 5) {
        $mediumRiskFiles += @{
            Path = $file
            Name = $fileName
            ImportCount = $result.Count
            Importers = $result.Importers
        }
    } else {
        $highRiskFiles += @{
            Path = $file
            Name = $fileName
            ImportCount = $result.Count
            Importers = $result.Importers
        }
    }
}

# GERAR RELATÓRIO
Write-Host "`n" -NoNewline
Write-Host ("="*80) -ForegroundColor Cyan
Write-Host "📊 RELATÓRIO DE ANÁLISE DE DEPENDÊNCIAS" -ForegroundColor Cyan
Write-Host ("="*80) -ForegroundColor Cyan

Write-Host "`n🎯 DISTRIBUIÇÃO POR NÍVEL DE RISCO:" -ForegroundColor Green
Write-Host "   🟢 SAFE (não são importados):     $($safeFiles.Count) arquivos" -ForegroundColor Green
Write-Host "   🟡 LOW (1-2 imports):              $($lowRiskFiles.Count) arquivos" -ForegroundColor Yellow
Write-Host "   🟠 MEDIUM (3-5 imports):           $($mediumRiskFiles.Count) arquivos" -ForegroundColor DarkYellow
Write-Host "   🔴 HIGH (6+ imports):              $($highRiskFiles.Count) arquivos" -ForegroundColor Red

# Detalhes dos arquivos SAFE
if ($safeFiles.Count -gt 0) {
    Write-Host "`n" -NoNewline
    Write-Host ("="*80) -ForegroundColor Green
    Write-Host "🟢 ARQUIVOS SAFE (SEGUROS PARA DELETAR)" -ForegroundColor Green
    Write-Host ("="*80) -ForegroundColor Green
    Write-Host "Estes arquivos NÃO são importados por ninguém - podem ser deletados sem medo!`n"
    
    foreach ($file in $safeFiles | Sort-Object -Property Name) {
        $relativePath = $file.Path.Replace((Get-Location).Path, "").TrimStart('\')
        Write-Host "   ✅ $relativePath" -ForegroundColor White
    }
}

# Detalhes dos arquivos LOW RISK
if ($lowRiskFiles.Count -gt 0) {
    Write-Host "`n" -NoNewline
    Write-Host ("="*80) -ForegroundColor Yellow
    Write-Host "🟡 ARQUIVOS LOW RISK (BAIXO RISCO)" -ForegroundColor Yellow
    Write-Host ("="*80) -ForegroundColor Yellow
    Write-Host "Importados por poucos arquivos - risco mínimo`n"
    
    foreach ($file in $lowRiskFiles | Sort-Object -Property ImportCount -Descending | Select-Object -First 15) {
        $relativePath = $file.Path.Replace((Get-Location).Path, "").TrimStart('\')
        Write-Host "   📄 $relativePath" -ForegroundColor White
        Write-Host "      Importado por: $($file.ImportCount) arquivo(s)" -ForegroundColor DarkGray
        foreach ($importer in $file.Importers) {
            Write-Host "         - $importer" -ForegroundColor DarkGray
        }
    }
    
    if ($lowRiskFiles.Count -gt 15) {
        Write-Host "   ... e mais $($lowRiskFiles.Count - 15) arquivos" -ForegroundColor DarkGray
    }
}

# Detalhes dos arquivos MEDIUM RISK
if ($mediumRiskFiles.Count -gt 0) {
    Write-Host "`n" -NoNewline
    Write-Host ("="*80) -ForegroundColor DarkYellow
    Write-Host "🟠 ARQUIVOS MEDIUM RISK (RISCO MÉDIO)" -ForegroundColor DarkYellow
    Write-Host ("="*80) -ForegroundColor DarkYellow
    Write-Host "Usados em alguns lugares - deletar com cuidado`n"
    
    foreach ($file in $mediumRiskFiles | Sort-Object -Property ImportCount -Descending) {
        $relativePath = $file.Path.Replace((Get-Location).Path, "").TrimStart('\')
        Write-Host "   📄 $relativePath" -ForegroundColor White
        Write-Host "      Importado por: $($file.ImportCount) arquivo(s)" -ForegroundColor DarkGray
    }
}

# Detalhes dos arquivos HIGH RISK
if ($highRiskFiles.Count -gt 0) {
    Write-Host "`n" -NoNewline
    Write-Host ("="*80) -ForegroundColor Red
    Write-Host "🔴 ARQUIVOS HIGH RISK (ALTO RISCO)" -ForegroundColor Red
    Write-Host ("="*80) -ForegroundColor Red
    Write-Host "MUITO usados - analisar individualmente antes de deletar`n"
    
    foreach ($file in $highRiskFiles | Sort-Object -Property ImportCount -Descending) {
        $relativePath = $file.Path.Replace((Get-Location).Path, "").TrimStart('\')
        Write-Host "   ⚠️  $relativePath" -ForegroundColor Red
        Write-Host "      Importado por: $($file.ImportCount) arquivo(s)" -ForegroundColor DarkGray
    }
}

# PLANO DE AÇÃO
Write-Host "`n" -NoNewline
Write-Host ("="*80) -ForegroundColor Cyan
Write-Host "📋 PLANO DE AÇÃO RECOMENDADO" -ForegroundColor Cyan
Write-Host ("="*80) -ForegroundColor Cyan

Write-Host "`n🎯 FASE 1: ARQUIVOS SAFE ($($safeFiles.Count) arquivos)"
Write-Host "   Risco: 🟢 ZERO"
Write-Host "   Ação: Deletar todos de uma vez"
Write-Host "   Teste: Opcional (flutter run)"

Write-Host "`n🎯 FASE 2: ARQUIVOS LOW RISK ($($lowRiskFiles.Count) arquivos)"
Write-Host "   Risco: 🟡 BAIXO"
Write-Host "   Ação: Deletar em grupos de 10"
Write-Host "   Teste: flutter run após cada grupo"

Write-Host "`n🎯 FASE 3: ARQUIVOS MEDIUM RISK ($($mediumRiskFiles.Count) arquivos)"
Write-Host "   Risco: 🟠 MÉDIO"
Write-Host "   Ação: Deletar um por vez"
Write-Host "   Teste: flutter run após CADA arquivo"

Write-Host "`n🎯 FASE 4: ARQUIVOS HIGH RISK ($($highRiskFiles.Count) arquivos)"
Write-Host "   Risco: 🔴 ALTO"
Write-Host "   Ação: Análise manual individual"
Write-Host "   Teste: Commit individual + flutter run"

# Salvar lista de arquivos SAFE em um arquivo
$safeFilesPath = ".\ARQUIVOS_SAFE_PARA_DELETAR.txt"
$safeFiles | ForEach-Object { $_.Path.Replace((Get-Location).Path, "").TrimStart('\') } | Out-File -FilePath $safeFilesPath -Encoding UTF8

Write-Host "`n💾 Lista de arquivos SAFE salva em: ARQUIVOS_SAFE_PARA_DELETAR.txt" -ForegroundColor Green

Write-Host "`n" -NoNewline
Write-Host ("="*80) -ForegroundColor Cyan
Write-Host "✅ ANÁLISE COMPLETA!" -ForegroundColor Green
Write-Host ("="*80) -ForegroundColor Cyan

Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Revise os arquivos listados acima"
Write-Host "2. Confirme se concorda com a classificação"
Write-Host "3. Vamos começar pela FASE 1 (arquivos SAFE)"
