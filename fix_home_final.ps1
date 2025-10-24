Write-Host "Comentando botao de teste de notificacoes..." -ForegroundColor Cyan

$arquivo = "lib\views\home_view.dart"
$conteudo = Get-Content $arquivo -Raw

# Comentar o bloco do FloatingActionButton de teste
$antigo = @"
          // Botão de Teste de Notificações
          FloatingActionButton.extended(
            heroTag: 'notif_test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // REMOVIDO: builder: (context) => const TestNotificationsButtonView(),
                ),
              );
            },
            icon: const Icon(Icons.science),
            label: const Text('🧪 Teste'),
            backgroundColor: Colors.orange,
          ),
"@

$novo = @"
          // REMOVIDO FASE 2: Botão de Teste de Notificações
          // FloatingActionButton.extended(
          //   heroTag: 'notif_test',
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const TestNotificationsButtonView(),
          //       ),
          //     );
          //   },
          //   icon: const Icon(Icons.science),
          //   label: const Text('🧪 Teste'),
          //   backgroundColor: Colors.orange,
          // ),
"@

$conteudo = $conteudo -replace [regex]::Escape($antigo), $novo

Set-Content $arquivo $conteudo -NoNewline

Write-Host "OK! Botao comentado" -ForegroundColor Green
Write-Host ""
Write-Host "Agora teste: flutter run" -ForegroundColor Cyan