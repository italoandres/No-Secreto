@echo off
echo ========================================
echo  GERAR APK LIMPO - Flutter
echo ========================================
echo.
echo Este script vai:
echo 1. Limpar cache do Flutter
echo 2. Obter dependencias
echo 3. Gerar APK release
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
echo [3/3] Gerando APK...
echo.
echo AGUARDE: Este processo pode demorar varios minutos...
echo.

flutter build apk --release

echo.
echo ========================================
echo  APK gerado com sucesso!
echo ========================================
echo.
echo Localizacao: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
