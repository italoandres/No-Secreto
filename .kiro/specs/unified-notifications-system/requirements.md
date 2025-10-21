# Requirements Document - Sistema Unificado de Notificações

## Introduction

Este documento define os requisitos para criar um sistema unificado de notificações que organize todas as notificações do app em **3 categorias horizontais**: Stories (Sinais), Interesse/Match e Sistema (incluindo Certificação Espiritual). O objetivo é facilitar a navegação e evitar mistura de contextos diferentes, mantendo as versões atuais do Firebase (sem atualização).

## Categorias do Sistema

1. **📖 Stories** - Notificações de interações com stories (Sinais de Rebeca, Sinais de Isaque, Nosso Propósito)
2. **💕 Interesse/Match** - Demonstrações de interesse, matches mútuos e chats
3. **⚙️ Sistema** - Certificação espiritual, atualizações do app e avisos administrativos

## Requirements

### Requirement 1: Tela Principal de Notificações Unificada

**User Story:** Como usuário, eu quero ver todas as minhas notificações organizadas por categoria em uma única tela, para que eu possa navegar facilmente entre diferentes tipos de notificações.

#### Acceptance Criteria

1. WHEN o usuário abre a tela de notificações THEN o sistema SHALL exibir categorias horizontais em formato de abas ou cards
2. WHEN o usuário visualiza as categorias THEN o sistema SHALL mostrar badges com contadores de notificações não lidas em cada categoria
3. WHEN o usuário toca em uma categoria THEN o sistema SHALL exibir apenas as notificações daquela categoria específica
4. IF uma categoria não tem notificações THEN o sistema SHALL exibir mensagem apropriada de estado vazio
5. WHEN o usuário está em uma categoria THEN o sistema SHALL destacar visualmente a categoria ativa

### Requirement 2: Categoria de Stories (Sinais)

**User Story:** Como usuário, eu quero ver todas as notificações de interações com meus stories (curtidas, comentários, menções, respostas, comentários curtidos) organizadas por contexto (Rebeca, Isaque, Nosso Propósito), para que eu possa acompanhar cada tipo de interação separadamente.

#### Acceptance Criteria

1. WHEN alguém curte meu story THEN o sistema SHALL criar notificação na categoria Stories mostrando quem curtiu
2. WHEN alguém comenta no meu story THEN o sistema SHALL criar notificação na categoria Stories com preview do comentário
3. WHEN alguém me menciona com @ em um comentário THEN o sistema SHALL criar notificação destacada na categoria Stories
4. WHEN alguém responde meu comentário THEN o sistema SHALL criar notificação na categoria Stories mostrando a resposta
5. WHEN alguém curte meu comentário THEN o sistema SHALL criar notificação na categoria Stories
6. WHEN há notificações de stories THEN o sistema SHALL agrupar por contexto (Rebeca, Isaque, Nosso Propósito) com ícones e cores específicas
7. WHEN o usuário toca em uma notificação de story THEN o sistema SHALL navegar para o story correspondente
8. IF o usuário tem notificações em múltiplos contextos THEN o sistema SHALL mostrar contador total e por contexto
9. WHEN o usuário marca notificações como lidas THEN o sistema SHALL atualizar os contadores em tempo real

### Requirement 3: Categoria de Sistema (incluindo Certificação Espiritual)

**User Story:** Como usuário, eu quero ver notificações do sistema (certificação espiritual, atualizações, avisos) organizadas em uma categoria específica, para que eu possa acompanhar informações administrativas e processos do app.

#### Acceptance Criteria

1. WHEN o usuário recebe aprovação de certificação THEN o sistema SHALL criar notificação na categoria Sistema com ícone de verificado e cor verde
2. WHEN o usuário recebe reprovação de certificação THEN o sistema SHALL criar notificação na categoria Sistema com ícone de informação e cor laranja
3. WHEN o usuário toca em notificação de aprovação THEN o sistema SHALL navegar para o perfil do usuário
4. WHEN o usuário toca em notificação de reprovação THEN o sistema SHALL navegar para tela de solicitação de certificação
5. WHEN há atualização importante do app THEN o sistema SHALL criar notificação de sistema com prioridade alta
6. WHEN há manutenção programada THEN o sistema SHALL notificar com antecedência na categoria Sistema
7. IF a certificação foi aprovada THEN o sistema SHALL exibir mensagem de parabéns e badge especial

### Requirement 4: Categoria de Interesse e Matches

**User Story:** Como usuário, eu quero ver notificações de pessoas que demonstraram interesse em mim e matches mútuos, para que eu possa responder e iniciar conversas.

#### Acceptance Criteria

1. WHEN alguém demonstra interesse THEN o sistema SHALL criar notificação com foto e nome do usuário
2. WHEN há match mútuo THEN o sistema SHALL criar notificação especial com animação ou destaque visual
3. WHEN o usuário toca em notificação de interesse THEN o sistema SHALL permitir aceitar ou rejeitar o interesse
4. WHEN o usuário aceita interesse THEN o sistema SHALL verificar se há match mútuo e criar chat automaticamente
5. IF há múltiplas notificações do mesmo usuário THEN o sistema SHALL agrupar em uma única notificação com contador

### Requirement 5: Organização Visual das 3 Categorias

**User Story:** Como usuário, eu quero ver as 3 categorias de notificações (Stories, Interesse/Match, Sistema) organizadas horizontalmente com ícones distintos, para que eu possa identificar rapidamente cada tipo.

#### Acceptance Criteria

1. WHEN o usuário abre notificações THEN o sistema SHALL exibir 3 categorias horizontais: Stories (📖), Interesse/Match (💕) e Sistema (⚙️)
2. WHEN há notificações em uma categoria THEN o sistema SHALL exibir badge com contador sobre o ícone da categoria
3. WHEN o usuário toca em uma categoria THEN o sistema SHALL destacar visualmente a categoria ativa
4. IF uma categoria está vazia THEN o sistema SHALL exibir mensagem apropriada de estado vazio
5. WHEN o usuário navega entre categorias THEN o sistema SHALL animar a transição suavemente

### Requirement 6: Badges e Contadores Visuais

**User Story:** Como usuário, eu quero ver badges com contadores nos ícones de navegação, para que eu saiba quantas notificações não lidas tenho em cada categoria.

#### Acceptance Criteria

1. WHEN há notificações não lidas THEN o sistema SHALL exibir badge vermelho com número no ícone de notificações
2. WHEN o usuário visualiza notificações THEN o sistema SHALL atualizar contadores em tempo real
3. WHEN há notificações em múltiplas categorias THEN o sistema SHALL mostrar contador total no ícone principal
4. IF o contador excede 99 THEN o sistema SHALL exibir "99+"
5. WHEN todas as notificações são lidas THEN o sistema SHALL remover o badge

### Requirement 7: Navegação Horizontal entre Categorias

**User Story:** Como usuário, eu quero navegar facilmente entre categorias de notificações com gestos ou toques, para que eu possa alternar rapidamente entre diferentes tipos.

#### Acceptance Criteria

1. WHEN o usuário desliza horizontalmente THEN o sistema SHALL trocar para a categoria adjacente
2. WHEN o usuário toca em uma aba de categoria THEN o sistema SHALL animar a transição suavemente
3. WHEN o usuário está em uma categoria THEN o sistema SHALL indicar visualmente a posição atual
4. IF há muitas categorias THEN o sistema SHALL permitir scroll horizontal nas abas
5. WHEN o usuário retorna à tela THEN o sistema SHALL lembrar a última categoria visualizada

### Requirement 8: Integração com Sistema Existente

**User Story:** Como desenvolvedor, eu quero integrar o novo sistema de notificações com os serviços existentes, para que não haja duplicação de código e mantenhamos compatibilidade.

#### Acceptance Criteria

1. WHEN o sistema é inicializado THEN o sistema SHALL usar os repositórios e serviços existentes
2. WHEN há nova notificação THEN o sistema SHALL rotear automaticamente para a categoria correta
3. WHEN o usuário interage com notificação THEN o sistema SHALL usar os handlers existentes
4. IF há erro em um serviço THEN o sistema SHALL usar fallback e recovery systems existentes
5. WHEN o sistema processa notificações THEN o sistema SHALL manter compatibilidade com versões atuais do Firebase

### Requirement 9: Performance e Cache

**User Story:** Como usuário, eu quero que as notificações carreguem rapidamente mesmo offline, para que eu possa visualizar notificações recentes sem conexão.

#### Acceptance Criteria

1. WHEN o app está offline THEN o sistema SHALL exibir notificações do cache local
2. WHEN o app volta online THEN o sistema SHALL sincronizar automaticamente novas notificações
3. WHEN há muitas notificações THEN o sistema SHALL implementar paginação ou lazy loading
4. IF o cache está desatualizado THEN o sistema SHALL atualizar em background
5. WHEN o usuário puxa para atualizar THEN o sistema SHALL forçar sincronização imediata

### Requirement 10: Acessibilidade e UX

**User Story:** Como usuário, eu quero que a interface de notificações seja intuitiva e acessível, para que eu possa usar facilmente independente de minhas habilidades.

#### Acceptance Criteria

1. WHEN o usuário usa leitor de tela THEN o sistema SHALL fornecer descrições apropriadas
2. WHEN há notificações importantes THEN o sistema SHALL usar cores e ícones distintos
3. WHEN o usuário tem dificuldade visual THEN o sistema SHALL suportar tamanhos de fonte maiores
4. IF há muitas notificações THEN o sistema SHALL permitir filtros e busca
5. WHEN o usuário interage THEN o sistema SHALL fornecer feedback visual e tátil apropriado
