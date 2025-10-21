@echo off
echo ========================================
echo   ATUALIZACAO DE HOBBIES - PERFIS
echo ========================================
echo.
echo Este script adiciona hobbies aos perfis de teste.
echo.
echo Pressione qualquer tecla para continuar...
pause > nul

echo.
echo Executando atualizacao...
echo.

flutter run -d chrome --dart-define=UPDATE_HOBBIES=true

echo.
echo ========================================
echo   ATUALIZACAO CONCLUIDA!
echo ========================================
echo.
echo Os perfis agora tem hobbies definidos.
echo Voce vera a secao "Hobbies" nos cards.
echo.
pause
