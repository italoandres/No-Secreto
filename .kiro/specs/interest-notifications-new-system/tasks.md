# Implementation Plan - Sistema de Notificações de Interesse

## Fase 1: Estrutura Base (Baseada no Sistema Funcional)

- [ ] 1.1 Criar InterestNotificationModel
  - Criar `lib/models/interest_notification_model.dart`
  - Implementar estrutura baseada em PurposeInviteModel
  - Adicionar métodos fromMap, toMap, e getters de conveniência
  - Incluir validações básicas
  - _Requirements: 1.2, 5.1_

- [ ] 1.2 Criar InterestNotificationRepository
  - Criar `lib/repositories/interest_notification_repository.dart`
  - Implementar createInterestNotification (baseado em sendPartnershipInvite)
  - Implementar getUserInterestNotifications stream (baseado em getUserInvites)
  - Implementar respondToInterestNotification (baseado em respondToInviteWithAction)
  - Adicionar validações de duplicata e existência de usuário
  - _Requirements: 1.1, 1.3, 3.4, 6.1, 6.2_

- [ ] 1.3 Criar InterestNotificationsComponent
  - Criar `lib/components/interest_notifications_component.dart`
  - Copiar estrutura visual do PurposeInvitesComponent
  - Adaptar para notificações de interesse
  - Implementar mesmo design com gradiente azul/rosa
  - Adicionar botões "Também Tenho", "Não Tenho", "Ver Perfil"
  - _Requirements: 2.1, 2.2, 2.3, 4.2_

## Fase 2: Integração com Sistema Existente

- [ ] 2.1 Criar InterestButtonComponent
  - Criar `lib/components/interest_button_component.dart`
  - Implementar botão "Tenho Interesse" integrado
  - Conectar com InterestNotificationRepository.createInterestNotification
  - Adicionar feedback visual (loading, success, error)
  - Usar mesmo padrão visual dos botões existentes
  - _Requirements: 1.1, 4.1, 6.4_

- [ ] 2.2 Integrar com perfis existentes
  - Localizar todos os botões "Tenho Interesse" existentes
  - Substituir por InterestButtonComponent
  - Manter mesma funcionalidade visual
  - Garantir que dados do usuário são passados corretamente
  - _Requirements: 4.1, 4.5_

- [ ] 2.3 Integrar InterestNotificationsComponent na interface
  - Adicionar componente na mesma área dos convites do Nosso Propósito
  - Implementar lógica de exibição condicional (só quando há notificações)
  - Garantir que aparece em tempo real via stream
  - Manter consistência visual com componentes existentes
  - _Requirements: 2.1, 2.4, 4.2, 4.3_

## Fase 3: Funcionalidades de Resposta

- [ ] 3.1 Implementar resposta "Também Tenho"
  - Conectar botão com InterestNotificationRepository.respondToInterestNotification
  - Marcar notificação como 'accepted'
  - Implementar lógica de match mútuo (se necessário)
  - Mostrar feedback de sucesso
  - _Requirements: 3.1, 3.4_

- [ ] 3.2 Implementar resposta "Não Tenho"
  - Conectar botão com InterestNotificationRepository.respondToInterestNotification
  - Marcar notificação como 'rejected'
  - Remover notificação da lista
  - Mostrar feedback apropriado
  - _Requirements: 3.2, 3.4_

- [ ] 3.3 Implementar "Ver Perfil"
  - Conectar botão com sistema de navegação existente
  - Navegar para perfil do usuário interessado
  - Manter contexto da notificação
  - Usar mesmas rotas existentes
  - _Requirements: 3.3, 4.4_

## Fase 4: Validações e Tratamento de Erros

- [ ] 4.1 Implementar validações de interesse
  - Verificar se usuário destinatário existe
  - Prevenir interesses duplicados pendentes
  - Validar dados antes de salvar no Firebase
  - Implementar rate limiting básico
  - _Requirements: 6.1, 6.2, 6.5_

- [ ] 4.2 Implementar tratamento de erros robusto
  - Adicionar try-catch em todas as operações
  - Mostrar loading dialogs durante operações (mesmo padrão dos convites)
  - Implementar snackbars de feedback específicos
  - Adicionar rollback em caso de erro
  - _Requirements: 1.4, 3.5, 6.4_

- [ ] 4.3 Implementar validações de resposta
  - Verificar se notificação ainda está pendente antes de responder
  - Validar permissões do usuário
  - Prevenir respostas duplicadas
  - Tratar casos de notificação já respondida
  - _Requirements: 6.3, 6.4_

## Fase 5: Tempo Real e Persistência

- [ ] 5.1 Configurar streams em tempo real
  - Garantir que getUserInterestNotifications funciona em tempo real
  - Implementar ordenação por data (mais recente primeiro)
  - Otimizar queries para performance
  - Testar sincronização automática
  - _Requirements: 5.2, 5.3, 2.3_

- [ ] 5.2 Implementar persistência offline
  - Configurar cache local para notificações
  - Implementar sincronização quando voltar online
  - Tratar casos de conflito de dados
  - Garantir que notificações não se percam
  - _Requirements: 5.4, 5.5_

- [ ] 5.3 Implementar contador de notificações
  - Adicionar contador visual de notificações não lidas
  - Atualizar contador em tempo real
  - Integrar com interface principal
  - Usar mesmo padrão dos convites
  - _Requirements: 2.5, 4.4_

## Fase 6: Testes e Validação

- [ ] 6.1 Testar fluxo completo de interesse
  - Testar criação de notificação quando clica "Tenho Interesse"
  - Verificar que notificação aparece instantaneamente para destinatário
  - Testar todas as respostas (Também Tenho, Não Tenho, Ver Perfil)
  - Validar que status é atualizado corretamente no Firebase
  - _Requirements: 1.3, 2.1, 3.1, 3.2, 3.3_

- [ ] 6.2 Testar validações e tratamento de erros
  - Testar prevenção de interesses duplicados
  - Testar validação de usuário inexistente
  - Testar comportamento com erro de rede
  - Verificar que mensagens de erro são claras
  - _Requirements: 1.5, 6.1, 6.2, 6.4_

- [ ] 6.3 Testar integração com sistema existente
  - Verificar que componente aparece na mesma área dos convites
  - Testar que design visual é consistente
  - Validar navegação para perfis
  - Confirmar que não interfere com funcionalidades existentes
  - _Requirements: 4.1, 4.2, 4.3, 4.5_

## Fase 7: Configuração Firebase

- [ ] 7.1 Criar coleção interest_notifications
  - Configurar coleção no Firebase Firestore
  - Definir estrutura de documentos
  - Configurar índices necessários para queries
  - Testar performance das queries
  - _Requirements: 5.1, 5.2_

- [ ] 7.2 Configurar regras de segurança
  - Implementar regras baseadas nas dos convites
  - Permitir leitura/escrita apenas para usuários envolvidos
  - Testar permissões de acesso
  - Validar segurança das operações
  - _Requirements: 6.1, 6.3_

## Fase 8: Polimento e Otimização

- [ ] 8.1 Otimizar performance
  - Implementar lazy loading de componentes
  - Otimizar queries Firebase
  - Adicionar cache local inteligente
  - Minimizar re-renders desnecessários
  - _Requirements: 5.3, 5.5_

- [ ] 8.2 Melhorar experiência do usuário
  - Adicionar animações suaves (mesmo padrão dos convites)
  - Implementar estados de loading elegantes
  - Melhorar feedback visual das ações
  - Adicionar haptic feedback onde apropriado
  - _Requirements: 2.2, 4.2_

- [ ] 8.3 Documentar sistema
  - Criar documentação de uso
  - Documentar APIs do repository
  - Criar guia de integração
  - Documentar padrões visuais utilizados
  - _Requirements: Todos_

## Critérios de Sucesso

### Teste Final de Aceitação

1. **Cenário @italo → @itala3**:
   - @italo clica "Tenho Interesse" no perfil de @itala3
   - @itala3 recebe notificação instantaneamente
   - @itala3 vê nome, foto e mensagem de @italo
   - @itala3 pode responder com "Também Tenho", "Não Tenho" ou "Ver Perfil"
   - Todas as ações funcionam corretamente

2. **Integração Visual**:
   - Componente aparece na mesma área dos convites
   - Design é consistente com gradiente azul/rosa
   - Animações e feedback são suaves
   - Interface é responsiva e acessível

3. **Robustez Técnica**:
   - Sistema funciona em tempo real
   - Tratamento de erros é robusto
   - Validações previnem problemas
   - Performance é adequada

### Definição de "Pronto"

- ✅ Todos os testes passam
- ✅ Integração visual está perfeita
- ✅ Sistema funciona como os convites do Nosso Propósito
- ✅ Documentação está completa
- ✅ Performance está otimizada