# Requirements Document

## Introduction

Esta spec define a reorganização dos elementos de interface do usuário no chat principal, movendo o menu de 3 pontos da capa para a página da comunidade e preparando o espaço para um futuro ícone de notificações.

## Requirements

### Requirement 1

**User Story:** Como usuário, quero que o menu de configurações (3 pontos) seja movido da capa do chat para a página da comunidade, para que a interface da capa fique mais limpa e organizada.

#### Acceptance Criteria

1. WHEN o usuário visualiza a capa do chat principal THEN o ícone de 3 pontos NÃO deve estar visível
2. WHEN o usuário acessa a página "Comunidade" THEN deve ver um ícone de engrenagem na parte superior da página
3. WHEN o usuário clica no ícone de engrenagem THEN deve abrir o mesmo menu que antes estava nos 3 pontos
4. WHEN o usuário visualiza a página "Comunidade" THEN o ícone de engrenagem deve estar posicionado acima da barra "Nossa Comunidade"

### Requirement 2

**User Story:** Como usuário, quero ter um botão "Sair" facilmente acessível na página da comunidade, para que eu possa fazer logout de forma rápida.

#### Acceptance Criteria

1. WHEN o usuário acessa a página "Comunidade" THEN deve ver um botão "Sair" na parte inferior da página
2. WHEN o usuário clica no botão "Sair" THEN deve ser deslogado do aplicativo
3. WHEN o usuário clica no botão "Sair" THEN deve ser redirecionado para a tela de login
4. WHEN o usuário visualiza o botão "Sair" THEN deve ter um design claro e visível

### Requirement 3

**User Story:** Como desenvolvedor, quero preparar o espaço na capa onde estava o menu de 3 pontos, para que futuramente possa ser implementado um ícone de notificações.

#### Acceptance Criteria

1. WHEN o ícone de 3 pontos for removido da capa THEN o espaço deve ficar disponível para futuros elementos
2. WHEN a remoção for implementada THEN a estrutura do código deve permitir fácil adição de novos ícones
3. WHEN a interface for reorganizada THEN não deve haver elementos quebrados ou mal posicionados
4. WHEN o layout for atualizado THEN deve manter a responsividade em diferentes tamanhos de tela