# Requirements Document

## Introduction

Este sistema visa corrigir definitivamente as notificações de interesse que estão apresentando dados incorretos. O problema principal é que as notificações mostram nomes errados (ex: "itala" em vez de "Italo Lior") e os botões "Ver Perfil" não funcionam corretamente, impedindo a navegação para o perfil do usuário que demonstrou interesse.

## Requirements

### Requirement 1

**User Story:** Como usuário @itala, eu quero ver o nome correto do usuário que demonstrou interesse no meu perfil, para que eu possa identificá-lo adequadamente.

#### Acceptance Criteria

1. WHEN uma notificação de interesse é exibida THEN o sistema SHALL mostrar o nome real do usuário (ex: "Italo Lior") em vez de dados incorretos
2. WHEN o sistema busca dados do usuário THEN SHALL consultar a coleção 'users' usando o fromUserId correto
3. IF o nome não for encontrado THEN o sistema SHALL usar um fallback apropriado como "Usuário não encontrado"

### Requirement 2

**User Story:** Como usuário @itala, eu quero que o botão "Ver Perfil" funcione corretamente, para que eu possa visualizar o perfil completo do usuário interessado.

#### Acceptance Criteria

1. WHEN eu clico no botão "Ver Perfil" THEN o sistema SHALL navegar para o perfil do usuário correto
2. WHEN o sistema processa o clique THEN SHALL usar o userId correto (ex: "6Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8")
3. IF o perfil não existir THEN o sistema SHALL exibir uma mensagem de erro apropriada

### Requirement 3

**User Story:** Como usuário @itala, eu quero ver apenas as notificações de interesse relevantes para mim, para que eu não veja notificações destinadas a outros usuários.

#### Acceptance Criteria

1. WHEN o sistema carrega notificações THEN SHALL filtrar apenas notificações onde userId corresponde ao usuário atual
2. WHEN uma notificação tem userId "test_target_user" THEN SHALL ser corrigida para o userId real do usuário logado
3. WHEN o sistema detecta dados inconsistentes THEN SHALL aplicar correções automáticas baseadas no fromUserId

### Requirement 4

**User Story:** Como usuário @itala, eu quero que as notificações sejam carregadas de forma eficiente, para que eu tenha uma experiência fluida no aplicativo.

#### Acceptance Criteria

1. WHEN o sistema carrega notificações THEN SHALL usar consultas otimizadas do Firebase
2. WHEN há múltiplas notificações THEN o sistema SHALL ordená-las por data de criação (mais recentes primeiro)
3. WHEN uma notificação é marcada como lida THEN SHALL atualizar o status no Firebase imediatamente

### Requirement 5

**User Story:** Como desenvolvedor, eu quero logs detalhados do sistema de notificações, para que eu possa diagnosticar problemas rapidamente.

#### Acceptance Criteria

1. WHEN o sistema processa notificações THEN SHALL registrar logs com IDs, nomes e dados relevantes
2. WHEN ocorre um erro THEN o sistema SHALL logar detalhes específicos do erro
3. WHEN dados são corrigidos THEN SHALL logar as correções aplicadas