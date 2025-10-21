# Requirements Document

## Introduction

Este documento define os requisitos para restaurar e melhorar o sistema de convites do chat "Nosso Propósito", incluindo a funcionalidade de convites de parceria, sistema de @menções, e restrições para chat sem parceiro.

## Requirements

### Requirement 1: Sistema de Convites de Parceria

**User Story:** Como usuário do chat "Nosso Propósito", eu quero poder enviar convites de parceria para outros usuários, para que possamos conversar juntos no chat compartilhado.

#### Acceptance Criteria

1. WHEN o usuário não tem parceiro ativo THEN o sistema SHALL exibir um botão de convite visível no chat
2. WHEN o usuário clica no botão de convite THEN o sistema SHALL abrir um modal com duas abas: "Buscar Usuário" e "Mensagem do Convite"
3. WHEN o usuário busca por email na aba "Buscar Usuário" THEN o sistema SHALL mostrar o perfil do usuário encontrado
4. WHEN o usuário escreve uma mensagem na aba "Mensagem do Convite" THEN o sistema SHALL permitir personalizar o convite
5. WHEN o usuário envia o convite THEN o sistema SHALL salvar no Firebase e notificar o destinatário

### Requirement 2: Recebimento e Resposta de Convites

**User Story:** Como usuário que recebe um convite de parceria, eu quero poder visualizar, aceitar, recusar ou bloquear convites, para que eu tenha controle sobre minhas parcerias.

#### Acceptance Criteria

1. WHEN o usuário recebe um convite THEN o sistema SHALL exibir o componente PurposeInvitesComponent no topo do chat
2. WHEN o usuário visualiza um convite THEN o sistema SHALL mostrar o nome do remetente, mensagem personalizada e botões de ação
3. WHEN o usuário clica em "Aceitar" THEN o sistema SHALL criar a parceria e ativar o chat compartilhado
4. WHEN o usuário clica em "Recusar" THEN o sistema SHALL marcar o convite como rejeitado
5. WHEN o usuário clica em "Bloquear" THEN o sistema SHALL bloquear o remetente e impedir futuros convites

### Requirement 3: Sistema de @Menções

**User Story:** Como usuário com parceria ativa, eu quero poder mencionar outros usuários com @, para que eles possam ser convidados para participar da conversa.

#### Acceptance Criteria

1. WHEN o usuário digita @ no campo de mensagem THEN o sistema SHALL mostrar autocomplete com usuários disponíveis
2. WHEN o usuário seleciona um usuário do autocomplete THEN o sistema SHALL inserir a menção no texto
3. WHEN o usuário envia uma mensagem com @menção THEN o sistema SHALL enviar convite de menção para o usuário mencionado
4. WHEN o usuário mencionado aceita o convite THEN o sistema SHALL adicioná-lo ao chat compartilhado
5. WHEN há menções na mensagem THEN o sistema SHALL destacar visualmente as menções

### Requirement 4: Restrição de Chat Sem Parceiro

**User Story:** Como usuário sem parceiro ativo, eu quero ser impedido de enviar mensagens sozinho, para que o chat mantenha seu propósito de conversa compartilhada.

#### Acceptance Criteria

1. WHEN o usuário não tem parceiro ativo THEN o sistema SHALL desabilitar o campo de mensagem
2. WHEN o usuário tenta enviar mensagem sem parceiro THEN o sistema SHALL mostrar mensagem "Você precisa ter uma pessoa adicionada para iniciar esse chat"
3. WHEN a mensagem de restrição é exibida THEN ela SHALL aparecer em destaque no topo do chat
4. WHEN o usuário adiciona um parceiro THEN o sistema SHALL remover a restrição e habilitar o chat
5. WHEN há parceria ativa THEN o sistema SHALL permitir envio normal de mensagens

### Requirement 5: Interface de Convite Fixa

**User Story:** Como usuário do chat "Nosso Propósito", eu quero ter uma interface de convite sempre visível quando necessário, para que eu possa facilmente gerenciar parcerias.

#### Acceptance Criteria

1. WHEN o usuário não tem parceiro THEN o sistema SHALL exibir interface de convite fixa no topo do chat
2. WHEN o usuário tem convites pendentes THEN o sistema SHALL exibir o componente de convites abaixo da interface de convite
3. WHEN o usuário tem parceria ativa THEN o sistema SHALL ocultar a interface de convite
4. WHEN a interface está visível THEN ela SHALL ter design consistente com o gradiente azul/rosa do chat
5. WHEN o usuário interage com a interface THEN o sistema SHALL fornecer feedback visual adequado

### Requirement 6: Validações e Segurança

**User Story:** Como sistema, eu quero validar todos os convites e interações, para que apenas usuários válidos possam formar parcerias.

#### Acceptance Criteria

1. WHEN um convite é enviado THEN o sistema SHALL verificar se o destinatário existe e não está bloqueado
2. WHEN um convite é enviado THEN o sistema SHALL verificar se não há convite pendente duplicado
3. WHEN uma parceria é criada THEN o sistema SHALL verificar se ambos usuários não têm parceria ativa
4. WHEN um usuário é bloqueado THEN o sistema SHALL impedir todos os futuros convites deste usuário
5. WHEN há erro em qualquer operação THEN o sistema SHALL mostrar mensagem de erro clara ao usuário