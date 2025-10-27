# Script SIMPLES para corrigir logs em release mode
# Substitui print por safePrint em todos os arquivos

Write-Host "Corrigindo logs em release mode..." -ForegroundColor Cyan
Write-Host ""

$arquivosCorrigidos = 0
$totalSubstituicoes = 0

# Lista de arquivos para corrigir
$arquivos = @(
    "lib\utils\context_debug.dart",
    "lib\views\welcome_view.dart",
    "lib\views\spiritual_certification_request_view.dart",
    "lib\views\username_settings_view.dart",
    "lib\views\unified_notifications_view.dart",
    "lib\views\story_favorites_view.dart",
    "lib\views\storie_view.dart",
    "lib\views\stories_viewer_view.dart",
    "lib\views\stories_view.dart",
    "lib\views\sinais_rebeca_view.dart",
    "lib\views\sinais_isaque_view.dart",
    "lib\views\robust_match_chat_view.dart"
)

foreach ($arquivo in $arquivos) {
    if (-not (Test-Path $arquivo)) {
        Write-Host "Arquivo nao encontrado: $arquivo" -ForegroundColor Yellow
        continue
    }

    Write-Host "Processando: $arquivo" -ForegroundColor White
    
    try {
        $conteudo = Get-Content $arquivo -Raw -Encoding UTF8
        $conteudoOriginal = $conteudo
        
        # Contar print antes
        $printsBefore = ([regex]::Matches($conteudo, "(?<!safe)print\(")).Count
        
        if ($printsBefore -gt 0) {
            # Substituir print por safePrint
            $conteudo = $conteudo -replace "(?<!safe)print\(", "safePrint("
            
            # Adicionar import se necessario
            if ($conteudo -match "safePrint\(" -and $conteudo -notmatch "import 'package:whatsapp_chat/utils/debug_utils\.dart';") {
                # Encontrar ultima linha de import
                $lines = $conteudo -split "`r?`n"
                $lastImportIndex = -1
                
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match "^import ") {
                        $lastImportIndex = $i
                    }
                }
                
                if ($lastImportIndex -ge 0) {
                    $lines = $lines[0..$lastImportIndex] + "import 'package:whatsapp_chat/utils/debug_utils.dart';" + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
                    $conteudo = $lines -join "`n"
                    Write-Host "  Import adicionado" -ForegroundColor Green
                }
            }
            
            # Salvar arquivo
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($conteudo)
            [System.IO.File]::WriteAllBytes($arquivo, $bytes)
            
            Write-Host "  $printsBefore print substituidos" -ForegroundColor Green
            $arquivosCorrigidos++
            $totalSubstituicoes += $printsBefore
        } else {
            Write-Host "  Nenhuma mudanca necessaria" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "  Erro ao processar: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "RESUMO:" -ForegroundColor Cyan
Write-Host "  Arquivos corrigidos: $arquivosCorrigidos" -ForegroundColor White
Write-Host "  Total de substituicoes: $totalSubstituicoes" -ForegroundColor White
Write-Host ""
Write-Host "PROXIMO PASSO:" -ForegroundColor Yellow
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter build apk --release" -ForegroundColor White
Write-Host ""
Write-Host "Pronto! Os logs devem sumir em release mode!" -ForegroundColor Green
