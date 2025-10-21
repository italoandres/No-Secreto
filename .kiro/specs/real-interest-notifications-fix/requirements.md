# Requirements Document

## Introduction

O sistema de notificações de interesse não está capturando as interações reais que acontecem no Firebase. Quando um usuário demonstra interesse por outro (como italo3 se interessando por @itala), a interação é registrada no Firebase mas não aparece nas notificações reais do usuário que recebeu o interesse.

## Requirements

### Requirement 1

**User Story:** Como usuário que recebeu um interesse, eu quero ver a notificação real da interação, para que eu possa saber quem se interessou por mim.

#### Acceptance Criteria

1. WHEN um usuário demonstra interesse por outro THEN o sistema SHALL registrar a interação na coleção correta do Firebase
2. WHEN o sistema busca notificações reais THEN ele SHALL encontrar todas as interações registradas na coleção interests
3. WHEN uma interação é encontrada THEN o sistema SHALL converter ela em uma notificação visível para o usuário
4. WHEN o usuário visualiza as notificações THEN ele SHALL ver o nome correto e foto do usuário que demonstrou interesse

### Requirement 2

**User Story:** Como desenvolvedor, eu quero que o sistema de busca de notificações reais funcione corretamente, para que todas as interações sejam capturadas.

#### Acceptance Criteria

1. WHEN o sistema busca na coleção interests THEN ele SHALL usar a query correta para encontrar interações onde o usuário atual é o destinatário
2. WHEN uma interação é encontrada THEN o sistema SHALL buscar os dados completos do usuário que demonstrou interesse
3. IF os dados do usuário não estão disponíveis THEN o sistema SHALL usar dados de fallback ou cache
4. WHEN múltiplas interações existem THEN o sistema SHALL retornar todas elas ordenadas por data

### Requirement 3

**User Story:** Como usuário, eu quero que as notificações de interesse sejam atualizadas em tempo real, para que eu veja imediatamente quando alguém se interessa por mim.

#### Acceptance Criteria

1. WHEN uma nova interação é registrada THEN o sistema SHALL atualizar automaticamente a lista de notificações
2. WHEN o usuário está na tela de matches THEN as notificações SHALL ser atualizadas periodicamente
3. WHEN há erro na busca THEN o sistema SHALL tentar novamente com estratégias de fallback
4. WHEN não há conexão THEN o sistema SHALL mostrar dados do cache local se disponível