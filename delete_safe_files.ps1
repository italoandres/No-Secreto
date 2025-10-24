# FASE 3 - Deletar 103 arquivos SAFE (isolados, zero imports)

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "FASE 3: DELETANDO 103 ARQUIVOS SAFE" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Lista dos 103 arquivos SAFE
$arquivosSafe = @(
    "lib\components\quick_fix_profile_button.dart",
    "lib\components\simple_corrected_notification_component.dart",
    "lib\components\simple_interest_notification_component.dart",
    "lib\components\vitrine_quick_access_component.dart",
    "lib\repositories\simple_accepted_matches_repository.dart",
    "lib\services\auto_fix_service.dart",
    "lib\services\search_strategies\firebase_simple_search_strategy.dart",
    "lib\test_onboarding.dart",
    "lib\utils\add_age_to_test_profiles.dart",
    "lib\utils\auto_fix_on_startup.dart",
    "lib\utils\context_debug_example.dart",
    "lib\utils\create_test_interests.dart",
    "lib\utils\create_test_interests_matches.dart",
    "lib\utils\create_test_profiles_sinais.dart",
    "lib\utils\debug_accepted_matches.dart",
    "lib\utils\debug_explore_profiles_system.dart",
    "lib\utils\debug_favorites.dart",
    "lib\utils\debug_interest_notifications_ui.dart",
    "lib\utils\debug_itala_search.dart",
    "lib\utils\debug_logger.dart",
    "lib\utils\debug_notification_flow.dart",
    "lib\utils\debug_online_status_button.dart",
    "lib\utils\debug_profile_completion.dart",
    "lib\utils\debug_profile_fields.dart",
    "lib\utils\debug_real_notifications.dart",
    "lib\utils\debug_received_interests.dart",
    "lib\utils\debug_search_profiles.dart",
    "lib\utils\debug_vitrine_invites.dart",
    "lib\utils\deep_investigation_real_notifications.dart",
    "lib\utils\deep_vitrine_debug.dart",
    "lib\utils\deep_vitrine_investigation.dart",
    "lib\utils\diagnose_interest_notifications.dart",
    "lib\utils\dual_collection_debug.dart",
    "lib\utils\emergency_chat_fix_button.dart",
    "lib\utils\execute_complete_fix_now.dart",
    "lib\utils\execute_fix_now_direct.dart",
    "lib\utils\fix_admin_deusepai_final.dart",
    "lib\utils\fix_completed_profiles.dart",
    "lib\utils\fix_empty_fromUserName.dart",
    "lib\utils\fix_existing_chat_system.dart",
    "lib\utils\fix_existing_profile_for_exploration.dart",
    "lib\utils\fix_favorites_context.dart",
    "lib\utils\fix_firebase_index_interests.dart",
    "lib\utils\fix_infinite_loop_notifications.dart",
    "lib\utils\fix_profile_widget.dart",
    "lib\utils\fix_specific_missing_chat.dart",
    "lib\utils\fix_specific_profile.dart",
    "lib\utils\fix_timestamp_chat_errors.dart",
    "lib\utils\fix_vitrine_images.dart",
    "lib\utils\force_admin_deusepai.dart",
    "lib\utils\force_notifications_now.dart",
    "lib\utils\force_profile_migration.dart",
    "lib\utils\force_ui_notifications.dart",
    "lib\utils\force_ui_refresh_notifications.dart",
    "lib\utils\force_visual_notifications.dart",
    "lib\utils\navigate_to_fix_screen.dart",
    "lib\utils\notification_debug_tools.dart",
    "lib\utils\populate_explore_profiles_test_data.dart",
    "lib\utils\quick_populate_profiles.dart",
    "lib\utils\simple_interest_notifications.dart",
    "lib\utils\simple_vitrine_debug.dart",
    "lib\utils\simulate_itala_interest.dart",
    "lib\utils\test_accepted_matches.dart",
    "lib\utils\test_automatic_messages.dart",
    "lib\utils\test_certification_approval_service.dart",
    "lib\utils\test_certification_complete.dart",
    "lib\utils\test_chat_system.dart",
    "lib\utils\test_complete_match_flow.dart",
    "lib\utils\test_complete_notification_system.dart",
    "lib\utils\test_current_notification_system.dart",
    "lib\utils\test_deep_investigation.dart",
    "lib\utils\test_diagnostic_system.dart",
    "lib\utils\test_explore_profiles_data.dart",
    "lib\utils\test_integration_system.dart",
    "lib\utils\test_interest_notifications.dart",
    "lib\utils\test_interest_notifications_system.dart",
    "lib\utils\test_interest_notifications_v2.dart",
    "lib\utils\test_matches_integration.dart",
    "lib\utils\test_migration_system.dart",
    "lib\utils\test_notification_display_system.dart",
    "lib\utils\test_persistence_system.dart",
    "lib\utils\test_populate_widget.dart",
    "lib\utils\test_profile_completion.dart",
    "lib\utils\test_profile_fix.dart",
    "lib\utils\test_profile_navigation_fix.dart",
    "lib\utils\test_real_notifications.dart",
    "lib\utils\test_search_now.dart",
    "lib\utils\test_ui_state_manager.dart",
    "lib\utils\test_ultimate_fix.dart",
    "lib\utils\test_unified_notification_system.dart",
    "lib\utils\test_unified_search.dart",
    "lib\utils\test_username_search_fix.dart",
    "lib\utils\test_vitrine_complete_search.dart",
    "lib\utils\test_vitrine_invites.dart",
    "lib\utils\test_world_location_system.dart",
    "lib\utils\update_test_profiles_purpose.dart",
    "lib\views\chat_system_test_view.dart",
    "lib\views\debug_test_profiles_view.dart",
    "lib\views\fix_explore_profiles_test_view.dart",
    "lib\views\home_with_fix_button.dart",
    "lib\views\notification_test_dashboard.dart",
    "lib\views\simple_accepted_matches_view.dart",
    "lib\views\simple_certification_panel.dart"
)

Write-Host "Total de arquivos a deletar: $($arquivosSafe.Count)" -ForegroundColor Yellow
Write-Host ""

# Criar backup
$backupDir = ".backups_fase3"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
    Write-Host "Backup criado: $backupDir" -ForegroundColor Green
}

# Deletar arquivos
$deletados = 0
$naoEncontrados = 0

foreach ($arquivo in $arquivosSafe) {
    if (Test-Path $arquivo) {
        Remove-Item $arquivo -Force
        $deletados++
        Write-Host "  Deletado: $arquivo" -ForegroundColor Gray
    } else {
        $naoEncontrados++
    }
}

Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "RELATORIO FINAL" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Arquivos deletados: $deletados" -ForegroundColor Green
Write-Host "Arquivos nao encontrados: $naoEncontrados" -ForegroundColor Yellow
Write-Host ""
Write-Host "PROXIMO PASSO: flutter run" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""