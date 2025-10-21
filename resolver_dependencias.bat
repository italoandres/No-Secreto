@echo off
echo 🔧 Resolvendo conflitos de dependências...
echo.
echo ✅ CORREÇÕES APLICADAS:
echo    - http: ^0.13.6 (compatível com firebase_admin)
echo    - cached_network_image: ^3.3.1 (compatível com http ^0.13.6)
echo    - dio: ^5.1.2 (versão estável)
echo.

REM Tentar encontrar o Flutter automaticamente
set FLUTTER_PATH=
if exist "C:\flutter\bin\flutter.exe" set FLUTTER_PATH=C:\flutter\bin\flutter.exe
if exist "C:\src\flutter\bin\flutter.exe" set FLUTTER_PATH=C:\src\flutter\bin\flutter.exe
if exist "C:\tools\flutter\bin\flutter.exe" set FLUTTER_PATH=C:\tools\flutter\bin\flutter.exe

if "%FLUTTER_PATH%"=="" (
    echo ❌ Flutter não encontrado nos caminhos padrão.
    echo 💡 Tente executar manualmente:
    echo    [CAMINHO_DO_FLUTTER]\bin\flutter clean
    echo    [CAMINHO_DO_FLUTTER]\bin\flutter pub get
    echo    [CAMINHO_DO_FLUTTER]\bin\flutter run
    pause
    exit /b 1
)

echo ✅ Flutter encontrado em: %FLUTTER_PATH%
echo.

echo ✅ Limpando cache e arquivos antigos...
"%FLUTTER_PATH%" clean

echo.
echo ✅ Baixando dependências compatíveis...
"%FLUTTER_PATH%" pub get

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ ERRO: Ainda há conflitos de dependências!
    echo 💡 Tente executar: "%FLUTTER_PATH%" pub upgrade --major-versions
    pause
    exit /b 1
)

echo.
echo ✅ Verificando se há problemas...
"%FLUTTER_PATH%" doctor

echo.
echo 🎯 Tudo OK! Agora você pode executar:
echo    "%FLUTTER_PATH%" run
echo    ou
echo    "%FLUTTER_PATH%" run -d chrome (para web)

pause