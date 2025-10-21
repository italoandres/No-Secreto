# Sistema de Notificações de Interesse em Matches - V2

## Introdução

Este documento define os requisitos para um sistema completo de notificações de interesse em matches, baseado na arquitetura bem-sucedida do sistema de notificações do "nosso propósito". O sistema deve exibir notificações quando outros usuários demonstram interesse no perfil do usuário atual, usando a mesma estrutura de componentes, serviços e repositórios que já funciona corretamente no projeto.

## Requisitos

### Requisito 1

**User Story:** Como usuário do app, quero ver notificações quando alguém demonstra interesse no meu perfil, para que eu possa saber quem está interessado em mim.

#### Acceptance Criteria

1. WHEN um usuário demonstra interesse no meu perfil THEN o sistema SHALL criar uma notificação de interesse
2. WHEN eu acesso a tela de matches THEN o sistema SHALL exibir um ícone de notificação com contador de notificações não lidas
3. WHEN há notificações não lidas THEN o ícone SHALL exibir um badge vermelho com o número de notificações
4. WHEN não há notificações não lidas THEN o ícone SHALL aparecer sem badge
5. WHEN eu clico no ícone de notificação THEN o sistema SHALL abrir a tela de notificações de interesse

### Requisito 2

**User Story:** Como usuário, quero ver uma lista das notificações de interesse recebidas, para que eu possa revisar quem demonstrou interesse no meu perfil.

#### Acceptance Criteria

1. WHEN eu abro a tela de notificações de interesse THEN o sistema SHALL exibir uma lista de todas as notificações de interesse
2. WHEN uma notificação não foi lida THEN ela SHALL aparecer destacada visualmente
3. WHEN uma notificação foi lida THEN ela SHALL aparecer com aparência normal
4. WHEN eu visualizo uma notificação THEN o sistema SHALL marcar automaticamente como lida
5. WHEN eu clico em uma notificação THEN o sistema SHALL navegar para o perfil do usuário que demonstrou interesse

### Requisito 3

**User Story:** Como usuário, quero que as notificações sejam atualizadas em tempo real, para que eu seja informado imediatamente quando alguém demonstra interesse.

#### Acceptance Criteria

1. WHEN um novo interesse é registrado THEN o sistema SHALL criar a notificação imediatamente
2. WHEN uma nova notificação é criada THEN o contador SHALL ser atualizado automaticamente
3. WHEN eu marco notificações como lidas THEN o contador SHALL ser decrementado automaticamente
4. WHEN há mudanças nas notificações THEN a interface SHALL ser atualizada sem necessidade de refresh manual

### Requisito 4

**User Story:** Como usuário, quero que o sistema seja integrado com a arquitetura existente, para que funcione de forma consistente com outras notificações do app.

#### Acceptance Criteria

1. WHEN o sistema é implementado THEN ele SHALL usar o mesmo NotificationService existente
2. WHEN o sistema é implementado THEN ele SHALL usar o mesmo NotificationRepository existente
3. WHEN o sistema é implementado THEN ele SHALL usar o mesmo NotificationModel existente
4. WHEN o sistema é implementado THEN ele SHALL seguir os mesmos padrões de UI dos outros componentes de notificação
5. WHEN o sistema é implementado THEN ele SHALL usar o contexto 'interest_matches' para separar das outras notificações

### Requisito 5

**User Story:** Como usuário, quero que as notificações tenham informações completas sobre quem demonstrou interesse, para que eu possa identificar facilmente a pessoa.

#### Acceptance Criteria

1. WHEN uma notificação é criada THEN ela SHALL incluir o nome do usuário que demonstrou interesse
2. WHEN uma notificação é criada THEN ela SHALL incluir a foto de perfil do usuário que demonstrou interesse
3. WHEN uma notificação é criada THEN ela SHALL incluir a data/hora quando o interesse foi demonstrado
4. WHEN uma notificação é exibida THEN ela SHALL mostrar um texto descritivo como "João demonstrou interesse no seu perfil"
5. WHEN uma notificação é exibida THEN ela SHALL mostrar o tempo relativo (ex: "há 2 horas")