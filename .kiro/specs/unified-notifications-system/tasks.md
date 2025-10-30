# Implementation Plan - Sistema Unificado de Notificações

Este plano de implementação divide o desenvolvimento do Sistema Unificado de Notificações em tarefas incrementais e testáveis. Cada tarefa é focada em código e pode ser executada por um agente de desenvolvimento.

---

## 📋 Task List

- [x] 1. Criar estrutura base e modelos de dados



  - Criar enum `NotificationCategory` com 3 categorias (Stories, Interesse, Sistema)
  - Criar classe `UnifiedNotificationModel` como wrapper para diferentes tipos
  - Adicionar métodos factory para conversão de tipos existentes





  - _Requirements: 1.1, 5.1_

- [ ] 2. Implementar UnifiedNotificationController
  - [ ] 2.1 Criar controller GetX com observables para cada categoria
    - Criar `RxList` para stories, interest e system notifications

    - Criar `RxInt` para badge counts de cada categoria
    - Criar `RxBool` para loading state e `RxString` para error messages
    - Criar `RxInt` para active category index
    - _Requirements: 1.2, 6.1, 6.2_
  
  - [x] 2.2 Implementar métodos de carregamento de notificações

    - Implementar `_loadStoriesNotifications()` usando `NotificationRepository` (filtrar tipos: like, comment, mention, reply, comment_like)
    - Implementar `_loadInterestNotifications()` usando `InterestNotificationRepository`
    - Implementar `_loadSystemNotifications()` usando `CertificationNotificationService`
    - Implementar `loadAllNotifications()` que chama os 3 métodos acima
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 4.1, 8.1, 8.2_
  

  - [ ] 2.3 Implementar cálculo de badges
    - Implementar `_updateStoriesBadgeCount()` contando notificações não lidas
    - Implementar `_updateInterestBadgeCount()` contando interesses pendentes
    - Implementar `_updateSystemBadgeCount()` contando notificações de sistema não lidas





    - Implementar `getTotalBadgeCount()` somando todos os badges
    - _Requirements: 6.1, 6.2, 6.4_
  
  - [ ] 2.4 Implementar métodos de ação
    - Implementar `refreshCategory()` para pull-to-refresh

    - Implementar `markCategoryAsRead()` para marcar todas como lidas
    - Implementar `switchCategory()` para trocar categoria ativa
    - Adicionar tratamento de erros em todos os métodos
    - _Requirements: 1.3, 7.2, 9.5_

- [x] 3. Criar componente NotificationCategoryTab

  - [ ] 3.1 Implementar widget de tab com ícone e badge
    - Criar StatelessWidget com parâmetros: category, badgeCount, isActive, onTap
    - Implementar layout com ícone da categoria centralizado
    - Adicionar badge posicionado no canto superior direito





    - Aplicar estilo visual diferente quando isActive é true
    - _Requirements: 5.1, 5.2, 5.3, 6.1_
  
  - [ ] 3.2 Implementar badge visual
    - Criar widget de badge circular vermelho

    - Exibir contador (ou "99+" se > 99)
    - Ocultar badge quando count é 0
    - Adicionar animação de fade in/out ao aparecer/desaparecer
    - _Requirements: 6.1, 6.2, 6.4, 6.5_
  
  - [x] 3.3 Adicionar acessibilidade

    - Adicionar Semantics com label descritivo
    - Incluir contador no label para screen readers
    - Adicionar hint de ação ("Toque para ver notificações")
    - Garantir área de toque mínima de 48x48
    - _Requirements: 10.1, 10.5_


- [ ] 4. Criar componente NotificationCategoryContent
  - [ ] 4.1 Implementar lista de notificações
    - Criar StatelessWidget com parâmetros: category, notifications, isLoading, onRefresh, onNotificationTap
    - Implementar ListView.builder para renderizar notificações
    - Adicionar separadores entre itens

    - Implementar scroll infinito se necessário
    - _Requirements: 1.3, 9.3_
  
  - [x] 4.2 Implementar pull-to-refresh





    - Adicionar RefreshIndicator ao redor da lista
    - Chamar onRefresh callback ao puxar
    - Exibir loading indicator durante refresh
    - Mostrar feedback visual de sucesso/erro
    - _Requirements: 9.5_

  
  - [ ] 4.3 Implementar estados vazios
    - Criar widget de empty state para cada categoria
    - Exibir ícone, título e mensagem apropriados
    - Adicionar botão de ação se aplicável
    - Usar mensagens específicas por categoria
    - _Requirements: 1.4, 2.5, 3.4, 4.5_
  
  - [x] 4.4 Implementar estado de loading

    - Exibir CircularProgressIndicator centralizado durante carregamento inicial
    - Exibir shimmer effect para loading incremental
    - Manter lista visível durante refresh
    - _Requirements: 9.1, 9.2_
  
  - [x] 4.5 Implementar estado de erro

    - Criar widget de error state com ícone e mensagem
    - Adicionar botão "Tentar Novamente"
    - Exibir mensagem de erro específica
    - Permitir retry da operação





    - _Requirements: 8.4_

- [ ] 5. Criar NotificationItemFactory
  - [ ] 5.1 Implementar factory method
    - Criar método estático `createNotificationItem()`

    - Receber parâmetros: category, notification, onTap, onDelete
    - Usar switch/case para determinar tipo de widget
    - Retornar widget apropriado para cada categoria
    - _Requirements: 8.3_
  
  - [x] 5.2 Criar StoryNotificationItem widget

    - Exibir foto do usuário, nome e tipo de ação (curtiu, comentou, mencionou @, respondeu, curtiu comentário)
    - Mostrar preview do story ou comentário se disponível
    - Usar ícones específicos: ❤️ curtida, 💬 comentário, @ menção, ↩️ resposta, 👍 curtida em comentário
    - Aplicar cor amber.shade700 como accent
    - Adicionar indicador de não lida (ponto azul)
    - Destacar visualmente menções (@) com background diferente ou badge especial

    - Implementar lógica para detectar tipo de notificação (like, comment, mention, reply, comment_like)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_
  
  - [ ] 5.3 Criar InterestNotificationItem widget
    - Exibir foto do usuário, nome e mensagem de interesse
    - Adicionar botões de aceitar/rejeitar se pendente

    - Aplicar cor pink.shade400 como accent
    - Mostrar badge de "Match Mútuo" se aplicável
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 5.4 Criar SystemNotificationItem widget
    - Exibir ícone apropriado (verificado para aprovação, info para reprovação)

    - Mostrar título e mensagem da notificação
    - Aplicar cor blue.shade600 como accent
    - Adicionar botão de ação se necessário
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ] 6. Implementar UnifiedNotificationsView
  - [ ] 6.1 Criar estrutura base da view
    - Criar StatefulWidget com TabController
    - Inicializar UnifiedNotificationController no initState
    - Configurar TabController com 3 tabs
    - Implementar dispose para limpar recursos
    - _Requirements: 1.1, 7.5_
  
  - [ ] 6.2 Implementar AppBar
    - Adicionar título "Notificações"
    - Exibir badge total no canto superior direito
    - Adicionar botão de voltar
    - Aplicar cor amber.shade700 como background
    - _Requirements: 1.1, 6.3_
  
  - [ ] 6.3 Implementar barra de categorias
    - Criar Container com as 3 tabs horizontais
    - Usar NotificationCategoryTab para cada categoria
    - Adicionar padding e espaçamento apropriados
    - Implementar scroll horizontal se necessário
    - _Requirements: 5.1, 5.2, 5.3, 7.4_
  
  - [ ] 6.4 Implementar TabBarView
    - Criar TabBarView com 3 páginas
    - Usar NotificationCategoryContent para cada página
    - Conectar com dados do controller
    - Implementar transições suaves entre tabs
    - _Requirements: 1.3, 5.5, 7.2_
  
  - [ ] 6.5 Implementar navegação entre categorias
    - Conectar TabController com controller.activeCategory
    - Atualizar activeCategory ao trocar de tab
    - Adicionar animação de transição
    - Suportar swipe gesture para trocar tabs
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [ ] 6.6 Implementar handlers de ações
    - Criar método `_handleNotificationTap()` que delega para serviços existentes
    - Criar método `_handleRefresh()` que chama controller.refreshCategory()
    - Criar método `_handleMarkAsRead()` que chama controller.markCategoryAsRead()
    - Adicionar tratamento de erros com snackbars
    - _Requirements: 2.3, 3.3, 3.4, 4.3, 8.3_

- [x] 7. Integrar com navegação do app


  - Atualizar rotas para incluir UnifiedNotificationsView
  - Substituir navegação antiga por nova tela
  - Manter rota antiga como fallback temporário
  - Testar navegação de diferentes pontos do app
  - _Requirements: 8.1, 8.2_




- [ ] 8. Implementar cache e performance
  - [ ] 8.1 Integrar com NotificationFallbackSystem
    - Salvar notificações no cache ao carregar
    - Carregar do cache quando offline
    - Implementar estratégia de invalidação

    - _Requirements: 8.4, 9.1, 9.2_
  
  - [ ] 8.2 Implementar lazy loading
    - Carregar apenas categoria ativa inicialmente
    - Carregar outras categorias em background

    - Implementar paginação para listas grandes
    - _Requirements: 9.3_
  
  - [ ] 8.3 Otimizar streams
    - Cancelar streams ao trocar de categoria

    - Implementar debounce para updates
    - Usar throttle para scroll events
    - _Requirements: 9.4_

- [ ] 9. Adicionar tratamento de erros robusto
  - Implementar try-catch em todos os métodos async

  - Usar ErrorRecoverySystem para recuperação automática
  - Exibir mensagens de erro user-friendly
  - Registrar erros para debug
  - _Requirements: 8.4_

- [ ] 10. Implementar acessibilidade completa
  - Adicionar Semantics em todos os widgets interativos
  - Garantir contraste de cores adequado (WCAG AA)
  - Suportar tamanhos de fonte maiores
  - Testar com screen readers
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 11. Criar testes unitários
  - [ ]* 11.1 Testar UnifiedNotificationController
    - Testar carregamento de notificações
    - Testar cálculo de badges
    - Testar mudança de categoria
    - Testar marcação como lida
  
  - [ ]* 11.2 Testar NotificationItemFactory
    - Testar criação de widgets por tipo
    - Testar aplicação de estilos
    - Testar ações específicas
  
  - [ ]* 11.3 Testar Data Models
    - Testar conversão entre tipos
    - Testar validação de dados
    - Testar serialização/deserialização

- [ ]* 12. Criar testes de integração
  - [ ]* 12.1 Testar fluxo completo
    - Testar abertura da tela
    - Testar navegação entre categorias
    - Testar tap em notificação
    - Testar marcação como lida
    - Testar pull to refresh
  
  - [ ]* 12.2 Testar integração com serviços
    - Testar carregamento de stories
    - Testar carregamento de interesse
    - Testar carregamento de sistema
    - Testar sincronização em tempo real

- [ ]* 13. Criar testes de widget
  - [ ]* 13.1 Testar UnifiedNotificationsView
    - Testar renderização das 3 categorias
    - Testar exibição de badges
    - Testar navegação entre tabs
    - Testar estados vazios

  
  - [ ]* 13.2 Testar NotificationCategoryTab
    - Testar exibição de ícone
    - Testar exibição de badge
    - Testar estado ativo/inativo

- [ ] 14. Documentar e finalizar
  - Adicionar comentários de documentação em código
  - Criar README com instruções de uso
  - Atualizar documentação de arquitetura
  - Fazer code review final
  - _Requirements: Todos_

---

## 📝 Notas de Implementação

### Ordem de Execução Recomendada

1. **Tasks 1-2**: Criar base (modelos e controller)
2. **Tasks 3-5**: Criar componentes visuais
3. **Task 6**: Montar view principal
4. **Tasks 7-9**: Integração e otimização
5. **Task 10**: Acessibilidade
6. **Tasks 11-13**: Testes (opcional)
7. **Task 14**: Documentação

### Dependências entre Tasks

- Task 3 depende de Task 1 (precisa do enum)
- Task 4 depende de Task 5 (usa o factory)
- Task 6 depende de Tasks 2, 3, 4 (usa todos os componentes)
- Task 7 depende de Task 6 (precisa da view completa)
- Tasks 8-9 podem ser feitas em paralelo
- Task 10 pode ser feita após Task 6
- Tasks 11-13 podem ser feitas após implementação completa

### Pontos de Atenção

⚠️ **Não atualizar versões do Firebase** - Manter compatibilidade com versões atuais
⚠️ **Reutilizar serviços existentes** - Não duplicar código
⚠️ **Testar em cada etapa** - Validar funcionamento incremental
⚠️ **Manter código limpo** - Seguir padrões do projeto

### Estimativa de Tempo

- Tasks 1-2: ~2-3 horas
- Tasks 3-5: ~3-4 horas
- Task 6: ~2-3 horas
- Tasks 7-9: ~2-3 horas
- Task 10: ~1-2 horas
- Tasks 11-13: ~3-4 horas (opcional)
- Task 14: ~1 hora

**Total estimado: 14-20 horas** (sem testes opcionais: 11-16 horas)
