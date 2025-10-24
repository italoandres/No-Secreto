Write-Host "Corrigindo main.dart - comentando GetPage completo..." -ForegroundColor Cyan

$arquivo = "lib\main.dart"
$conteudo = Get-Content $arquivo -Raw

# Encontrar e comentar o GetPage completo de SimpleAcceptedMatchesView
# Procurar por padrão GetPage com name e page comentado

# Padrão: GetPage com múltiplas linhas
$pattern = @"
      GetPage\(
        name: '/simple-accepted-matches',
        // REMOVIDO FASE 3: page: \(\) => const SimpleAcceptedMatchesView\(\),
      \),
"@

$replacement = @"
      // REMOVIDO FASE 3: GetPage SimpleAcceptedMatchesView
      // GetPage(
      //   name: '/simple-accepted-matches',
      //   page: () => const SimpleAcceptedMatchesView(),
      // ),
"@

$conteudo = $conteudo -replace [regex]::Escape($pattern), $replacement

Set-Content $arquivo $conteudo -NoNewline

Write-Host "OK! GetPage completo comentado" -ForegroundColor Green
Write-Host ""
Write-Host "Agora teste: flutter run" -ForegroundColor Cyan