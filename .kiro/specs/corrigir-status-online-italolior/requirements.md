# Requirements Document

## Introduction

Este documento define os requisitos para corrigir o problema de status online "há muito tempo" que aparece para o usuário @italolior e potencialmente outros usuários. O problema ocorre porque diferentes views de chat não implementam consistentemente a lógica de exibição do status online, mesmo quando o campo `lastSeen` está sendo atualizado corretamente no Firestore.

## Glossary

- **ChatView**: View antiga de chat que usa a collection `/chat` do Firestore
- **RomanticMatchChatView**: View nova de chat que usa a collection `/match_chats/{chatId}/messages`
- **lastSeen**: Campo Timestamp no documento do usuário em `/usuarios/{userId}` que registra o último momento em que o usuário estava ativo
- **OnlineStatusService**: Serviço que atualiza o campo `lastSeen` no Firestore
- **Status Online**: Indicador visual que mostra se um usuário está online, offline, ou quando foi visto pela última vez

## Requirements

### Requirement 1: Identificar todas as views que exibem status de usuários

**User Story:** Como desenvolvedor, eu quero identificar todas as views que deveriam exibir o status online de usuários, para que eu possa garantir que todas implementem a lógica corretamente.

#### Acceptance Criteria

1. WHEN o desenvolvedor executa uma busca no código, THE Sistema SHALL retornar todas as views que exibem informações de usuários
2. WHEN o desenvolvedor analisa cada view encontrada, THE Sistema SHALL identificar quais views exibem ou deveriam exibir status online
3. WHEN o desenvolvedor documenta as views, THE Sistema SHALL criar uma lista completa com o status atual de implementação de cada view
4. THE Sistema SHALL identificar especificamente onde o status de @italolior é exibido incorretamente

### Requirement 2: Criar componente reutilizável de status online

**User Story:** Como desenvolvedor, eu quero criar um componente reutilizável para exibir o status online, para que todas as views possam usar a mesma lógica consistente.

#### Acceptance Criteria

1. THE Sistema SHALL criar um widget Flutter chamado `OnlineStatusWidget`
2. WHEN o widget recebe um `userId`, THE Sistema SHALL buscar o campo `lastSeen` do usuário em tempo real via Stream
3. WHEN o `lastSeen` é menor que 5 minutos, THE Sistema SHALL exibir "Online" com indicador verde
4. WHEN o `lastSeen` está entre 5 minutos e 1 hora, THE Sistema SHALL exibir "Online há X minutos" com indicador amarelo
5. WHEN o `lastSeen` está entre 1 hora e 24 horas, THE Sistema SHALL exibir "Online há X horas" com indicador laranja
6. WHEN o `lastSeen` é maior que 24 horas, THE Sistema SHALL exibir "Online há X dias" com indicador cinza
7. WHEN o `lastSeen` é null ou não existe, THE Sistema SHALL exibir "Online há muito tempo" com indicador cinza
8. THE Sistema SHALL permitir customização de tamanho, cor e estilo do componente

### Requirement 3: Implementar status online no ChatView

**User Story:** Como usuário que visualiza conversas no ChatView, eu quero ver o status online correto dos outros usuários, para que eu saiba quando eles estiveram ativos pela última vez.

#### Acceptance Criteria

1. WHEN o ChatView é aberto, THE Sistema SHALL exibir o status online do usuário admin/sistema
2. THE Sistema SHALL usar o componente `OnlineStatusWidget` para exibir o status
3. WHEN o `lastSeen` do usuário é atualizado, THE Sistema SHALL atualizar o status em tempo real
4. THE Sistema SHALL posicionar o status online de forma visível na AppBar ou próximo ao nome do usuário

### Requirement 4: Verificar e corrigir outras views

**User Story:** Como usuário, eu quero ver o status online correto em todas as telas do aplicativo, para que eu tenha informações consistentes sobre a atividade dos usuários.

#### Acceptance Criteria

1. WHEN o desenvolvedor identifica uma view que exibe informações de usuário, THE Sistema SHALL verificar se ela implementa status online
2. IF a view não implementa status online, THEN THE Sistema SHALL adicionar o componente `OnlineStatusWidget`
3. THE Sistema SHALL garantir que todas as views usem a mesma lógica de cálculo de status
4. THE Sistema SHALL testar cada view modificada para garantir que o status é exibido corretamente

### Requirement 5: Testar com usuário @italolior

**User Story:** Como testador, eu quero verificar que o status online de @italolior é exibido corretamente, para que eu possa confirmar que o problema foi resolvido.

#### Acceptance Criteria

1. WHEN @italolior está com o app aberto, THE Sistema SHALL exibir "Online" ou "Online há X minutos" em todas as views
2. WHEN @italolior fecha o app, THE Sistema SHALL atualizar o status para refletir o tempo decorrido
3. WHEN outro usuário visualiza @italolior em qualquer view, THE Sistema SHALL exibir o status correto baseado no `lastSeen`
4. THE Sistema SHALL garantir que o status nunca exibe "há muito tempo" se o `lastSeen` foi atualizado nas últimas 24 horas
5. WHEN o testador verifica o Firestore, THE Sistema SHALL confirmar que o campo `lastSeen` está sendo atualizado corretamente

### Requirement 6: Documentar a solução

**User Story:** Como desenvolvedor futuro, eu quero ter documentação clara sobre como o status online funciona, para que eu possa manter e estender o sistema corretamente.

#### Acceptance Criteria

1. THE Sistema SHALL criar documentação explicando a arquitetura do status online
2. THE Sistema SHALL documentar como usar o componente `OnlineStatusWidget`
3. THE Sistema SHALL documentar as regras de cálculo de status (online, minutos, horas, dias)
4. THE Sistema SHALL incluir exemplos de código para implementar status online em novas views
5. THE Sistema SHALL documentar como testar o status online manualmente
