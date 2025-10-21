# Implementation Plan - Aba Sinais com Recomendações Semanais

- [x] 1. Criar modelos de dados e estrutura base



  - Criar modelo `WeeklyRecommendation` com serialização Firestore
  - Criar modelo `Interest` para gerenciar interesses
  - Criar modelo `Match` para matches confirmados
  - Adicionar campos necessários em `ScoredProfile` (commonHobbies, matchesVirginityPreference, etc)





  - _Requirements: 1.1, 5.1, 5.2_

- [ ] 2. Implementar WeeklyRecommendationsService
  - [ ] 2.1 Criar serviço base com métodos principais
    - Implementar `getWeeklyRecommendations()` com cache semanal


    - Implementar `_generateRecommendations()` integrando com MatchingAlgorithmService
    - Implementar `needsRefresh()` para verificar renovação semanal
    - Implementar `_getCurrentWeekKey()` e helpers de data
    - _Requirements: 1.1, 1.4_


  - [ ] 2.2 Implementar sistema de interesses
    - Implementar `registerInterest()` para registrar interesse em perfil
    - Implementar `_checkMutualInterest()` para detectar interesse mútuo
    - Implementar `_createMatch()` para criar match quando há mutualidade





    - Implementar `_sendMatchNotifications()` para notificar usuários
    - _Requirements: 3.2, 3.4, 8.2_

  - [ ] 2.3 Implementar gerenciamento de candidatos
    - Implementar `_getCandidateProfiles()` excluindo já visualizados e bloqueados

    - Implementar filtro de perfis já com match
    - Implementar cache de recomendações no Firestore
    - Implementar lógica de renovação automática às segundas-feiras
    - _Requirements: 1.1, 1.3, 1.4_

- [x] 3. Criar componentes visuais do card de perfil

  - [ ] 3.1 Implementar ProfileRecommendationCard
    - Criar estrutura base com layout 50/50 (foto superior, valores inferior)
    - Implementar PhotoSection com carregamento otimizado de imagem
    - Implementar ValuesSection com informações do perfil
    - Adicionar suporte a gestos de swipe (direita/esquerda)
    - _Requirements: 2.1, 2.2, 3.5_


  - [ ] 3.2 Implementar MatchScoreBadge
    - Criar badge visual com percentual de compatibilidade
    - Implementar gradiente de cores baseado no score (verde > 90%, azul > 75%, etc)
    - Adicionar modal de breakdown detalhado ao tocar no badge
    - Criar ScoreBreakdownSheet mostrando pontuação por categoria
    - _Requirements: 7.1, 7.2, 7.3_

  - [ ] 3.3 Implementar ValueHighlightChips
    - Criar chips para certificação espiritual com destaque visual
    - Criar chips para movimento Deus é Pai
    - Criar chips para virgindade com indicador de compatibilidade
    - Criar chips para educação, idiomas e hobbies
    - Implementar destaque visual para valores de alta compatibilidade
    - _Requirements: 2.3, 2.4, 7.4, 7.5_

  - [ ] 3.4 Implementar ActionButtons
    - Criar botão "Tenho Interesse" com ícone de coração
    - Criar botão "Passar" com ícone de X
    - Adicionar animações de feedback ao clicar
    - Implementar confirmação visual de ação registrada
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 4. Implementar ProfileCardStack e navegação
  - Criar stack de cards com animação de transição
  - Implementar lógica de remoção de card ao swipe/ação
  - Adicionar contador de perfis restantes
  - Implementar animação de "fim de recomendações"





  - Adicionar pull-to-refresh para recarregar (se disponível)
  - _Requirements: 1.2, 3.3, 9.2, 9.3_

- [ ] 5. Criar view expandida de perfil
  - [x] 5.1 Implementar ExpandedProfileView

    - Criar modal/sheet com informações completas do perfil
    - Implementar galeria de fotos com navegação horizontal
    - Exibir biografia completa e valores detalhados
    - Mostrar localização e distância
    - Manter botões de ação visíveis
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_


  - [ ] 5.2 Adicionar animações de transição
    - Implementar Hero animation da foto principal
    - Adicionar slide animation para abrir/fechar
    - Implementar page view para galeria de fotos
    - _Requirements: 9.2_

- [ ] 6. Implementar SinaisView com tabs
  - [ ] 6.1 Criar estrutura principal com TabBar
    - Criar SinaisView com 3 tabs (Recomendações, Interesses, Matches)
    - Implementar RecommendationsTab com ProfileCardStack



    - Criar InterestsTab para listar interesses pendentes
    - Criar MatchesTab para listar matches confirmados
    - _Requirements: 5.1, 5.2_

  - [ ] 6.2 Implementar InterestsTab
    - Criar lista de perfis onde usuário demonstrou interesse
    - Exibir status "Aguardando resposta" em cada card
    - Implementar ordenação por data (mais recente primeiro)
    - Adicionar opção de cancelar interesse
    - _Requirements: 5.1, 5.5_

  - [ ] 6.3 Implementar MatchesTab
    - Criar lista de matches confirmados
    - Exibir animação celebratória ao criar novo match
    - Adicionar botão "Enviar mensagem" em cada match
    - Implementar ordenação por data de match
    - _Requirements: 5.2, 5.3, 5.4_

- [ ] 7. Criar SinaisController
  - Implementar state management com GetX
  - Criar variáveis observáveis (recommendations, interests, matches)
  - Implementar `loadWeeklyRecommendations()`
  - Implementar `handleInterest()` e `handlePass()`
  - Implementar `loadInterests()` e `loadMatches()`
  - Adicionar loading states e error handling
  - _Requirements: 1.1, 3.2, 3.3, 5.1, 5.2_

- [ ] 8. Implementar EmptyStateView
  - [ ] 8.1 Criar view para quando não há recomendações
    - Exibir mensagem explicativa amigável
    - Mostrar ilustração/ícone apropriado
    - Listar sugestões de ação (completar perfil, ajustar filtros, etc)
    - _Requirements: 6.1, 6.2_

  - [ ] 8.2 Adicionar botões de ação
    - Criar botão "Completar Perfil" (se perfil incompleto)
    - Criar botão "Ajustar Filtros" (se filtros muito restritivos)
    - Criar botão "Expandir Localização"
    - Exibir estatísticas de compatibilidade
    - _Requirements: 6.3, 6.4, 6.5_

- [ ] 9. Implementar sistema de notificações
  - Criar serviço de notificações para aba Sinais
  - Implementar notificação de novas recomendações semanais
  - Implementar notificação de novo match
  - Implementar notificação de novo interesse recebido
  - Adicionar agrupamento de notificações
  - Respeitar configurações de notificação do usuário
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 10. Otimizar performance e carregamento
  - [ ] 10.1 Implementar carregamento otimizado de imagens
    - Usar cached_network_image com placeholder
    - Implementar carregamento progressivo (baixa → alta qualidade)
    - Lazy load de galeria completa
    - Adicionar cache de imagens
    - _Requirements: 9.1_

  - [ ] 10.2 Otimizar cálculo de scores
    - Implementar cache de scores calculados (24h)
    - Adicionar cálculo assíncrono em background
    - Implementar batch processing para múltiplos perfis
    - _Requirements: 1.1_

  - [ ] 10.3 Implementar modo offline
    - Adicionar suporte offline para perfis já carregados
    - Criar queue local para ações (interesse/passar)
    - Implementar sincronização ao reconectar
    - Adicionar feedback visual de "offline"
    - _Requirements: 9.4_

- [ ] 11. Implementar animações e transições
  - Adicionar AnimatedSwitcher para transição entre cards
  - Implementar animação de swipe com feedback visual
  - Criar animação de "match" celebratória
  - Adicionar micro-interações nos botões
  - Garantir 60 FPS com RepaintBoundary
  - _Requirements: 9.2, 9.3_

- [ ] 12. Configurar Firestore rules e segurança
  - Criar rules para coleção `weeklyRecommendations`
  - Criar rules para coleção `interests`
  - Criar rules para coleção `matches`
  - Implementar rate limiting (max 10 interesses/dia)
  - Adicionar validações de perfil completo
  - _Requirements: 1.1, 3.2, 5.2_

- [ ] 13. Implementar analytics e métricas
  - Registrar taxa de interesse (interesse vs passar)
  - Registrar tempo médio de visualização por perfil
  - Registrar taxa de conversão (interesse → match → conversa)
  - Registrar quais valores recebem mais atenção
  - Criar relatório semanal de performance
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 14. Criar testes
  - [ ]* 14.1 Criar unit tests para WeeklyRecommendationsService
    - Testar geração de 6 recomendações
    - Testar renovação semanal
    - Testar criação de match em interesse mútuo
    - Testar exclusão de perfis já visualizados
    - _Requirements: 1.1, 1.4, 3.4_

  - [ ]* 14.2 Criar integration tests para fluxo completo
    - Testar abertura da aba Sinais
    - Testar swipe e ações nos cards
    - Testar demonstração de interesse
    - Testar criação de match
    - Testar navegação entre tabs
    - _Requirements: 1.1, 3.2, 3.3, 5.1, 5.2_

- [ ] 15. Integrar com sistema existente
  - Adicionar aba Sinais na navegação principal (HomeView)
  - Integrar com sistema de notificações existente
  - Conectar matches com sistema de chat
  - Adicionar badge de notificação na aba Sinais
  - Testar fluxo completo end-to-end
  - _Requirements: 1.1, 5.3, 8.2_
