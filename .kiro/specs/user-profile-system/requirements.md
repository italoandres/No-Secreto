# Requirements Document

## Introduction

Esta funcionalidade implementa um sistema de perfil de usuário com username único (com @) e edição de nome, transformando o app em uma rede social. O sistema deve verificar disponibilidade de username em tempo real e permitir edição de perfil através do menu de 3 pontos.

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero editar meu nome de exibição, para que eu possa personalizar como apareço para outros usuários

#### Acceptance Criteria

1. WHEN o usuário acessa o menu de 3 pontos THEN o sistema SHALL exibir opção "Editar Perfil"
2. WHEN o usuário seleciona "Editar Perfil" THEN o sistema SHALL abrir tela de edição com campo de nome atual
3. WHEN o usuário modifica o nome THEN o sistema SHALL validar que não está vazio
4. WHEN o usuário salva o nome THEN o sistema SHALL atualizar no Firebase e exibir confirmação

### Requirement 2

**User Story:** Como usuário, eu quero criar um username único com @, para que eu tenha uma identidade única na rede social

#### Acceptance Criteria

1. WHEN o usuário acessa edição de perfil THEN o sistema SHALL exibir campo para username com @
2. WHEN o usuário digita um username THEN o sistema SHALL verificar disponibilidade em tempo real
3. IF username já existe THEN o sistema SHALL exibir "Username não disponível" em vermelho
4. IF username está disponível THEN o sistema SHALL exibir "Username disponível" em verde
5. WHEN o usuário salva username disponível THEN o sistema SHALL reservar no Firebase

### Requirement 3

**User Story:** Como usuário, eu quero que o sistema valide usernames, para que não haja duplicatas ou formatos inválidos

#### Acceptance Criteria

1. WHEN o usuário digita username THEN o sistema SHALL validar formato (apenas letras, números, underscore)
2. WHEN username tem menos de 3 caracteres THEN o sistema SHALL exibir erro de tamanho mínimo
3. WHEN username tem mais de 20 caracteres THEN o sistema SHALL exibir erro de tamanho máximo
4. WHEN username contém caracteres especiais inválidos THEN o sistema SHALL exibir erro de formato
5. WHEN o usuário tenta salvar username inválido THEN o sistema SHALL impedir salvamento

### Requirement 4

**User Story:** Como usuário, eu quero ver meu username atual no perfil, para que eu saiba qual é minha identidade na rede social

#### Acceptance Criteria

1. WHEN o usuário acessa edição de perfil THEN o sistema SHALL exibir username atual (se existir)
2. WHEN usuário não tem username THEN o sistema SHALL exibir placeholder "Criar username"
3. WHEN o usuário visualiza seu perfil THEN o sistema SHALL exibir @username junto com o nome
4. WHEN outros usuários veem o perfil THEN o sistema SHALL exibir @username publicamente

### Requirement 5

**User Story:** Como desenvolvedor, eu quero que o sistema seja performático, para que a verificação de username seja rápida

#### Acceptance Criteria

1. WHEN o usuário digita username THEN o sistema SHALL fazer debounce de 500ms antes de verificar
2. WHEN verificação está em andamento THEN o sistema SHALL exibir indicador de carregamento
3. WHEN verificação falha THEN o sistema SHALL exibir erro e permitir tentar novamente
4. WHEN usuário cancela edição THEN o sistema SHALL cancelar verificações pendentes