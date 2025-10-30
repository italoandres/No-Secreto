@echo off
echo ========================================
echo  REBUILD COMPLETO - Flutter
echo ========================================
echo.
echo Este script vai:
echo 1. Limpar cache do Flutter
echo 2. Obter dependencias
echo 3. Executar no Chrome
echo.
echo Pressione qualquer tecla para continuar...
pause > nul

echo.
echo [1/3] Limpando cache...
flutter clean

echo.
echo [2/3] Obtendo dependencias...
flutter pub get

echo.
echo [3/3] Executando no Chrome...
echo.
echo IMPORTANTE: Quando o Chrome abrir:
echo - Pressione F12 para abrir DevTools
echo - Va na aba Network
echo - Marque "Disable cache"
echo.
echo Pressione qualquer tecla para iniciar...
pause > nul

flutter run -d chrome

echo.
echo ========================================
echo  Processo concluido!
echo ========================================
pause
