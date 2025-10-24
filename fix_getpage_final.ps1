Write-Host "Corrigindo GetPage de accepted-matches..." -ForegroundColor Cyan

$arquivo = "lib\main.dart"
$conteudo = Get-Content $arquivo -Raw

# Padrão exato do GetPage quebrado
$antigo = @"
      GetPage(
        name: '/accepted-matches',
        // REMOVIDO FASE 3: page: () => const SimpleAcceptedMatchesView(),
        transition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 300),
      ),
"@

$novo = @"
      // REMOVIDO FASE 3: GetPage accepted-matches
      // GetPage(
      //   name: '/accepted-matches',
      //   page: () => const SimpleAcceptedMatchesView(),
      //   transition: Transition.rightToLeft,
      //   transitionDuration: const Duration(milliseconds: 300),
      // ),
"@

$conteudo = $conteudo -replace [regex]::Escape($antigo), $novo

Set-Content $arquivo $conteudo -NoNewline

Write-Host "OK! GetPage comentado completamente" -ForegroundColor Green
Write-Host ""
Write-Host "Teste: flutter run" -ForegroundColor Cyan