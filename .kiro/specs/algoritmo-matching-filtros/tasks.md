# Implementation Plan

- [x] 1. Criar modelos de dados para matching


  - Criar classes `MatchingResult`, `ScoredProfile`, `MatchScore` e enum `MatchLevel`
  - Implementar métodos `toJson()` e `fromJson()` para serialização
  - Adicionar getters para cores e labels baseados no nível de match
  - _Requirements: 2.4, 3.1, 3.2, 3.3, 3.4_



- [x] 2. Implementar DistanceCalculator


  - Criar classe `DistanceCalculator` com método de cálculo Haversine
  - Implementar `calculateDistance()` que recebe coordenadas lat/lon
  - Implementar `isWithinRadius()` para verificar se está dentro do raio
  - Adicionar constantes para raio da Terra em km


  - _Requirements: 4.1, 4.4_


- [-] 2.1 Escrever testes unitários para DistanceCalculator

  - Testar cálculo com coordenadas conhecidas (ex: São Paulo - Rio de Janeiro)
  - Testar casos extremos (mesma localização, polos, linha do equador)
  - Verificar precisão do cálculo (margem de erro < 1km)

  - _Requirements: 4.1_

- [ ] 3. Implementar ScoreCalculator
  - Criar classe `ScoreCalculator` com constantes de pontos base
  - Implementar `calculateScore()` que retorna `MatchScore` completo

  - Implementar métodos privados para cada critério (idiomas, educação, etc)
  - Implementar normalização de pontuação para escala 0-100
  - Implementar lógica de aplicação de pesos para filtros priorizados



  - Gerar breakdown detalhado mostrando pontos por filtro
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

- [ ] 3.1 Escrever testes unitários para ScoreCalculator
  - Testar pontuação com todos filtros ativos e priorizados
  - Testar pontuação com filtros parciais
  - Verificar normalização correta para 0-100
  - Testar classificação de níveis (excellent, good, moderate, low)
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 4. Implementar QueryBuilder
  - Criar classe `QueryBuilder` para construir queries Firestore
  - Implementar `buildQuery()` que aplica filtros obrigatórios
  - Adicionar filtro de exclusão do próprio usuário
  - Adicionar filtro de perfis completos apenas
  - Implementar filtro de idade (range query)
  - Adicionar limite de 50 perfis por query
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 5. Implementar CacheManager
  - Criar classe `CacheManager` com Map para armazenar resultados
  - Implementar `cacheResult()` para armazenar com timestamp
  - Implementar `getCachedResult()` que verifica expiração (5 minutos)
  - Implementar `invalidate()` para limpar cache
  - Implementar `_generateCacheKey()` baseado em hash dos filtros
  - _Requirements: 8.4, 8.5_

- [ ] 6. Implementar ProfileMatchingService principal
  - Criar classe `ProfileMatchingService` com dependências injetadas
  - Implementar `searchProfiles()` que coordena todo o fluxo
  - Integrar QueryBuilder para buscar perfis no Firestore
  - Aplicar filtragem em memória para altura e distância
  - Calcular pontuação para cada perfil usando ScoreCalculator
  - Ordenar perfis por pontuação decrescente
  - Implementar paginação com `lastDocument`
  - Contar perfis "Excelente Match" (score >= 80)
  - Retornar `MatchingResult` completo
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.5, 6.1, 8.1_

- [ ] 7. Adicionar logging detalhado
  - Registrar início da busca com filtros aplicados
  - Registrar número de perfis retornados pela query
  - Registrar pontuação calculada para cada perfil (debug level)
  - Registrar cache hit/miss
  - Registrar tempo total de execução
  - Registrar erros com contexto completo
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 8. Integrar matching no ExploreProfilesController
  - Adicionar `ProfileMatchingService` como dependência
  - Criar variável reativa `RxList<ScoredProfile> matchedProfiles`
  - Criar variável reativa `Rx<MatchingResult?> currentMatchingResult`
  - Implementar método `searchMatchingProfiles()` que chama o service
  - Implementar método `loadMoreProfiles()` para paginação
  - Chamar busca automaticamente quando filtros mudam
  - Invalidar cache quando `saveSearchFilters()` é chamado
  - Adicionar tratamento de erros com mensagens amigáveis
  - _Requirements: 1.1, 6.4, 8.2, 8.5_

- [ ] 9. Criar componente MatchBadge
  - Criar widget `MatchBadge` que recebe score e level
  - Implementar visual com cor baseada no nível
  - Exibir porcentagem e label (ex: "85% Excelente Match")
  - Adicionar ícone de coração
  - Usar cores: verde (80+), azul (60-79), laranja (40-59), cinza (<40)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 10. Criar componente ProfileMatchCard
  - Criar widget `ProfileMatchCard` que recebe `ScoredProfile`
  - Exibir foto do perfil
  - Exibir `MatchBadge` no topo
  - Exibir nome, idade e informações básicas
  - Exibir distância calculada
  - Adicionar seção expandível com breakdown de pontuação
  - Adicionar ação de tap para ver perfil completo
  - _Requirements: 3.5, 4.5_

- [ ] 11. Criar componente MatchCountHeader
  - Criar widget `MatchCountHeader` que recebe contadores
  - Exibir "X perfis encontrados"
  - Exibir chip destacado com "X excelentes" se houver
  - Usar ícone de estrela para excelentes
  - _Requirements: 6.1, 6.2, 6.5_

- [ ] 12. Criar componente ScoreBreakdown
  - Criar widget `ScoreBreakdown` expansível
  - Listar cada filtro com sua pontuação individual
  - Mostrar ícone indicando se filtro foi atendido
  - Destacar filtros priorizados
  - Exibir total no final
  - _Requirements: 2.3, 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 13. Atualizar ExploreProfilesView com lista de matches
  - Substituir lista placeholder por `ListView.builder` de `ProfileMatchCard`
  - Adicionar `MatchCountHeader` no topo da lista
  - Implementar scroll infinito que chama `loadMoreProfiles()`
  - Adicionar indicador de carregamento durante busca
  - Exibir mensagem quando nenhum perfil é encontrado
  - Adicionar botão "Resetar Filtros" na mensagem vazia
  - _Requirements: 6.2, 6.3, 8.1, 8.2, 8.3_

- [ ] 14. Implementar tratamento de erros
  - Verificar se usuário tem localização configurada antes de buscar
  - Exibir mensagem específica se localização não configurada
  - Implementar retry automático (max 3 tentativas) para erros de rede
  - Implementar timeout de 30 segundos para queries
  - Exibir mensagens de erro amigáveis para o usuário
  - Registrar todos os erros no log com contexto
  - _Requirements: 7.4_

- [ ] 15. Adicionar indicadores visuais de filtros restritivos
  - Quando nenhum perfil é encontrado, analisar quais filtros são muito restritivos
  - Exibir sugestões específicas (ex: "Tente aumentar a distância máxima")
  - Destacar filtros priorizados que podem estar limitando resultados
  - Oferecer ação rápida para ajustar filtro específico
  - _Requirements: 6.3_

- [ ] 16. Implementar atualização automática ao mudar filtros
  - Adicionar listener em `currentFilters` no controller
  - Quando filtros mudam, invalidar cache
  - Executar nova busca automaticamente
  - Resetar paginação (voltar para primeira página)
  - Exibir indicador de "Atualizando resultados..."
  - _Requirements: 6.4, 8.5_

- [ ] 17. Criar testes de integração
  - Testar fluxo completo: configurar filtros → buscar → exibir resultados
  - Testar paginação carregando múltiplas páginas
  - Testar cache: buscar, mudar filtros, voltar aos filtros originais
  - Testar cenário sem resultados
  - Testar cenário com erro de rede
  - _Requirements: 1.1, 8.1, 8.2, 8.4, 8.5_

- [ ] 18. Otimizar performance
  - Criar índices compostos no Firestore para queries
  - Implementar cálculos em paralelo usando `Future.wait()`
  - Adicionar lazy loading de imagens com `cached_network_image`
  - Medir e registrar tempo de execução de cada etapa
  - Otimizar renderização com `const` widgets onde possível
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 19. Adicionar animações e feedback visual
  - Animar entrada dos cards de perfil
  - Adicionar shimmer effect durante carregamento
  - Animar mudança de badge ao recalcular pontuação
  - Adicionar feedback tátil ao tocar em perfil
  - Animar expansão do breakdown de pontuação
  - _Requirements: 3.5_

- [ ] 20. Criar documentação para desenvolvedores
  - Documentar algoritmo de pontuação com exemplos
  - Criar diagrama de fluxo do matching
  - Documentar como adicionar novos critérios de matching
  - Criar guia de troubleshooting para problemas comuns
  - Documentar índices necessários no Firestore
  - _Requirements: 7.1, 7.2, 7.3_
