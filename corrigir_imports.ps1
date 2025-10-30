# Script PowerShell para adicionar imports automaticamente
# Salve como: corrigir_imports.ps1

Write-Host "🚀 CORRETOR AUTOMÁTICO DE IMPORTS" -ForegroundColor Cyan
Write-Host ""

# Configurações - AJUSTE ESTE CAMINHO SE NECESSÁRIO
$projectRoot = "C:\Users\ItaloLior\Downloads\whatsapp_chat-main\whatsapp_chat-main"
$libFolder = Join-Path $projectRoot "lib"
$importLine = "import 'package:whatsapp_chat/utils/debug_utils.dart';`n"

# Verificar se a pasta existe
if (-not (Test-Path $libFolder)) {
    Write-Host "❌ ERRO: Pasta não encontrada: $libFolder" -ForegroundColor Red
    Write-Host "Edite o script e ajuste a variável `$projectRoot" -ForegroundColor Yellow
    exit 1
}

# Verificar se debug_utils.dart existe
$debugUtilsPath = Join-Path $libFolder "utils\debug_utils.dart"
if (-not (Test-Path $debugUtilsPath)) {
    Write-Host "❌ ERRO: Arquivo não encontrado: $debugUtilsPath" -ForegroundColor Red
    Write-Host "Certifique-se de que você copiou o debug_utils.dart para lib\utils\" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Arquivo debug_utils.dart encontrado!" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Procurando arquivos com safePrint..." -ForegroundColor Yellow
Write-Host "📂 Pasta: $libFolder" -ForegroundColor Gray
Write-Host ""

$filesProcessed = 0
$filesSkipped = 0
$filesFixed = 0

# Percorrer todos os arquivos .dart
Get-ChildItem -Path $libFolder -Filter *.dart -Recurse | ForEach-Object {
    $file = $_
    $filesProcessed++
    
    # Ler conteúdo do arquivo
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    # Verificar se usa safePrint
    if ($content -match 'safePrint\(') {
        $relativePath = $file.FullName.Replace($projectRoot + "\", "")
        
        # Verificar se já tem o import
        if ($content -match 'debug_utils\.dart') {
            Write-Host "✅ $relativePath - já tem import" -ForegroundColor Gray
            $filesSkipped++
        }
        else {
            Write-Host "🔧 $relativePath - adicionando import..." -ForegroundColor Yellow
            
            try {
                # Ler linhas do arquivo
                $lines = Get-Content $file.FullName -Encoding UTF8
                
                # Encontrar posição para adicionar o import
                $insertPosition = 0
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match "^import ") {
                        $insertPosition = $i + 1
                    }
                    elseif ($lines[$i].Trim() -and $lines[$i].Trim() -notmatch "^//") {
                        break
                    }
                }
                
                # Adicionar o import
                $newLines = @()
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($i -eq $insertPosition) {
                        $newLines += $importLine
                    }
                    $newLines += $lines[$i]
                }
                
                # Se não encontrou posição, adicionar no início
                if ($insertPosition -eq 0) {
                    $newLines = @($importLine) + $lines
                }
                
                # Salvar arquivo
                $newLines | Set-Content $file.FullName -Encoding UTF8
                
                Write-Host "   ✅ Import adicionado!" -ForegroundColor Green
                $filesFixed++
            }
            catch {
                Write-Host "   ❌ Falha ao adicionar import: $_" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "📊 RESUMO:" -ForegroundColor Cyan
Write-Host "   Arquivos processados: $filesProcessed" -ForegroundColor White
Write-Host "   Arquivos que já tinham import: $filesSkipped" -ForegroundColor Gray
Write-Host "   Arquivos corrigidos: $filesFixed" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

if ($filesFixed -gt 0) {
    Write-Host ""
    Write-Host "✅ PRONTO! Agora compile novamente:" -ForegroundColor Green
    Write-Host ""
    Write-Host "   flutter clean" -ForegroundColor Yellow
    Write-Host "   flutter pub get" -ForegroundColor Yellow
    Write-Host "   flutter build apk --release" -ForegroundColor Yellow
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "⚠️ Nenhum arquivo foi corrigido." -ForegroundColor Yellow
    Write-Host "Verifique se:" -ForegroundColor Yellow
    Write-Host "  1. O arquivo debug_utils.dart existe em lib\utils\" -ForegroundColor Gray
    Write-Host "  2. Os arquivos realmente usam safePrint" -ForegroundColor Gray
}
