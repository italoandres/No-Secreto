# Requirements Document - Stories System Fixes

## Introduction

Este documento define os requisitos para corrigir os problemas restantes no sistema de stories, incluindo índices do Firebase, histórico de stories e carregamento de imagens.

## Requirements

### Requirement 1 - Firebase Indexes

**User Story:** Como usuário do sistema, eu quero que as consultas de likes e comentários funcionem sem erros, para que eu possa interagir com os stories normalmente.

#### Acceptance Criteria

1. WHEN o sistema consulta likes de um story THEN a consulta deve executar sem erro de índice
2. WHEN o sistema consulta comentários de um story THEN a consulta deve executar sem erro de índice
3. WHEN os índices são criados THEN todas as consultas do Firebase devem funcionar corretamente

### Requirement 2 - Stories History

**User Story:** Como usuário, eu quero que meus stories sejam automaticamente salvos no histórico após 24 horas, para que eu possa revisá-los posteriormente.

#### Acceptance Criteria

1. WHEN um story completa 24 horas THEN ele deve ser movido para a coleção `stories_antigos`
2. WHEN um story é movido para o histórico THEN ele deve manter todos os dados originais
3. WHEN acesso o histórico THEN devo ver todos os meus stories antigos com imagens carregando corretamente

### Requirement 3 - Image Loading

**User Story:** Como usuário, eu quero que as imagens dos stories carreguem rapidamente e sem erros, para ter uma experiência fluida.

#### Acceptance Criteria

1. WHEN visualizo um story com imagem THEN a imagem deve carregar completamente
2. WHEN há erro de carregamento THEN deve mostrar um placeholder ou tentar novamente
3. WHEN acesso o histórico THEN as imagens antigas devem carregar corretamente

### Requirement 4 - Stories Auto-Close

**User Story:** Como usuário, eu quero que os stories fechem automaticamente após o tempo definido, para que a experiência seja similar ao Instagram/WhatsApp.

#### Acceptance Criteria

1. WHEN um story de imagem é exibido THEN deve fechar automaticamente após 10 segundos
2. WHEN um story de vídeo é exibido THEN deve fechar automaticamente após a duração do vídeo
3. WHEN o usuário toca na tela THEN deve avançar para o próximo story ou fechar se for o último