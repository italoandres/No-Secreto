# Sistema de Notificações de Stories - Requisitos

## Introdução

Este documento define os requisitos para implementar um sistema de notificações focado em comentários de stories. O sistema incluirá um ícone de notificação na capa do chat principal que abrirá uma página dedicada às notificações, com foco inicial em comentários de stories.

## Requisitos

### Requisito 1: Ícone de Notificação na Capa Principal

**User Story:** Como usuário, eu quero ver um ícone de notificação ao lado do ícone de comunidade na capa do chat principal, para que eu possa acessar rapidamente minhas notificações.

#### Acceptance Criteria

1. QUANDO o usuário visualizar a capa do chat principal ENTÃO o sistema SHALL exibir um ícone de notificação (sino) ao lado do ícone de comunidade
2. QUANDO existirem notificações não lidas ENTÃO o sistema SHALL exibir um badge vermelho com o número de notificações
3. QUANDO o usuário tocar no ícone de notificação ENTÃO o sistema SHALL navegar para a página de notificações
4. QUANDO não existirem notificações ENTÃO o sistema SHALL exibir o ícone sem badge

### Requisito 2: Página de Notificações

**User Story:** Como usuário, eu quero acessar uma página dedicada às notificações, para que eu possa visualizar e gerenciar todas as minhas notificações de forma organizada.

#### Acceptance Criteria

1. QUANDO o usuário acessar a página de notificações ENTÃO o sistema SHALL exibir uma lista de todas as notificações
2. QUANDO a página for carregada ENTÃO o sistema SHALL marcar todas as notificações como lidas
3. QUANDO não existirem notificações ENTÃO o sistema SHALL exibir uma mensagem informativa
4. QUANDO o usuário tocar em uma notificação ENTÃO o sistema SHALL navegar para o conteúdo relacionado

### Requisito 3: Notificações de Comentários em Stories

**User Story:** Como usuário que postou um story, eu quero receber notificações quando alguém comentar no meu story, para que eu possa acompanhar as interações.

#### Acceptance Criteria

1. QUANDO um usuário comentar em um story ENTÃO o sistema SHALL criar uma notificação para o autor do story
2. QUANDO uma notificação de comentário for criada ENTÃO o sistema SHALL incluir o nome do usuário que comentou
3. QUANDO uma notificação de comentário for criada ENTÃO o sistema SHALL incluir o texto do comentário (limitado a 100 caracteres)
4. QUANDO uma notificação de comentário for criada ENTÃO o sistema SHALL incluir a data/hora do comentário
5. QUANDO o usuário tocar na notificação ENTÃO o sistema SHALL abrir o story com os comentários visíveis

### Requisito 4: Estrutura de Dados das Notificações

**User Story:** Como desenvolvedor, eu quero uma estrutura de dados consistente para as notificações, para que o sistema possa armazenar e recuperar as informações de forma eficiente.

#### Acceptance Criteria

1. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar o ID único da notificação
2. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar o ID do usuário destinatário
3. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar o tipo da notificação (story_comment)
4. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar o ID do story relacionado
5. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar o ID do usuário que gerou a notificação
6. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar o status de lida/não lida
7. QUANDO uma notificação for criada ENTÃO o sistema SHALL armazenar a data/hora de criação

### Requisito 5: Interface da Página de Notificações

**User Story:** Como usuário, eu quero uma interface clara e intuitiva na página de notificações, para que eu possa facilmente identificar e interagir com minhas notificações.

#### Acceptance Criteria

1. QUANDO a página de notificações for exibida ENTÃO o sistema SHALL mostrar um cabeçalho com título "Notificações"
2. QUANDO uma notificação de comentário for exibida ENTÃO o sistema SHALL mostrar o avatar do usuário que comentou
3. QUANDO uma notificação de comentário for exibida ENTÃO o sistema SHALL mostrar o nome do usuário que comentou
4. QUANDO uma notificação de comentário for exibida ENTÃO o sistema SHALL mostrar uma prévia do comentário
5. QUANDO uma notificação de comentário for exibida ENTÃO o sistema SHALL mostrar o tempo relativo (ex: "há 2 horas")
6. QUANDO uma notificação for não lida ENTÃO o sistema SHALL destacá-la visualmente
7. QUANDO a lista estiver vazia ENTÃO o sistema SHALL exibir uma mensagem "Nenhuma notificação ainda"

### Requisito 6: Integração com Sistema de Stories Existente

**User Story:** Como desenvolvedor, eu quero integrar o sistema de notificações com o sistema de stories existente, para que as notificações sejam geradas automaticamente quando comentários forem criados.

#### Acceptance Criteria

1. QUANDO um comentário for salvo no Firestore ENTÃO o sistema SHALL verificar se deve criar uma notificação
2. QUANDO o autor do comentário for diferente do autor do story ENTÃO o sistema SHALL criar uma notificação
3. QUANDO o autor do comentário for o mesmo do story ENTÃO o sistema SHALL NOT criar uma notificação
4. QUANDO uma notificação for criada ENTÃO o sistema SHALL atualizar o contador de notificações não lidas