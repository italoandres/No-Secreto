# Script para substituir TODOS os debugPrint por safePrint
# E adicionar imports necessários

Write-Host "🔧 CORREÇÃO MASSIVA: debugPrint → safePrint" -ForegroundColor Cyan
Write-Host ""

$arquivosCorrigidos = 0
$debugPrintsSubstituidos = 0
$printsSubstituidos = 0
$importsAdicionados = 0

# Lista de arquivos para corrigir (baseado na busca)
$arquivos = @(
    "lib\repositories\login_repository.dart",
    "lib\services\online_status_service.dart",
    "lib\utils\context_debug.dart",
    "lib\views\robust_match_chat_view.dart",
    "lib\views\sinais_isaque_view.dart",
    "lib\views\spiritual_certification_request_view.dart",
    "lib\views\stories_view.dart",
    "lib\views\story_favorites_view.dart",
    "lib\views\username_settings_view.dart",
    "lib\views\unified_notifications_view.dart",
    "lib\views\storie_view.dart",
    "lib\views\welcome_view.dart",
    "lib\views\stories_viewer_view.dart"
)

foreach ($arquivo in $arquivos) {
    if (-not (Test-Path $arquivo)) {
        Write-Host "⚠️ Arquivo não encontrado: $arquivo" -ForegroundColor Yellow
        continue
    }

    Write-Host "📝 Processando: $arquivo" -ForegroundColor White
    
    $conteudo = Get-Content $arquivo -Raw -Encoding UTF8
    $conteudoOriginal = $conteudo
    
    # Contar ocorrências antes
    $debugPrintsBefore = ([regex]::Matches($conteudo, "debugPrint\(")).Count
    $printsBefore = ([regex]::Matches($conteudo, "(?<!safe)print\(")).Count
    
    # 1. Substituir debugPrint por safePrint (exceto em debug_utils.dart)
    if ($arquivo -notlike "*debug_utils.dart") {
        $conteudo = $conteudo -replace "debugPrint\(", "safePrint("
        $debugPrintsSubstituidos += $debugPrintsBefore
    }
    
    # 2. Substituir print( por safePrint( (exceto em debug_utils.dart e context_debug.dart)
    if ($arquivo -notlike "*debug_utils.dart" -and $arquivo -notlike "*context_debug.dart") {
        # Substituir print( por safePrint(, mas não safePrint( que já existe
        $conteudo = $conteudo -replace "(?<!safe)print\(", "safePrint("
        $printsSubstituidos += $printsBefore
    }
    
    # 3. Adicionar import se necessário
    $precisaImport = $false
    
    # Verificar se tem safePrint no código
    if ($conteudo -match "safePrint\(") {
        # Verificar se já tem o import
        if ($conteudo -notmatch "import 'package:whatsapp_chat/utils/debug_utils\.dart';") {
            $precisaImport = $true
        }
    }
    
    if ($precisaImport) {
        # Encontrar a posição após os imports existentes
        $lines = $conteudo -split "`n"
        $lastImportIndex = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^import ") {
                $lastImportIndex = $i
            }
        }
        
        if ($lastImportIndex -ge 0) {
            # Adicionar após o último import
            $lines = $lines[0..$lastImportIndex] + "import 'package:whatsapp_chat/utils/debug_utils.dart';" + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
            $conteudo = $lines -join "`n"
            $importsAdicionados++
            Write-Host "  ✅ Import adicionado" -ForegroundColor Green
        }
    }
    
    # Salvar se houve mudanças
    if ($conteudo -ne $conteudoOriginal) {
        Set-Content $arquivo -Value $conteudo -Encoding UTF8 -NoNewline
        $arquivosCorrigidos++
        Write-Host "  ✅ Arquivo corrigido" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️ Nenhuma mudança necessária" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "📊 RESUMO DA CORREÇÃO:" -ForegroundColor Cyan
Write-Host "  Arquivos corrigidos: $arquivosCorrigidos" -ForegroundColor White
Write-Host "  debugPrint substituídos: $debugPrintsSubstituidos" -ForegroundColor White
Write-Host "  print substituídos: $printsSubstituidos" -ForegroundColor White
Write-Host "  Imports adicionados: $importsAdicionados" -ForegroundColor White
Write-Host ""
Write-Host "🎯 PRÓXIMO PASSO:" -ForegroundColor Yellow
Write-Host "Execute: flutter build apk --release" -ForegroundColor White
Write-Host "Ou: flutter run --release" -ForegroundColor White
Write-Host ""
Write-Host "✅ Os logs devem SUMIR em release mode!" -ForegroundColor Green
