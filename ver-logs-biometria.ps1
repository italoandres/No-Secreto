# Script para ver logs de biometria no celular
# Execute este script DEPOIS de abrir o app no celular

Write-Host "🔍 Conectando ao logcat..." -ForegroundColor Cyan
Write-Host "📱 Certifique-se que o celular está conectado via USB" -ForegroundColor Yellow
Write-Host ""
Write-Host "Aguardando logs... (Clique no botão 'Usar Biometria' agora)" -ForegroundColor Green
Write-Host ""

# Limpar logs antigos primeiro
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -c

# Mostrar apenas logs do Flutter
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -s flutter:V
