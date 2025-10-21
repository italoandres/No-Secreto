# Requirements Document - Correção da Exibição de Notificações na Interface

## Introdução

O sistema de notificações está funcionando corretamente no backend, carregando e processando as notificações de interesse, mas elas não estão sendo exibidas na interface do usuário. Os logs mostram que as notificações são encontradas e processadas (1 notificação real encontrada), mas não aparecem visualmente para o usuário.

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero ver as notificações de interesse na interface, para que eu possa saber quando alguém se interessou pelo meu perfil

#### Acceptance Criteria

1. WHEN o sistema carrega notificações no backend THEN elas devem aparecer visualmente na interface
2. WHEN existem notificações reais processadas THEN elas devem ser renderizadas na tela de matches
3. WHEN o stream de notificações é atualizado THEN a interface deve refletir as mudanças imediatamente

### Requirement 2

**User Story:** Como usuário, eu quero que as notificações sejam exibidas em tempo real, para que eu receba feedback imediato sobre novos interesses

#### Acceptance Criteria

1. WHEN uma nova notificação é criada THEN ela deve aparecer na interface sem necessidade de recarregar
2. WHEN o sistema processa múltiplas notificações THEN todas devem ser exibidas corretamente
3. WHEN o usuário navega para a tela de matches THEN as notificações devem estar visíveis

### Requirement 3

**User Story:** Como desenvolvedor, eu quero que o componente de notificações seja conectado corretamente ao controller, para que os dados fluam do backend para a UI

#### Acceptance Criteria

1. WHEN o MatchesController recebe notificações THEN elas devem ser passadas para o componente de UI
2. WHEN o stream de notificações é atualizado THEN o widget deve ser reconstruído
3. WHEN há erro na exibição THEN deve haver logs de debug para identificar o problema

### Requirement 4

**User Story:** Como usuário, eu quero ver notificações formatadas corretamente, para que eu possa entender facilmente quem se interessou por mim

#### Acceptance Criteria

1. WHEN uma notificação é exibida THEN ela deve mostrar o nome do usuário interessado
2. WHEN múltiplas notificações do mesmo usuário existem THEN elas devem ser agrupadas adequadamente
3. WHEN a notificação é exibida THEN deve incluir timestamp e ícones apropriados

### Requirement 5

**User Story:** Como usuário, eu quero que as notificações sejam persistentes na interface, para que eu não perca informações importantes sobre interesses

#### Acceptance Criteria

1. WHEN eu navego entre telas THEN as notificações devem permanecer visíveis quando retorno
2. WHEN o app é minimizado e reaberto THEN as notificações devem ainda estar visíveis
3. WHEN há problemas de conectividade THEN as notificações já carregadas devem permanecer na interface