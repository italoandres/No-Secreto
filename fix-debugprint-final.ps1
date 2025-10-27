# Script DEFINITIVO para corrigir debugPrint e print em TODOS os arquivos

Write-Host "🔧 CORREÇÃO DEFINITIVA: Removendo logs de release mode" -ForegroundColor Cyan
Write-Host ""

$totalArquivos = 0
$totalSubstituicoes = 0

# Função para processar um arquivo
function Process-File {
    param(
        [string]$FilePath,
        [bool]$IsDebugUtils = $false,
        [bool]$IsContextDebug = $false
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "⚠️ Arquivo não encontrado: $FilePath" -ForegroundColor Yellow
        return 0
    }
    
    Write-Host "📝 Processando: $FilePath" -ForegroundColor White
    
    try {
        # Ler arquivo como bytes para preservar encoding
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        $originalContent = $content
        $substituicoes = 0
        
        # 1. Substituir debugPrint( por safePrint( (exceto debug_utils.dart)
        if (-not $IsDebugUtils) {
            $matches = [regex]::Matches($content, "debugPrint\(")
            if ($matches.Count -gt 0) {
                $content = $content -replace "debugPrint\(", "safePrint("
                $substituicoes += $matches.Count
                Write-Host "  ✅ $($matches.Count) debugPrint substituídos" -ForegroundColor Green
            }
        }
        
        # 2. Substituir if (kDebugMode) debugPrint( por safePrint(
        if (-not $IsDebugUtils) {
            $pattern = "if\s*\(\s*kDebugMode\s*\)\s*debugPrint\("
            $matches = [regex]::Matches($content, $pattern)
            if ($matches.Count -gt 0) {
                $content = $content -replace $pattern, "safePrint("
                $substituicoes += $matches.Count
                Write-Host "  ✅ $($matches.Count) if(kDebugMode)debugPrint substituídos" -ForegroundColor Green
            }
            
            # Também substituir o padrão com chaves
            $pattern2 = "if\s*\(\s*kDebugMode\s*\)\s*\{\s*debugPrint\("
            $matches2 = [regex]::Matches($content, $pattern2)
            if ($matches2.Count -gt 0) {
                $content = $content -replace $pattern2, "safePrint("
                # Remover a chave de fechamento correspondente (simplificado)
                $content = $content -replace "\}\s*\n\s*return;", "return;"
                $substituicoes += $matches2.Count
                Write-Host "  ✅ $($matches2.Count) if(kDebugMode){debugPrint substituídos" -ForegroundColor Green
            }
        }
        
        # 3. Substituir print( por safePrint( (exceto debug_utils.dart e context_debug.dart)
        if (-not $IsDebugUtils -and -not $IsContextDebug) {
            $pattern = "(?<!safe)print\("
            $matches = [regex]::Matches($content, $pattern)
            if ($matches.Count -gt 0) {
                $content = $content -replace $pattern, "safePrint("
                $substituicoes += $matches.Count
                Write-Host "  ✅ $($matches.Count) print substituídos" -ForegroundColor Green
            }
        }
        
        # 4. Adicionar import se necessário
        if ($content -match "safePrint\(" -and $content -notmatch "import 'package:whatsapp_chat/utils/debug_utils\.dart';") {
            # Encontrar a última linha de import
            $lines = $content -split "`r?`n"
            $lastImportIndex = -1
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^import ") {
                    $lastImportIndex = $i
                }
            }
            
            if ($lastImportIndex -ge 0) {
                $lines = $lines[0..$lastImportIndex] + "import 'package:whatsapp_chat/utils/debug_utils.dart';" + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
                $content = $lines -join "`n"
                Write-Host "  ✅ Import adicionado" -ForegroundColor Green
            }
        }
        
        # Salvar se houve mudanças
        if ($content -ne $originalContent) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
            [System.IO.File]::WriteAllBytes($FilePath, $bytes)
            Write-Host "  ✅ Arquivo salvo com $substituicoes substituições" -ForegroundColor Green
            return $substituicoes
        } else {
            Write-Host "  ℹ️ Nenhuma mudança necessária" -ForegroundColor Gray
            return 0
        }
        
    } catch {
        Write-Host "  ❌ Erro ao processar arquivo: $_" -ForegroundColor Red
        return 0
    }
}

# Lista de arquivos para processar
$arquivos = @(
    @{Path="lib\repositories\login_repository.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\services\online_status_service.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\utils\context_debug.dart"; IsDebugUtils=$false; IsContextDebug=$true},
    @{Path="lib\views\robust_match_chat_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\sinais_isaque_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\spiritual_certification_request_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\stories_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\story_favorites_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\username_settings_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\unified_notifications_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\storie_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\welcome_view.dart"; IsDebugUtils=$false; IsContextDebug=$false},
    @{Path="lib\views\stories_viewer_view.dart"; IsDebugUtils=$false; IsContextDebug=$false}
)

foreach ($arquivo in $arquivos) {
    $subs = Process-File -FilePath $arquivo.Path -IsDebugUtils $arquivo.IsDebugUtils -IsContextDebug $arquivo.IsContextDebug
    if ($subs -gt 0) {
        $totalArquivos++
        $totalSubstituicoes += $subs
    }
}

Write-Host ""
Write-Host "📊 RESUMO FINAL:" -ForegroundColor Cyan
Write-Host "  Arquivos modificados: $totalArquivos" -ForegroundColor White
Write-Host "  Total de substituições: $totalSubstituicoes" -ForegroundColor White
Write-Host ""
Write-Host "🎯 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Execute: flutter clean" -ForegroundColor White
Write-Host "2. Execute: flutter build apk --release" -ForegroundColor White
Write-Host "3. Teste o login no APK" -ForegroundColor White
Write-Host ""
Write-Host "✅ Os logs devem SUMIR completamente em release mode!" -ForegroundColor Green
Write-Host "✅ O login deve funcionar SEM timeout!" -ForegroundColor Green
