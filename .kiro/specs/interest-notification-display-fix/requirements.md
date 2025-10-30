# Requirements Document - Correção Exibição de Notificações de Interesse

## Introduction

O sistema está criando e salvando notificações de interesse (curtidas) corretamente no Firebase, mas elas não estão sendo exibidas na interface do usuário. O problema está no filtro que processa as notificações recebidas, que está excluindo as notificações de tipo "interest" com status "pending".

## Requirements

### Requirement 1: Exibir Notificações de Interesse Simples

**User Story:** Como usuário que recebe uma curtida de interesse, eu quero ver a notificação na minha lista de notificações, para que eu possa saber quem demonstrou interesse em mim.

#### Acceptance Criteria

1. WHEN uma notificação de tipo "interest" com status "pending" existe no Firebase THEN o sistema SHALL exibir essa notificação na lista de notificações recebidas
2. WHEN o usuário abre a tela de notificações THEN o sistema SHALL carregar todas as notificações com type "interest" e status "pending" ou "viewed"
3. WHEN uma notificação de interesse é criada THEN ela SHALL aparecer imediatamente na interface do receptor sem necessidade de recarregar o app

### Requirement 2: Corrigir Filtro de Notificações

**User Story:** Como desenvolvedor, eu quero que o filtro de notificações processe corretamente todos os tipos de notificações, para que nenhuma notificação válida seja excluída.

#### Acceptance Criteria

1. WHEN o sistema busca notificações recebidas THEN ele SHALL incluir notificações com type "interest", "acceptance" e "mutual_match"
2. WHEN o sistema filtra notificações THEN ele SHALL considerar status "pending", "viewed" e "new" como válidos
3. WHEN o log mostra "Notificações filtradas (pending/viewed): 0" THEN isso SHALL indicar um problema no filtro que precisa ser corrigido

### Requirement 3: Sincronização em Tempo Real

**User Story:** Como usuário, eu quero que as notificações apareçam em tempo real quando alguém demonstra interesse, para que eu possa responder rapidamente.

#### Acceptance Criteria

1. WHEN uma notificação é criada no Firebase THEN o stream SHALL detectar a mudança e atualizar a UI automaticamente
2. WHEN o usuário está na tela de notificações THEN novas notificações SHALL aparecer sem necessidade de pull-to-refresh
3. WHEN o sistema detecta uma nova notificação THEN ela SHALL ser adicionada ao topo da lista

### Requirement 4: Debug e Diagnóstico

**User Story:** Como desenvolvedor, eu quero logs claros do processo de filtragem, para que eu possa identificar rapidamente onde as notificações estão sendo perdidas.

#### Acceptance Criteria

1. WHEN o sistema busca notificações THEN ele SHALL logar o total encontrado no Firebase
2. WHEN o sistema aplica filtros THEN ele SHALL logar quantas notificações passaram por cada filtro
3. WHEN notificações são excluídas THEN o sistema SHALL logar o motivo da exclusão (tipo inválido, status inválido, etc)
4. WHEN o processamento termina THEN o log SHALL mostrar claramente quantas notificações foram exibidas vs quantas foram filtradas
