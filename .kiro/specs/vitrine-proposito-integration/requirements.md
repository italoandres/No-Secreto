# Requirements Document

## Introduction

Este documento define os requisitos para integrar e melhorar o sistema de "Vitrine de Propósito", consolidando funcionalidades de username e foto de perfil que estão atualmente espalhadas entre diferentes telas. O objetivo é criar uma experiência unificada onde o usuário pode gerenciar todas as informações do seu perfil público em um só lugar, além de corrigir erros de tipo que estão causando falhas no sistema.

## Requirements

### Requirement 1

**User Story:** Como usuário, quero poder criar e editar meu username diretamente na Vitrine de Propósito, para que eu não precise navegar entre diferentes telas para gerenciar minha identidade pública.

#### Acceptance Criteria

1. WHEN o usuário acessa a Vitrine de Propósito THEN o sistema SHALL exibir o username atual ou uma opção para criar um username se não existir
2. WHEN o usuário clica em editar username THEN o sistema SHALL abrir um campo de edição inline ou modal para modificar o username
3. WHEN o usuário salva um novo username THEN o sistema SHALL validar a unicidade e atualizar tanto o perfil espiritual quanto o perfil de usuário
4. WHEN o username é atualizado THEN o sistema SHALL sincronizar automaticamente com todas as outras telas que exibem o username

### Requirement 2

**User Story:** Como usuário, quero gerenciar minha foto de perfil diretamente na Vitrine de Propósito, para que eu tenha controle completo sobre minha apresentação visual em um só lugar.

#### Acceptance Criteria

1. WHEN o usuário acessa a Vitrine de Propósito THEN o sistema SHALL exibir a foto de perfil atual ou um placeholder se não existir
2. WHEN o usuário clica na foto de perfil THEN o sistema SHALL oferecer opções para alterar, remover ou adicionar uma nova foto
3. WHEN o usuário seleciona uma nova foto THEN o sistema SHALL fazer upload e atualizar tanto o perfil espiritual quanto o perfil de usuário
4. WHEN a foto é atualizada THEN o sistema SHALL sincronizar automaticamente com todas as outras telas que exibem a foto

### Requirement 3

**User Story:** Como usuário, quero que as informações do meu perfil (nome, username, foto) sejam sincronizadas automaticamente entre "Editar Perfil" e "Vitrine de Propósito", para que eu não tenha dados inconsistentes.

#### Acceptance Criteria

1. WHEN o usuário atualiza informações em qualquer tela THEN o sistema SHALL sincronizar automaticamente com todas as outras telas
2. WHEN há conflito de dados THEN o sistema SHALL usar a fonte de verdade mais recente (Firestore)
3. WHEN o sistema detecta dados inconsistentes THEN o sistema SHALL executar migração automática para corrigir
4. WHEN a sincronização falha THEN o sistema SHALL exibir mensagem de erro clara e permitir retry

### Requirement 4

**User Story:** Como usuário, quero que os erros de tipo (Timestamp vs Bool) sejam corrigidos automaticamente, para que eu não tenha falhas no carregamento do meu perfil.

#### Acceptance Criteria

1. WHEN o sistema carrega dados do perfil THEN o sistema SHALL verificar e corrigir automaticamente tipos de dados incorretos
2. WHEN encontra um campo boolean com tipo Timestamp THEN o sistema SHALL converter para boolean e atualizar no Firestore
3. WHEN encontra dados corrompidos THEN o sistema SHALL aplicar valores padrão seguros e registrar no log
4. WHEN a migração é executada THEN o sistema SHALL confirmar que os dados foram corrigidos antes de prosseguir

### Requirement 5

**User Story:** Como usuário, quero que o carregamento de imagens seja mais robusto, para que eu não veja erros de rede quando visualizo perfis.

#### Acceptance Criteria

1. WHEN uma imagem falha ao carregar THEN o sistema SHALL exibir um placeholder apropriado em vez de erro
2. WHEN há problemas de conectividade THEN o sistema SHALL tentar recarregar automaticamente
3. WHEN a URL da imagem é inválida THEN o sistema SHALL usar uma imagem padrão
4. WHEN o usuário não tem foto THEN o sistema SHALL exibir um avatar gerado com as iniciais do nome

### Requirement 6

**User Story:** Como desenvolvedor, quero que o sistema tenha logs detalhados de debug, para que eu possa identificar e corrigir problemas rapidamente.

#### Acceptance Criteria

1. WHEN operações críticas são executadas THEN o sistema SHALL registrar logs detalhados com timestamps
2. WHEN erros ocorrem THEN o sistema SHALL registrar o contexto completo do erro
3. WHEN dados são migrados THEN o sistema SHALL registrar o antes e depois da migração
4. WHEN o sistema está em modo debug THEN o sistema SHALL exibir informações adicionais na interface