# Requirements Document: Melhorar Tela de Matches Aceitos

## Introduction

Esta spec visa melhorar a tela de matches aceitos (`SimpleAcceptedMatchesView`) para incluir fotos reais dos perfis, status de presença online, e sincronização correta de notificações de mensagens.

## Glossary

- **Match System**: Sistema que gerencia matches aceitos entre usuários
- **Presence System**: Sistema que rastreia status online/offline dos usuários
- **Chat System**: Sistema de mensagens entre matches
- **Profile Photo**: Foto principal do perfil do usuário
- **Last Seen**: Timestamp da última vez que o usuário esteve online
- **Unread Count**: Contador de mensagens não lidas em um chat

## Requirements

### Requirement 1: Exibir Foto Real do Perfil

**User Story:** Como usuário, quero ver a foto real do perfil do meu match, para reconhecer visualmente com quem estou conversando

#### Acceptance Criteria

1. WHEN THE Match System carrega um match, THE Match System SHALL buscar a foto principal do perfil do outro usuário
2. WHEN a foto existe no Firestore, THE Match System SHALL exibir a foto no CircleAvatar do card
3. IF a foto não existe, THEN THE Match System SHALL exibir a inicial do nome em um avatar colorido
4. WHEN a foto falha ao carregar, THE Match System SHALL exibir um placeholder com a inicial do nome

### Requirement 2: Mostrar Status de Presença Online

**User Story:** Como usuário, quero saber se meu match está online ou quando esteve online pela última vez, para saber se posso esperar uma resposta rápida

#### Acceptance Criteria

1. WHEN THE Presence System detecta que um usuário está online, THE Presence System SHALL exibir um indicador verde "Online" no card
2. WHEN o usuário está offline, THE Presence System SHALL exibir "Visto há X minutos/horas/dias"
3. WHEN o usuário nunca esteve online, THE Presence System SHALL exibir "Nunca visto"
4. THE Presence System SHALL atualizar o status em tempo real usando Firestore listeners
5. WHEN o usuário está online há menos de 5 minutos, THE Presence System SHALL exibir "Online agora"

### Requirement 3: Sincronizar Notificações de Mensagens

**User Story:** Como usuário, quero ver o contador de mensagens não lidas atualizado em tempo real, para saber quando recebi novas mensagens

#### Acceptance Criteria

1. WHEN THE Chat System recebe uma nova mensagem, THE Chat System SHALL atualizar o contador de não lidas no card do match
2. WHEN o usuário abre o chat, THE Chat System SHALL zerar o contador de não lidas
3. THE Chat System SHALL usar Firestore listeners para atualizar contadores em tempo real
4. WHEN há mensagens não lidas, THE Match System SHALL exibir um badge rosa com o número
5. WHEN não há mensagens não lidas, THE Match System SHALL ocultar o badge

### Requirement 4: Corrigir Funcionamento no APK

**User Story:** Como usuário, quero que a tela funcione corretamente no APK de produção, não apenas em perfis de teste

#### Acceptance Criteria

1. THE Match System SHALL funcionar identicamente em debug e release builds
2. THE Match System SHALL tratar corretamente permissões de leitura do Firestore
3. WHEN há erro de permissão, THE Match System SHALL exibir mensagem clara ao usuário
4. THE Match System SHALL ter logs adequados para debug em produção
5. THE Match System SHALL ter fallbacks para dados ausentes ou inválidos

### Requirement 5: Melhorar Visual do Card

**User Story:** Como usuário, quero um card visualmente atraente e informativo, para ter uma boa experiência ao ver meus matches

#### Acceptance Criteria

1. THE Match System SHALL exibir foto do perfil em tamanho adequado (60x60)
2. THE Match System SHALL mostrar indicador de presença sobreposto à foto
3. THE Match System SHALL exibir nome, idade e localização do match
4. WHEN há mensagens não lidas, THE Match System SHALL destacar visualmente o card
5. THE Match System SHALL mostrar preview da última mensagem enviada
