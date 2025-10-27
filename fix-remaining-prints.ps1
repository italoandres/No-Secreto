# Script para corrigir os prints restantes em arquivos Dart
# Substitui print() por safePrint() e adiciona import do debug_utils.dart

$arquivos = @(
    "lib\views\enhanced_stories_viewer_view.dart",
    "lib\views\home_view.dart",
    "lib\views\interest_dashboard_view.dart",
    "lib\views\match_chat_view.dart"
)

foreach ($arquivo in $arquivos) {
    Write-Host "Processando: $arquivo" -ForegroundColor Cyan
    
    if (Test-Path $arquivo) {
        $conteudo = Get-Content $arquivo -Raw -Encoding UTF8
        
        # Adicionar import se não existir
        if ($conteudo -notmatch "import.*debug_utils\.dart") {
            # Encontrar a última linha de import
            $linhas = $conteudo -split "`n"
            $ultimoImportIndex = -1
            
            for ($i = 0; $i -lt $linhas.Count; $i++) {
                if ($linhas[$i] -match "^import ") {
                    $ultimoImportIndex = $i
                }
            }
            
            if ($ultimoImportIndex -ge 0) {
                # Inserir import após o último import existente
                $linhas = $linhas[0..$ultimoImportIndex] + "import '../utils/debug_utils.dart';" + $linhas[($ultimoImportIndex + 1)..($linhas.Count - 1)]
                $conteudo = $linhas -join "`n"
                Write-Host "  ✓ Import adicionado" -ForegroundColor Green
            }
        }
        
        # Substituir print( por safePrint(
        $antes = ($conteudo -split "print\(" | Measure-Object).Count - 1
        $conteudo = $conteudo -replace '\bprint\(', 'safePrint('
        $depois = ($conteudo -split "safePrint\(" | Measure-Object).Count - 1
        
        # Salvar arquivo
        [System.IO.File]::WriteAllText($arquivo, $conteudo, [System.Text.Encoding]::UTF8)
        
        Write-Host "  ✓ $antes prints substituídos" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Arquivo não encontrado" -ForegroundColor Red
    }
}

Write-Host "`n✅ CONCLUÍDO!" -ForegroundColor Green
Write-Host "Todos os prints foram substituídos por safePrint()" -ForegroundColor Green
Write-Host "`nPróximo passo:" -ForegroundColor Yellow
Write-Host "flutter clean" -ForegroundColor Cyan
Write-Host "flutter build apk --release" -ForegroundColor Cyan
