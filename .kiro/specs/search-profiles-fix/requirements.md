# Requirements Document - Correção Sistema de Busca de Perfis

## Introduction

O sistema de busca de perfis está falhando devido a erros de índices compostos do Firebase. O Firebase está exigindo índices específicos para queries que combinam `displayName` com filtros booleanos (`hasCompletedSinaisCourse`, `isActive`, `isVerified`). Esta funcionalidade é crítica para a experiência do usuário na exploração de perfis.

## Requirements

### Requirement 1

**User Story:** Como usuário do app, eu quero buscar perfis por nome sem erros de índice, para que eu possa encontrar pessoas específicas rapidamente.

#### Acceptance Criteria

1. WHEN o usuário digita um nome na busca THEN o sistema SHALL retornar resultados sem erros de índice Firebase
2. WHEN a busca é executada THEN o sistema SHALL usar uma estratégia que não dependa de índices compostos complexos
3. WHEN não há resultados THEN o sistema SHALL mostrar uma mensagem apropriada em vez de erro
4. WHEN a busca é bem-sucedida THEN os resultados SHALL ser exibidos em menos de 3 segundos

### Requirement 2

**User Story:** Como usuário, eu quero que a busca funcione mesmo sem índices Firebase específicos, para que o sistema seja robusto e independente.

#### Acceptance Criteria

1. WHEN o Firebase não tem índices compostos THEN o sistema SHALL usar busca simples + filtros no código Dart
2. WHEN há múltiplos filtros ativos THEN o sistema SHALL aplicar filtros sequencialmente no código
3. WHEN a query é complexa THEN o sistema SHALL dividir em queries simples e combinar resultados
4. WHEN há erro de índice THEN o sistema SHALL automaticamente usar estratégia alternativa

### Requirement 3

**User Story:** Como desenvolvedor, eu quero uma solução de busca que seja performática e escalável, para que o sistema funcione bem com muitos usuários.

#### Acceptance Criteria

1. WHEN há muitos perfis THEN o sistema SHALL limitar resultados para manter performance
2. WHEN a busca é executada THEN o sistema SHALL usar cache quando apropriado
3. WHEN há filtros múltiplos THEN o sistema SHALL otimizar a ordem de aplicação dos filtros
4. WHEN a busca falha THEN o sistema SHALL ter fallback para busca básica

### Requirement 4

**User Story:** Como usuário, eu quero que a busca seja intuitiva e responsiva, para que eu tenha uma boa experiência de uso.

#### Acceptance Criteria

1. WHEN o usuário digita THEN o sistema SHALL mostrar indicador de carregamento
2. WHEN a busca demora THEN o sistema SHALL mostrar progresso ou timeout apropriado
3. WHEN há resultados THEN o sistema SHALL destacar termos de busca nos resultados
4. WHEN não há resultados THEN o sistema SHALL sugerir buscas alternativas