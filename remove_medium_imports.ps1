# FASE 2 - Remover imports

Write-Host "Removendo imports..." -ForegroundColor Cyan

# Criar backup
$backupDir = ".backups_fase2"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# Arquivo 1: chat_view.dart
$arquivo1 = "lib\views\chat_view.dart"
if (Test-Path $arquivo1) {
    Write-Host "Processando chat_view.dart" -ForegroundColor Yellow
    Copy-Item $arquivo1 "$backupDir\chat_view_backup.dart"
    
    $conteudo = Get-Content $arquivo1 -Raw
    $conteudo = $conteudo -replace "import 'package:app_no_secreto/utils/debug_user_state.dart';", ""
    $conteudo = $conteudo -replace "import 'package:app_no_secreto/views/fix_button_screen.dart';", ""
    Set-Content $arquivo1 $conteudo -NoNewline
    
    Write-Host "OK - chat_view.dart" -ForegroundColor Green
}

# Arquivo 2: notifications_view_backup.dart
$arquivo2 = "lib\views\notifications_view_backup.dart"
if (Test-Path $arquivo2) {
    Write-Host "Processando notifications_view_backup.dart" -ForegroundColor Yellow
    Copy-Item $arquivo2 "$backupDir\notifications_view_backup_backup.dart"
    
    $conteudo = Get-Content $arquivo2 -Raw
    $conteudo = $conteudo -replace "import 'package:app_no_secreto/utils/test_notifications.dart';", ""
    Set-Content $arquivo2 $conteudo -NoNewline
    
    Write-Host "OK - notifications_view_backup.dart" -ForegroundColor Green
}

# Arquivo 3: routes.dart (CRITICO!)
$arquivo3 = "lib\routes.dart"
if (Test-Path $arquivo3) {
    Write-Host "Processando routes.dart (CRITICO!)" -ForegroundColor Yellow
    Copy-Item $arquivo3 "$backupDir\routes_backup.dart"
    
    $conteudo = Get-Content $arquivo3 -Raw
    $conteudo = $conteudo -replace "import 'package:app_no_secreto/views/debug_online_status_view.dart';", ""
    Set-Content $arquivo3 $conteudo -NoNewline
    
    Write-Host "OK - routes.dart" -ForegroundColor Green
}

# Arquivo 4: home_view.dart
$arquivo4 = "lib\views\home_view.dart"
if (Test-Path $arquivo4) {
    Write-Host "Processando home_view.dart" -ForegroundColor Yellow
    Copy-Item $arquivo4 "$backupDir\home_view_backup.dart"
    
    $conteudo = Get-Content $arquivo4 -Raw
    $conteudo = $conteudo -replace "import 'package:app_no_secreto/views/test_notifications_button_view.dart';", ""
    Set-Content $arquivo4 $conteudo -NoNewline
    
    Write-Host "OK - home_view.dart" -ForegroundColor Green
}

Write-Host ""
Write-Host "PRONTO! Backups em: .backups_fase2" -ForegroundColor Green
Write-Host ""
Write-Host "PROXIMO PASSO: flutter run" -ForegroundColor Cyan