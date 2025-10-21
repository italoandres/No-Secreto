# Requirements Document

## Introduction

Esta funcionalidade transforma o módulo de Stories do app em uma experiência similar ao TikTok, com foco em engajamento, comunidade e interatividade. O sistema incluirá curtidas, comentários, respostas, menções de usuários e notificações, criando um ambiente social dinâmico.

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero visualizar stories em tela cheia com rolagem lateral, para que eu tenha uma experiência imersiva similar ao TikTok

#### Acceptance Criteria

1. WHEN o usuário acessa stories THEN o sistema SHALL exibir em tela cheia vertical
2. WHEN o usuário desliza para o lado THEN o sistema SHALL trocar para o próximo story
3. WHEN um vídeo termina THEN o sistema SHALL fazer loop automático
4. WHEN um vídeo carrega THEN o sistema SHALL iniciar autoplay automaticamente
5. WHEN o usuário interage THEN a interface SHALL responder de forma fluida e responsiva

### Requirement 2

**User Story:** Como usuário, eu quero curtir stories com ícone de oração, para que eu possa expressar minha reação de forma espiritual

#### Acceptance Criteria

1. WHEN o usuário toca no ícone de oração THEN o sistema SHALL registrar uma curtida
2. WHEN o usuário faz toque duplo no vídeo THEN o sistema SHALL curtir e mostrar animação
3. WHEN uma curtida é registrada THEN o sistema SHALL exibir animação de oração flutuante
4. WHEN há curtidas THEN o sistema SHALL exibir a quantidade total
5. WHEN o usuário já curtiu THEN o ícone SHALL aparecer destacado

### Requirement 3

**User Story:** Como usuário, eu quero salvar stories favoritos, para que eu possa acessá-los posteriormente

#### Acceptance Criteria

1. WHEN o usuário toca no botão salvar THEN o sistema SHALL adicionar aos favoritos
2. WHEN um story é salvo THEN o sistema SHALL exibir confirmação visual
3. WHEN o usuário acessa perfil THEN o sistema SHALL mostrar aba "Favoritos"
4. WHEN o usuário remove dos favoritos THEN o sistema SHALL atualizar a lista
5. WHEN há stories salvos THEN o sistema SHALL manter sincronização entre dispositivos

### Requirement 4

**User Story:** Como usuário, eu quero comentar em stories, para que eu possa interagir com a comunidade

#### Acceptance Criteria

1. WHEN o usuário toca no botão comentário THEN o sistema SHALL abrir modal inferior
2. WHEN o usuário digita comentário THEN o sistema SHALL permitir texto e emojis
3. WHEN comentário é enviado THEN o sistema SHALL exibir com nome de usuário e @
4. WHEN há comentários THEN o sistema SHALL ordenar por relevância/recentes
5. WHEN usuário não está autenticado THEN o sistema SHALL impedir comentários

### Requirement 5

**User Story:** Como usuário, eu quero responder comentários, para que eu possa criar conversas em threads

#### Acceptance Criteria

1. WHEN o usuário toca "responder" THEN o sistema SHALL abrir campo de resposta
2. WHEN resposta é enviada THEN o sistema SHALL criar sub-thread
3. WHEN há respostas THEN o sistema SHALL exibir "ver respostas" retraído
4. WHEN usuário clica "ver respostas" THEN o sistema SHALL expandir thread
5. WHEN resposta é criada THEN o sistema SHALL marcar automaticamente o @ do usuário

### Requirement 6

**User Story:** Como usuário, eu quero mencionar outros usuários, para que eu possa direcioná-los para conversas específicas

#### Acceptance Criteria

1. WHEN o usuário digita @ THEN o sistema SHALL mostrar sugestões de usuários
2. WHEN usuário seleciona menção THEN o sistema SHALL completar automaticamente
3. WHEN menção é enviada THEN o usuário mencionado SHALL receber notificação
4. WHEN há menção THEN o sistema SHALL destacar visualmente no comentário
5. WHEN usuário clica na menção THEN o sistema SHALL navegar para o perfil

### Requirement 7

**User Story:** Como usuário, eu quero receber notificações de interações, para que eu saiba quando há atividade nos meus comentários

#### Acceptance Criteria

1. WHEN comentário é curtido THEN o autor SHALL receber notificação
2. WHEN comentário é respondido THEN o autor SHALL receber notificação
3. WHEN usuário é mencionado THEN ele SHALL receber notificação
4. WHEN notificação é enviada THEN o sistema SHALL usar Firebase Cloud Messaging
5. WHEN usuário abre notificação THEN o sistema SHALL navegar para o story específico

### Requirement 8

**User Story:** Como administrador, eu quero que stories sejam publicados automaticamente em sequência, para que novos usuários tenham conteúdo infinito

#### Acceptance Criteria

1. WHEN novo story é adicionado THEN o sistema SHALL programar publicação sequencial
2. WHEN usuário termina de ver stories THEN o sistema SHALL carregar próximos automaticamente
3. WHEN há novos stories THEN o sistema SHALL notificar usuários
4. WHEN stories são carregados THEN o sistema SHALL otimizar cache e dados
5. WHEN sistema detecta fim da lista THEN o sistema SHALL recomeçar do início

### Requirement 9

**User Story:** Como desenvolvedor, eu quero sistema de moderação automática, para que comentários inadequados sejam filtrados

#### Acceptance Criteria

1. WHEN comentário é enviado THEN o sistema SHALL verificar filtro de palavras
2. WHEN palavra inadequada é detectada THEN o sistema SHALL bloquear comentário
3. WHEN comentário é bloqueado THEN o sistema SHALL notificar usuário
4. WHEN admin revisa THEN o sistema SHALL permitir aprovação manual
5. WHEN filtro é atualizado THEN o sistema SHALL aplicar retroativamente

### Requirement 10

**User Story:** Como administrador, eu quero analytics de engajamento, para que eu possa entender o comportamento dos usuários

#### Acceptance Criteria

1. WHEN story é visualizado THEN o sistema SHALL registrar view
2. WHEN usuário interage THEN o sistema SHALL registrar tempo assistido
3. WHEN há interações THEN o sistema SHALL contar likes e comentários
4. WHEN dados são coletados THEN o sistema SHALL gerar relatórios
5. WHEN admin acessa THEN o sistema SHALL exibir dashboard de analytics