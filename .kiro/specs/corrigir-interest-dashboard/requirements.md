# Requirements: Correção do Interest Dashboard

## Introduction

Corrigir múltiplos problemas no InterestDashboardView para que funcione corretamente com o novo sistema de notificações e perfis.

## Glossary

- **InterestDashboardView**: Tela que mostra notificações de interesse recebidas
- **EnhancedVitrineDisplayView**: Nova tela de visualização de perfil público
- **ProfileDisplayView**: Tela antiga de visualização de perfil (deprecated)
- **fromUserName**: Campo que armazena o nome de quem enviou o interesse
- **Status accepted**: Status de notificação que foi aceita pelo destinatário
- **Status viewed**: Status de notificação que foi visualizada mas não respondida

## Requirements

### Requirement 1: Exibir Nome Real do Remetente

**User Story:** Como usuário que recebe interesse, quero ver o nome real da pessoa que demonstrou interesse, para saber quem é antes de responder.

#### Acceptance Criteria

1. WHEN o sistema carrega uma notificação de interesse, THE InterestDashboardView SHALL buscar o nome do remetente do Firestore usando fromUserId
2. WHEN o fromUserName está vazio no Firestore, THE InterestDashboardView SHALL buscar o nome da collection usuarios
3. WHEN o nome é encontrado, THE InterestDashboardView SHALL exibir o nome real ao invés de "Usuário"
4. WHEN o nome não é encontrado, THE InterestDashboardView SHALL exibir "Usuário Anônimo" como fallback

### Requirement 2: Navegar para Perfil Correto

**User Story:** Como usuário que recebe interesse, quero ver o perfil completo da pessoa ao clicar em "Ver Perfil", para conhecer melhor antes de responder.

#### Acceptance Criteria

1. WHEN o usuário clica em "Ver Perfil", THE InterestDashboardView SHALL navegar para EnhancedVitrineDisplayView
2. WHEN a navegação ocorre, THE InterestDashboardView SHALL passar o userId correto do remetente
3. WHEN EnhancedVitrineDisplayView é aberta, THE sistema SHALL exibir o perfil público completo
4. THE InterestDashboardView SHALL NOT navegar para ProfileDisplayView (deprecated)

### Requirement 3: Exibir Botões Corretos por Status

**User Story:** Como usuário que recebe interesse, quero ver botões apropriados para cada tipo de notificação, para responder adequadamente.

#### Acceptance Criteria

1. WHEN a notificação tem status "pending", THE InterestDashboardView SHALL exibir botões "Não Tenho" e "Também Tenho"
2. WHEN a notificação tem status "accepted", THE InterestDashboardView SHALL exibir badge "MATCH!" e botão "Conversar"
3. WHEN a notificação tem status "viewed", THE InterestDashboardView SHALL exibir botões "Não Tenho" e "Também Tenho"
4. THE InterestDashboardView SHALL NOT exibir "Tenho Interesse" para notificações recebidas

### Requirement 4: Manter Notificações Lidas por 7 Dias

**User Story:** Como usuário, quero que notificações respondidas fiquem visíveis por 7 dias, para poder revisar minhas decisões recentes.

#### Acceptance Criteria

1. WHEN uma notificação é aceita ou rejeitada, THE sistema SHALL manter a notificação visível
2. WHEN uma notificação tem status "accepted" ou "rejected", THE sistema SHALL calcular dias desde dataResposta
3. WHEN passaram menos de 7 dias desde a resposta, THE InterestDashboardView SHALL exibir a notificação
4. WHEN passaram 7 ou mais dias desde a resposta, THE InterestDashboardView SHALL ocultar a notificação
5. THE sistema SHALL incluir "accepted" e "rejected" nos status válidos para exibição

### Requirement 5: Filtrar Notificações Corretamente

**User Story:** Como usuário, quero ver todas as notificações relevantes (pendentes, visualizadas e recentes), para gerenciar meus interesses.

#### Acceptance Criteria

1. THE sistema SHALL aceitar status: "pending", "new", "viewed", "accepted", "rejected"
2. WHEN o status é "accepted" ou "rejected", THE sistema SHALL verificar se passaram menos de 7 dias
3. WHEN o status é "pending", "new" ou "viewed", THE sistema SHALL sempre exibir a notificação
4. THE sistema SHALL ordenar notificações por data de criação (mais recente primeiro)
5. THE sistema SHALL NOT rejeitar notificações com status "accepted" automaticamente

### Requirement 6: Criar Notificação de Match Mútuo

**User Story:** Como usuário que aceita um interesse, quero que o sistema detecte match mútuo, para que ambos sejam notificados.

#### Acceptance Criteria

1. WHEN um usuário aceita um interesse, THE sistema SHALL verificar se existe interesse mútuo
2. WHEN existe interesse mútuo, THE sistema SHALL criar notificações de "mutual_match" para ambos
3. WHEN existe match mútuo, THE sistema SHALL criar um chat automaticamente
4. WHEN não existe interesse mútuo, THE sistema SHALL criar apenas notificação de "acceptance"
5. THE sistema SHALL exibir badge "MATCH!" para notificações de mutual_match

### Requirement 7: Corrigir Script de Correção

**User Story:** Como desenvolvedor, quero corrigir notificações existentes com fromUserName vazio, para que o sistema funcione corretamente.

#### Acceptance Criteria

1. THE script SHALL buscar todas as notificações com fromUserName vazio
2. WHEN encontra uma notificação, THE script SHALL buscar o nome do usuário no Firestore
3. WHEN o nome é encontrado, THE script SHALL atualizar o campo fromUserName
4. THE script SHALL registrar logs detalhados de cada correção
5. THE script SHALL tratar erros graciosamente sem interromper o processo
