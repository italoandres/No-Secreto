# Script para adicionar import do debug_utils.dart em todos os arquivos que usam safePrint

$files = @(
    'lib/main.dart',
    'lib/controllers/notification_controller.dart',
    'lib/repositories/stories_repository.dart',
    'lib/repositories/usuario_repository.dart',
    'lib/controllers/login_controller.dart',
    'lib/utils/enhanced_logger.dart',
    'lib/repositories/spiritual_profile_repository.dart',
    'lib/components/profile_header_section.dart',
    'lib/controllers/profile_display_controller.dart',
    'lib/repositories/simple_accepted_matches_repository.dart',
    'lib/views/chat_view.dart',
    'lib/services/data_migration_service.dart',
    'lib/repositories/temporary_chat_repository.dart',
    'lib/views/stories_view.dart',
    'lib/views/enhanced_stories_viewer_view.dart',
    'lib/views/profile_completion_view.dart',
    'lib/services/match_chat_service.dart',
    'lib/utils/enhanced_image_loader.dart',
    'lib/components/story_comments_component.dart',
    'lib/utils/firebase_image_loader.dart',
    'lib/controllers/profile_completion_controller.dart',
    'lib/services/chat_expiration_service.dart',
    'lib/views/simple_accepted_matches_view.dart',
    'lib/controllers/profile_photos_task_controller.dart'
)

$importLine = "import 'package:whatsapp_chat/utils/debug_utils.dart';"
$count = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # Verifica se já tem o import
        if ($content -notmatch [regex]::Escape($importLine)) {
            # Encontra a última linha de import
            $lines = $content -split "`n"
            $lastImportIndex = -1
            
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "^import ") {
                    $lastImportIndex = $i
                }
            }
            
            if ($lastImportIndex -ge 0) {
                # Insere após o último import
                $newLines = @()
                $newLines += $lines[0..$lastImportIndex]
                $newLines += $importLine
                if ($lastImportIndex + 1 -lt $lines.Length) {
                    $newLines += $lines[($lastImportIndex + 1)..($lines.Length - 1)]
                }
                
                $newContent = $newLines -join "`n"
                Set-Content $file -Value $newContent -Encoding UTF8 -NoNewline
                Write-Host "✅ $file" -ForegroundColor Green
                $count++
            }
        } else {
            Write-Host "⏭️  $file (já tem import)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ $file (não encontrado)" -ForegroundColor Red
    }
}

Write-Host "`n✨ Concluído! $count arquivos atualizados" -ForegroundColor Cyan
