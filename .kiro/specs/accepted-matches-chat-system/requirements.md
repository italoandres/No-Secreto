# Requirements Document

## Introduction

Este sistema permite que usuários visualizem seus matches aceitos e iniciem chats temporários de 30 dias com cada match. O sistema integra com as notificações de interesse existentes e fornece uma experiência completa de comunicação entre matches.

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero ver uma lista dos meus matches aceitos, para que eu possa visualizar todas as pessoas que aceitaram meu interesse ou cujo interesse eu aceitei.

#### Acceptance Criteria

1. WHEN o usuário acessa "Gerencie seus Matches" > "Aceitos" THEN o sistema SHALL exibir uma lista de todos os matches aceitos
2. WHEN a lista é carregada THEN o sistema SHALL mostrar foto, nome e data do match para cada item
3. WHEN não há matches aceitos THEN o sistema SHALL exibir uma mensagem explicativa
4. WHEN há matches aceitos THEN o sistema SHALL ordenar por data mais recente primeiro

### Requirement 2

**User Story:** Como usuário, eu quero clicar em um match aceito para abrir um chat temporário, para que eu possa conversar com a pessoa por 30 dias.

#### Acceptance Criteria

1. WHEN o usuário clica em um match aceito THEN o sistema SHALL abrir a tela de chat temporário
2. WHEN o chat é aberto THEN o sistema SHALL mostrar o nome e foto do match no cabeçalho
3. WHEN o chat é criado THEN o sistema SHALL definir expiração de 30 dias a partir da data do match
4. WHEN o chat expira THEN o sistema SHALL bloquear o envio de novas mensagens

### Requirement 3

**User Story:** Como usuário, eu quero enviar e receber mensagens no chat temporário, para que eu possa me comunicar com meu match durante o período permitido.

#### Acceptance Criteria

1. WHEN o usuário digita uma mensagem THEN o sistema SHALL permitir envio se o chat não expirou
2. WHEN uma mensagem é enviada THEN o sistema SHALL salvar no Firebase com timestamp
3. WHEN há novas mensagens THEN o sistema SHALL atualizar em tempo real
4. WHEN o chat expira THEN o sistema SHALL mostrar aviso de expiração

### Requirement 4

**User Story:** Como usuário, eu quero ver o status do tempo restante do chat, para que eu saiba quanto tempo tenho para conversar.

#### Acceptance Criteria

1. WHEN o chat é aberto THEN o sistema SHALL mostrar dias restantes no cabeçalho
2. WHEN restam menos de 7 dias THEN o sistema SHALL destacar o aviso em amarelo
3. WHEN restam menos de 24 horas THEN o sistema SHALL destacar o aviso em vermelho
4. WHEN o chat expira THEN o sistema SHALL mostrar "Chat Expirado"

### Requirement 5

**User Story:** Como usuário, eu quero que o sistema gerencie automaticamente a criação e expiração dos chats, para que eu não precise me preocupar com configurações técnicas.

#### Acceptance Criteria

1. WHEN um match é aceito THEN o sistema SHALL criar automaticamente um chat temporário
2. WHEN o chat é criado THEN o sistema SHALL definir data de expiração (30 dias)
3. WHEN o chat expira THEN o sistema SHALL manter histórico mas bloquear novas mensagens
4. WHEN há erro na criação THEN o sistema SHALL tentar novamente automaticamente

### Requirement 6

**User Story:** Como usuário, eu quero navegar facilmente entre a lista de matches e os chats individuais, para que eu possa gerenciar múltiplas conversas.

#### Acceptance Criteria

1. WHEN estou no chat THEN o sistema SHALL mostrar botão "Voltar" para lista de matches
2. WHEN volto para lista THEN o sistema SHALL mostrar indicador de mensagens não lidas
3. WHEN há mensagens não lidas THEN o sistema SHALL destacar o match na lista
4. WHEN clico em outro match THEN o sistema SHALL navegar para o chat correspondente