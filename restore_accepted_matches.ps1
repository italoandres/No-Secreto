Write-Host "REVERTENDO ERRO - Restaurando rota accepted-matches..." -ForegroundColor Red

$arquivo = "lib\main.dart"
$conteudo = Get-Content $arquivo -Raw

# Restaurar GetPage comentado
$comentado = @"
      // REMOVIDO FASE 3:
      // GetPage(
      //   name: '/accepted-matches',
      //   page: () => const SimpleAcceptedMatchesView(),
      //   transition: Transition.rightToLeft,
      //   transitionDuration: const Duration(milliseconds: 300),
      // ),
"@

$restaurado = @"
      GetPage(
        name: '/accepted-matches',
        page: () => const SimpleAcceptedMatchesView(),
        transition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 300),
      ),
"@

$conteudo = $conteudo -replace [regex]::Escape($comentado), $restaurado

Set-Content $arquivo $conteudo -NoNewline

Write-Host "OK! Rota restaurada" -ForegroundColor Green
Write-Host ""
Write-Host "Teste: flutter run" -ForegroundColor Cyan