# FASE 3 CONSERVADORA - Limpar apenas main.dart

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "FASE 3 CONSERVADORA: Limpando main.dart" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Backup
$backupDir = ".backups_fase3_conservadora"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$arquivo = "lib\main.dart"
Copy-Item $arquivo "$backupDir\main_backup.dart"
Write-Host "Backup criado: $backupDir\main_backup.dart" -ForegroundColor Green
Write-Host ""

# Ler conteudo
$conteudo = Get-Content $arquivo -Raw

Write-Host "Removendo imports debug/test do main.dart..." -ForegroundColor Yellow

# Remover imports debug/test
$conteudo = $conteudo -replace "import '/test_onboarding\.dart';\s*", ""
$conteudo = $conteudo -replace "import '/views/simple_accepted_matches_view\.dart';\s*", ""
$conteudo = $conteudo -replace "import '/utils/test_vitrine_complete_search\.dart';.*?\n", ""
$conteudo = $conteudo -replace "import '/utils/deep_vitrine_investigation\.dart';.*?\n", ""
$conteudo = $conteudo -replace "import '/utils/simple_vitrine_debug\.dart';.*?\n", ""
$conteudo = $conteudo -replace "import '/utils/dual_collection_debug\.dart';.*?\n", ""
$conteudo = $conteudo -replace "import '/utils/force_notifications_now\.dart';.*?\n", ""
$conteudo = $conteudo -replace "import '/utils/fix_timestamp_chat_errors\.dart';.*?\n", ""

Write-Host "Comentando codigo relacionado..." -ForegroundColor Yellow

# Comentar codigo que usa essas classes
$conteudo = $conteudo -replace "TestVitrineCompleteSearch\.registerGlobalTestFunction\(\);", "// REMOVIDO FASE 3: TestVitrineCompleteSearch.registerGlobalTestFunction();"
$conteudo = $conteudo -replace "DeepVitrineInvestigation\.registerConsoleFunction\(\);", "// REMOVIDO FASE 3: DeepVitrineInvestigation.registerConsoleFunction();"

# Comentar rota SimpleAcceptedMatchesView
$conteudo = $conteudo -replace "page: \(\) => const SimpleAcceptedMatchesView\(\),", "// REMOVIDO FASE 3: page: () => const SimpleAcceptedMatchesView(),"

# Salvar
Set-Content $arquivo $conteudo -NoNewline

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Green
Write-Host "PRONTO!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Green
Write-Host ""
Write-Host "Imports removidos: 8" -ForegroundColor Cyan
Write-Host "Codigo comentado: 3 linhas" -ForegroundColor Cyan
Write-Host ""
Write-Host "PROXIMO PASSO:" -ForegroundColor Yellow
Write-Host "  flutter run" -ForegroundColor White
Write-Host ""
Write-Host "Se funcionar, podemos continuar limpando outros arquivos!" -ForegroundColor Cyan
Write-Host ""