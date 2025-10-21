# Requirements Document

## Introduction

O chat "Nosso Propósito" não está carregando os stories publicados especificamente para seu contexto. Atualmente, o sistema está tentando carregar stories do contexto "principal" em vez do contexto "nosso_proposito", causando uma desconexão entre a publicação e a visualização.

## Requirements

### Requirement 1

**User Story:** Como um usuário no chat "Nosso Propósito", eu quero ver os stories publicados especificamente para este contexto, para que eu possa visualizar o conteúdo direcionado ao nosso relacionamento.

#### Acceptance Criteria

1. WHEN um story é publicado com contexto 'nosso_proposito' THEN o sistema SHALL salvar na coleção 'stories_nosso_proposito'
2. WHEN o chat "Nosso Propósito" é carregado THEN o sistema SHALL buscar stories da coleção 'stories_nosso_proposito'
3. WHEN stories do contexto 'nosso_proposito' existem THEN eles SHALL aparecer na logo do chat "Nosso Propósito"
4. WHEN não há stories no contexto 'nosso_proposito' THEN a logo SHALL aparecer sem indicador de stories

### Requirement 2

**User Story:** Como um administrador, eu quero que os stories publicados para "Nosso Propósito" apareçam apenas no chat correspondente, para que haja isolamento correto de contextos.

#### Acceptance Criteria

1. WHEN um story é publicado para contexto 'nosso_proposito' THEN ele SHALL aparecer apenas no chat "Nosso Propósito"
2. WHEN um story é publicado para contexto 'nosso_proposito' THEN ele SHALL NOT aparecer no chat principal
3. WHEN um story é publicado para contexto 'nosso_proposito' THEN ele SHALL NOT aparecer nos chats "Sinais de Isaque" ou "Sinais de Rebeca"

### Requirement 3

**User Story:** Como um usuário, eu quero que o sistema de favoritos funcione corretamente para stories do contexto "Nosso Propósito", para que eu possa salvar e acessar meus stories preferidos.

#### Acceptance Criteria

1. WHEN eu acesso favoritos do contexto 'nosso_proposito' THEN o sistema SHALL carregar apenas stories favoritados deste contexto
2. WHEN eu favorito um story do contexto 'nosso_proposito' THEN ele SHALL ser salvo com o contexto correto
3. WHEN eu acesso a tela de favoritos via notificações do "Nosso Propósito" THEN o sistema SHALL mostrar o título "Stories Favoritos - Nosso Propósito"

### Requirement 4

**User Story:** Como um desenvolvedor, eu quero que o sistema de carregamento de stories seja consistente entre todos os contextos, para que a manutenção seja simplificada.

#### Acceptance Criteria

1. WHEN o sistema carrega stories THEN ele SHALL usar o contexto correto baseado na tela atual
2. WHEN há erro no carregamento THEN o sistema SHALL mostrar mensagem de erro apropriada
3. WHEN o contexto é inválido THEN o sistema SHALL usar fallback apropriado sem quebrar a funcionalidade
4. WHEN stories são carregados THEN o sistema SHALL aplicar filtros de contexto corretamente

### Requirement 5

**User Story:** Como um usuário, eu quero que a detecção de stories não vistos funcione corretamente no contexto "Nosso Propósito", para que eu saiba quando há conteúdo novo.

#### Acceptance Criteria

1. WHEN há stories não vistos no contexto 'nosso_proposito' THEN a logo SHALL mostrar indicador visual (círculo colorido)
2. WHEN todos os stories do contexto 'nosso_proposito' foram vistos THEN a logo SHALL aparecer sem indicador
3. WHEN eu visualizo um story do contexto 'nosso_proposito' THEN ele SHALL ser marcado como visto
4. WHEN eu marco um story como visto THEN o indicador visual SHALL ser atualizado em tempo real