# Implementation Plan - Correção Exibição de Notificações de Interesse

- [x] 1. Investigar e identificar componente com filtro problemático


  - Buscar no código onde está o filtro que exclui notificações
  - Identificar se é em `received_interests_view.dart`, repository ou service
  - Documentar a lógica atual de filtragem
  - _Requirements: 1.1, 2.1, 2.2_



- [ ] 2. Corrigir filtro de notificações no repository
  - Modificar query do Firebase para buscar todas as notificações do usuário
  - Remover filtros restritivos de `whereIn` se estiverem excluindo notificações válidas
  - Implementar filtro na aplicação que aceita tipos: interest, acceptance, mutual_match

  - Implementar filtro na aplicação que aceita status: pending, viewed, new
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 3. Adicionar logs detalhados de debug
  - Adicionar log no início da query mostrando userId
  - Adicionar log após query mostrando total de documentos retornados
  - Adicionar log durante filtragem mostrando tipos e status válidos

  - Adicionar log para cada notificação excluída com motivo
  - Adicionar log final mostrando quantas notificações passaram no filtro
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 4. Garantir processamento correto de notificações de interesse
  - Verificar que NotificationModel suporta type "interest"

  - Verificar que NotificationModel suporta status "pending"
  - Garantir que método de conversão não está descartando campos
  - Validar que todos os campos obrigatórios estão presentes
  - _Requirements: 1.1, 1.2_

- [ ] 5. Testar exibição de notificações em tempo real
  - Criar notificação de teste com type "interest" e status "pending"
  - Verificar que stream detecta a nova notificação


  - Confirmar que notificação aparece na UI sem reload
  - Validar que notificação aparece no topo da lista
  - _Requirements: 3.1, 3.2, 3.3_



- [ ] 6. Criar ferramenta de diagnóstico
  - Criar utility que lista todas as notificações do usuário no Firebase
  - Mostrar tipo, status e outros campos de cada notificação
  - Simular aplicação de filtros e mostrar quais passam/falham
  - Gerar relatório de diagnóstico completo
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 7. Validar correção com cenário real
  - Usuário A curte perfil de Usuário B
  - Verificar logs de criação da notificação
  - Usuário B abre tela de notificações
  - Verificar logs de busca e filtragem
  - Confirmar que notificação aparece na UI
  - Testar ações (aceitar/rejeitar) na notificação
  - _Requirements: 1.1, 1.2, 1.3_
