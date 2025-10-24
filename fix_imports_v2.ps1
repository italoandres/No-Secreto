Write-Host "Corrigindo imports e comentando codigo..." -ForegroundColor Cyan

# chat_view.dart
$arquivo = "lib\views\chat_view.dart"
if (Test-Path $arquivo) {
    Write-Host "Processando chat_view.dart..." -ForegroundColor Cyan
    $conteudo = Get-Content $arquivo -Raw
    
    # Remover imports extras
    $conteudo = $conteudo -replace "import 'package:whatsapp_chat/utils/debug_user_state\.dart';\s*", ""
    $conteudo = $conteudo -replace "import 'package:whatsapp_chat/views/fix_button_screen\.dart';\s*", ""
    
    # Comentar codigo
    $conteudo = $conteudo -replace "Get\.to\(\(\) => const FixButtonScreen\(\)\);", "// REMOVIDO: Get.to(() => const FixButtonScreen());"
    $conteudo = $conteudo -replace "await DebugUserState\.printCurrentUserState\(\);", "// REMOVIDO: await DebugUserState.printCurrentUserState();"
    $conteudo = $conteudo -replace "await DebugUserState\.fixUserSexo\(\);", "// REMOVIDO: await DebugUserState.fixUserSexo();"
    
    Set-Content $arquivo $conteudo -NoNewline
    Write-Host "OK" -ForegroundColor Green
}

# home_view.dart
$arquivo = "lib\views\home_view.dart"
if (Test-Path $arquivo) {
    Write-Host "Processando home_view.dart..." -ForegroundColor Cyan
    $conteudo = Get-Content $arquivo -Raw
    
    $conteudo = $conteudo -replace "import 'package:whatsapp_chat/views/test_notifications_button_view\.dart';\s*", ""
    $conteudo = $conteudo -replace "builder: \(context\) => const TestNotificationsButtonView\(\),", "// REMOVIDO: builder: (context) => const TestNotificationsButtonView(),"
    
    Set-Content $arquivo $conteudo -NoNewline
    Write-Host "OK" -ForegroundColor Green
}

# routes.dart
$arquivo = "lib\routes.dart"
if (Test-Path $arquivo) {
    Write-Host "Processando routes.dart..." -ForegroundColor Cyan
    $conteudo = Get-Content $arquivo -Raw
    
    $conteudo = $conteudo -replace "import 'package:whatsapp_chat/views/debug_online_status_view\.dart';\s*", ""
    $conteudo = $conteudo -replace "debugOnlineStatus: const DebugOnlineStatusView\(\),", "// REMOVIDO: debugOnlineStatus: const DebugOnlineStatusView(),"
    
    Set-Content $arquivo $conteudo -NoNewline
    Write-Host "OK" -ForegroundColor Green
}

# notifications_view_backup.dart
$arquivo = "lib\views\notifications_view_backup.dart"
if (Test-Path $arquivo) {
    Write-Host "Processando notifications_view_backup.dart..." -ForegroundColor Cyan
    $conteudo = Get-Content $arquivo -Raw
    
    $conteudo = $conteudo -replace "import 'package:whatsapp_chat/utils/test_notifications\.dart';\s*", ""
    
    Set-Content $arquivo $conteudo -NoNewline
    Write-Host "OK" -ForegroundColor Green
}

Write-Host ""
Write-Host "PRONTO! Agora teste: flutter run" -ForegroundColor Green