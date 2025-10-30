# Requirements Document

## Introduction

Este sistema implementa uma correção robusta para a abertura do chat após match mútuo. Atualmente, quando um usuário clica no botão "Conversar" na notificação de match mútuo, o app falha devido a problemas de criação de chat, índices Firebase faltando e tratamento inadequado de notificações duplicadas.

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero que um chat seja criado automaticamente quando ocorre um match mútuo, para que eu possa conversar imediatamente sem erros técnicos.

#### Acceptance Criteria

1. WHEN ocorre um match mútuo THEN o sistema SHALL criar automaticamente um documento de chat no Firestore
2. WHEN o chat é criado THEN o sistema SHALL usar ID determinístico (match_<userId1>_<userId2>) para evitar duplicados
3. WHEN já existe um chat THEN o sistema SHALL reutilizar o existente sem criar duplicado
4. WHEN há erro na criação THEN o sistema SHALL tentar novamente automaticamente

### Requirement 2

**User Story:** Como usuário, eu quero que o botão "Conversar" abra corretamente a janela de chat, para que eu possa iniciar uma conversa sem falhas.

#### Acceptance Criteria

1. WHEN o usuário clica no botão "Conversar" THEN o sistema SHALL verificar se o chat já existe
2. WHEN o chat não existe THEN o sistema SHALL criar o chat e em seguida abrir a janela
3. WHEN o chat existe THEN o sistema SHALL abrir diretamente a janela de chat
4. WHEN há erro THEN o sistema SHALL mostrar feedback apropriado ao usuário

### Requirement 3

**User Story:** Como usuário, eu quero que todas as queries do Firestore funcionem corretamente, para que não haja erros de índice que quebrem o fluxo do chat.

#### Acceptance Criteria

1. WHEN o sistema faz query em chat_messages com orderBy(timestamp) THEN o sistema SHALL funcionar sem erro de índice
2. WHEN há múltiplos filtros na query THEN o sistema SHALL ter índices compostos necessários
3. WHEN falta um índice THEN o sistema SHALL gerar automaticamente ou retornar erro tratado
4. WHEN o índice não pode ser criado THEN o sistema SHALL implementar fallback funcional

### Requirement 4

**User Story:** Como usuário, eu quero que o sistema trate adequadamente notificações duplicadas, para que não haja exceções que quebrem o fluxo.

#### Acceptance Criteria

1. WHEN uma notificação vai ser marcada como respondida THEN o sistema SHALL verificar o estado atual
2. WHEN a notificação já foi respondida THEN o sistema SHALL tratar graciosamente sem gerar exceção
3. WHEN há resposta duplicada THEN o sistema SHALL identificar se foi por motivo de match mútuo
4. WHEN há conflito de estado THEN o sistema SHALL resolver automaticamente

### Requirement 5

**User Story:** Como usuário, eu quero receber feedback claro sobre o status do chat, para que eu saiba quando há problemas e como resolvê-los.

#### Acceptance Criteria

1. WHEN o chat está sendo criado THEN o sistema SHALL mostrar "Estamos criando seu chat... tente novamente em alguns segundos"
2. WHEN há erro de índice THEN o sistema SHALL mostrar notificação com link para correção
3. WHEN o chat é criado com sucesso THEN o sistema SHALL abrir automaticamente a janela
4. WHEN há falha persistente THEN o sistema SHALL mostrar opções de recuperação

### Requirement 6

**User Story:** Como usuário, eu quero que o sistema garanta que ao dar match um chat válido sempre seja criado ou reutilizado, para que eu nunca fique sem poder conversar.

#### Acceptance Criteria

1. WHEN um match é aceito THEN o sistema SHALL garantir que um chat válido existe
2. WHEN o chat já existe THEN o sistema SHALL reutilizar sem criar duplicado
3. WHEN há erro na criação THEN o sistema SHALL implementar retry automático
4. WHEN todos os retries falham THEN o sistema SHALL mostrar erro claro e opção manual