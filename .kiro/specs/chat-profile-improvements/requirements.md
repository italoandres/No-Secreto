# Requirements Document

## Introduction

Esta spec visa melhorar a experiência do usuário no chat principal, reorganizando as opções de personalização de perfil. Atualmente existe um ícone de câmera no canto superior direito que permite alterar foto de perfil e papel de parede, mas isso cria redundância já que a foto de perfil também pode ser alterada no menu "Editar Perfil". A proposta é consolidar todas as opções de personalização em um local único e mais intuitivo.

## Requirements

### Requirement 1

**User Story:** Como usuário do chat, eu quero ter todas as opções de personalização do meu perfil em um local único e organizado, para que eu não precise procurar em vários lugares diferentes.

#### Acceptance Criteria

1. WHEN o usuário acessa o menu "Editar Perfil" (3 pontos) THEN o sistema SHALL exibir as opções: username, nome, foto de perfil e papel de parede
2. WHEN o usuário clica em "Foto de Perfil" no menu Editar Perfil THEN o sistema SHALL abrir o seletor de imagens para alterar a foto de perfil
3. WHEN o usuário clica em "Papel de Parede" no menu Editar Perfil THEN o sistema SHALL abrir o seletor de imagens para alterar o papel de parede do chat
4. WHEN o usuário altera o papel de parede THEN o sistema SHALL aplicar a mudança imediatamente no chat principal

### Requirement 2

**User Story:** Como usuário do chat, eu quero que o ícone de câmera no canto superior direito seja removido, para que a interface fique mais limpa e organizada.

#### Acceptance Criteria

1. WHEN o usuário visualiza o chat principal THEN o sistema SHALL NOT exibir o ícone de câmera no canto superior direito
2. WHEN o usuário procura por opções de personalização THEN o sistema SHALL direcionar apenas para o menu "Editar Perfil"
3. WHEN o ícone de câmera é removido THEN o sistema SHALL manter todas as funcionalidades existentes através do menu "Editar Perfil"

### Requirement 3

**User Story:** Como usuário do chat, eu quero que o menu "Editar Perfil" tenha uma interface clara e organizada, para que eu possa facilmente encontrar e alterar minhas configurações de personalização.

#### Acceptance Criteria

1. WHEN o usuário abre o menu "Editar Perfil" THEN o sistema SHALL exibir os campos organizados na seguinte ordem: Username, Nome, Foto de Perfil, Papel de Parede
2. WHEN o usuário visualiza as opções de imagem THEN o sistema SHALL mostrar previews das imagens atuais (foto de perfil e papel de parede)
3. WHEN o usuário altera qualquer configuração THEN o sistema SHALL salvar automaticamente as mudanças
4. WHEN o usuário cancela uma alteração de imagem THEN o sistema SHALL manter a imagem anterior sem alterações

### Requirement 4

**User Story:** Como usuário do chat, eu quero que as alterações de papel de parede sejam aplicadas imediatamente, para que eu possa ver o resultado da minha personalização em tempo real.

#### Acceptance Criteria

1. WHEN o usuário seleciona um novo papel de parede THEN o sistema SHALL aplicar a mudança imediatamente no chat
2. WHEN o papel de parede é alterado THEN o sistema SHALL manter a legibilidade das mensagens
3. WHEN o usuário volta ao chat após alterar o papel de parede THEN o sistema SHALL exibir o novo papel de parede aplicado
4. WHEN há erro no upload do papel de parede THEN o sistema SHALL manter o papel de parede anterior e exibir mensagem de erro