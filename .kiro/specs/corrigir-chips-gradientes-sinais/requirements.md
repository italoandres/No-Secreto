# Requirements Document

## Introduction

Este spec documenta a correção dos chips de valores na aba "Seus Sinais" que não estão exibindo os gradientes implementados devido a problemas de cache do Flutter Web.

## Glossary

- **ValueHighlightChips**: Componente que exibe chips com informações do perfil (Educação, Idiomas, etc.)
- **ProfileRecommendationCard**: Card que exibe perfis recomendados na aba "Seus Sinais"
- **Flutter Web Hot Reload**: Mecanismo de atualização de código que no Flutter Web faz "hot restart" ao invés de "hot reload" verdadeiro
- **Cache do Navegador**: Armazenamento temporário de assets e código compilado pelo navegador

## Requirements

### Requirement 1

**User Story:** Como desenvolvedor, quero que os gradientes dos chips sejam exibidos corretamente no Flutter Web, para que a interface fique visualmente atraente

#### Acceptance Criteria

1. WHEN o desenvolvedor compila o app para Web, THE Sistema SHALL exibir os chips com gradientes coloridos
2. WHEN o desenvolvedor faz hot reload no Chrome, THE Sistema SHALL aplicar as mudanças visuais imediatamente
3. WHEN o desenvolvedor gera um APK, THE Sistema SHALL incluir os gradientes nos chips
4. IF o cache do navegador estiver impedindo a atualização, THEN THE Sistema SHALL fornecer instruções para limpar o cache
5. THE Sistema SHALL garantir que os gradientes sejam renderizados tanto em Web quanto em Mobile

### Requirement 2

**User Story:** Como desenvolvedor, quero entender por que os gradientes não aparecem, para que eu possa evitar esse problema no futuro

#### Acceptance Criteria

1. THE Documentação SHALL explicar o comportamento do hot reload no Flutter Web
2. THE Documentação SHALL fornecer comandos para rebuild completo
3. THE Documentação SHALL incluir passos para limpar cache do navegador
4. THE Documentação SHALL explicar a diferença entre hot reload e hot restart
5. THE Documentação SHALL fornecer checklist de verificação visual

### Requirement 3

**User Story:** Como desenvolvedor, quero ter certeza de que os gradientes estão no código correto, para que eles sejam renderizados nos cards da aba "Seus Sinais"

#### Acceptance Criteria

1. THE Sistema SHALL verificar que ValueHighlightChips contém os gradientes
2. THE Sistema SHALL confirmar que ProfileRecommendationCard usa ValueHighlightChips
3. THE Sistema SHALL validar que sinais_view.dart renderiza ProfileRecommendationCard
4. IF os gradientes estiverem em arquivo errado, THEN THE Sistema SHALL movê-los para o local correto
5. THE Sistema SHALL garantir que não há duplicação de código de chips
