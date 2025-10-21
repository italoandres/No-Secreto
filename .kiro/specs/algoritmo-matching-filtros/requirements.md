# Requirements Document

## Introduction

Este documento define os requisitos para implementar um algoritmo de matching inteligente que utiliza os 8 filtros de busca configurados pelo usuário (Distância, Idade, Altura, Idiomas, Educação, Filhos, Beber, Fumar) para encontrar e classificar perfis compatíveis. O sistema deve calcular uma pontuação de compatibilidade baseada nos filtros ativos e suas prioridades, retornando perfis ordenados por relevância.

## Glossary

- **Sistema de Matching**: O componente responsável por buscar e classificar perfis baseado nos filtros do usuário
- **Pontuação de Compatibilidade**: Valor numérico (0-100) que indica o quão compatível um perfil é com os filtros do usuário
- **Filtro Ativo**: Filtro que possui um valor diferente do padrão (ex: idioma selecionado, educação específica)
- **Filtro Priorizado**: Filtro marcado como prioritário pelo usuário, que recebe peso maior no cálculo
- **Perfil Candidato**: Perfil de outro usuário que será avaliado pelo algoritmo de matching
- **Firestore Query**: Consulta ao banco de dados Firestore para buscar perfis
- **Peso do Filtro**: Multiplicador aplicado à pontuação de um filtro quando ele é priorizado
- **Match Score**: Pontuação final calculada para um perfil específico

## Requirements

### Requirement 1

**User Story:** Como usuário, eu quero que o sistema busque perfis que correspondam aos meus filtros configurados, para que eu veja apenas pessoas compatíveis com minhas preferências.

#### Acceptance Criteria

1. WHEN o usuário acessa a aba "Explorar Perfis", THE Sistema de Matching SHALL buscar perfis no Firestore que atendam aos filtros básicos configurados
2. WHILE um Filtro Ativo está configurado, THE Sistema de Matching SHALL aplicar esse filtro na busca de Perfis Candidatos
3. THE Sistema de Matching SHALL excluir da busca perfis que não atendem aos filtros obrigatórios (distância máxima, faixa etária, faixa de altura)
4. THE Sistema de Matching SHALL retornar no máximo 50 Perfis Candidatos por consulta
5. THE Sistema de Matching SHALL excluir o próprio perfil do usuário dos resultados

### Requirement 2

**User Story:** Como usuário, eu quero que perfis que correspondem aos meus filtros priorizados apareçam primeiro, para que eu veja as pessoas mais compatíveis no topo da lista.

#### Acceptance Criteria

1. WHEN um perfil atende a um Filtro Priorizado, THE Sistema de Matching SHALL aplicar um Peso do Filtro de 2.0 à pontuação desse critério
2. WHEN um perfil atende a um Filtro Ativo não priorizado, THE Sistema de Matching SHALL aplicar um Peso do Filtro de 1.0 à pontuação desse critério
3. THE Sistema de Matching SHALL calcular a Pontuação de Compatibilidade somando as pontuações de todos os filtros ativos
4. THE Sistema de Matching SHALL normalizar a Pontuação de Compatibilidade para uma escala de 0 a 100
5. THE Sistema de Matching SHALL ordenar os Perfis Candidatos em ordem decrescente de Match Score

### Requirement 3

**User Story:** Como usuário, eu quero ver uma indicação visual da compatibilidade de cada perfil, para que eu saiba rapidamente quão bem alguém corresponde às minhas preferências.

#### Acceptance Criteria

1. WHEN a Pontuação de Compatibilidade é maior ou igual a 80, THE Sistema de Matching SHALL classificar o perfil como "Excelente Match" com cor verde
2. WHEN a Pontuação de Compatibilidade está entre 60 e 79, THE Sistema de Matching SHALL classificar o perfil como "Bom Match" com cor azul
3. WHEN a Pontuação de Compatibilidade está entre 40 e 59, THE Sistema de Matching SHALL classificar o perfil como "Match Moderado" com cor laranja
4. WHEN a Pontuação de Compatibilidade é menor que 40, THE Sistema de Matching SHALL classificar o perfil como "Match Baixo" com cor cinza
5. THE Sistema de Matching SHALL exibir a porcentagem de compatibilidade e o badge colorido em cada card de perfil

### Requirement 4

**User Story:** Como usuário, eu quero que o sistema calcule a distância real entre minha localização e a do perfil, para que eu veja apenas pessoas dentro do raio configurado.

#### Acceptance Criteria

1. WHEN o filtro de distância está ativo, THE Sistema de Matching SHALL calcular a distância em quilômetros usando a fórmula de Haversine
2. THE Sistema de Matching SHALL usar a localização primária do usuário como ponto de referência
3. IF a localização primária não está disponível, THEN THE Sistema de Matching SHALL usar a primeira localização adicional configurada
4. THE Sistema de Matching SHALL excluir perfis cuja distância calculada excede o valor de maxDistance configurado
5. THE Sistema de Matching SHALL exibir a distância calculada em cada card de perfil

### Requirement 5

**User Story:** Como usuário, eu quero que o sistema avalie múltiplos critérios de forma inteligente, para que perfis que atendem a mais filtros tenham pontuação maior.

#### Acceptance Criteria

1. WHEN o filtro de idiomas está ativo, THE Sistema de Matching SHALL adicionar 15 pontos para cada idioma em comum entre usuário e Perfil Candidato
2. WHEN o filtro de educação está ativo e há correspondência exata, THE Sistema de Matching SHALL adicionar 20 pontos à Pontuação de Compatibilidade
3. WHEN o filtro de filhos está ativo e há correspondência, THE Sistema de Matching SHALL adicionar 15 pontos à Pontuação de Compatibilidade
4. WHEN o filtro de beber está ativo e há correspondência, THE Sistema de Matching SHALL adicionar 10 pontos à Pontuação de Compatibilidade
5. WHEN o filtro de fumar está ativo e há correspondência, THE Sistema de Matching SHALL adicionar 10 pontos à Pontuação de Compatibilidade
6. WHEN o perfil está dentro da faixa de idade configurada, THE Sistema de Matching SHALL adicionar 10 pontos à Pontuação de Compatibilidade
7. WHEN o perfil está dentro da faixa de altura configurada, THE Sistema de Matching SHALL adicionar 10 pontos à Pontuação de Compatibilidade
8. WHEN o perfil está dentro da distância configurada, THE Sistema de Matching SHALL adicionar 10 pontos à Pontuação de Compatibilidade

### Requirement 6

**User Story:** Como usuário, eu quero que o sistema mostre quantos perfis correspondem aos meus filtros, para que eu saiba se preciso ajustar minhas preferências.

#### Acceptance Criteria

1. THE Sistema de Matching SHALL contar o número total de Perfis Candidatos encontrados
2. THE Sistema de Matching SHALL exibir o contador na parte superior da lista de perfis
3. WHEN nenhum perfil é encontrado, THE Sistema de Matching SHALL exibir uma mensagem sugerindo ajustar os filtros
4. THE Sistema de Matching SHALL atualizar o contador automaticamente quando os filtros são modificados
5. THE Sistema de Matching SHALL exibir separadamente quantos perfis são "Excelente Match" (80+)

### Requirement 7

**User Story:** Como desenvolvedor, eu quero que o sistema registre logs detalhados do processo de matching, para que eu possa debugar problemas e otimizar o algoritmo.

#### Acceptance Criteria

1. THE Sistema de Matching SHALL registrar no log o início de cada busca com os filtros aplicados
2. THE Sistema de Matching SHALL registrar no log o número de perfis retornados pela Firestore Query
3. THE Sistema de Matching SHALL registrar no log a Pontuação de Compatibilidade calculada para cada perfil
4. WHEN ocorre um erro durante o matching, THE Sistema de Matching SHALL registrar no log o erro com contexto completo
5. THE Sistema de Matching SHALL registrar no log o tempo total de execução do algoritmo

### Requirement 8

**User Story:** Como usuário, eu quero que o sistema carregue os perfis de forma eficiente, para que eu não precise esperar muito tempo para ver os resultados.

#### Acceptance Criteria

1. THE Sistema de Matching SHALL implementar paginação com limite de 20 perfis por página
2. THE Sistema de Matching SHALL carregar a próxima página automaticamente quando o usuário rola até o final da lista
3. THE Sistema de Matching SHALL exibir um indicador de carregamento durante a busca
4. THE Sistema de Matching SHALL cachear os resultados por 5 minutos para evitar consultas repetidas
5. WHEN os filtros são alterados, THE Sistema de Matching SHALL invalidar o cache e buscar novos resultados
