# Design Document

## Overview

O problema identificado é que o chat "Nosso Propósito" está carregando stories do contexto "principal" em vez do contexto "nosso_proposito". Isso acontece porque o sistema de carregamento de stories não está configurado corretamente para detectar e usar o contexto específico da tela.

## Architecture

### Current Problem
```
Chat Nosso Propósito → Carrega contexto "principal" → stories_files (ERRADO)
```

### Desired Solution
```
Chat Nosso Propósito → Carrega contexto "nosso_proposito" → stories_nosso_proposito (CORRETO)
```

## Components and Interfaces

### 1. NossoPropositoView
**Responsabilidade:** Detectar e passar o contexto correto para o sistema de stories

**Modificações Necessárias:**
- Configurar contexto 'nosso_proposito' para carregamento de stories
- Garantir que a logo use o contexto correto
- Implementar detecção de stories não vistos para o contexto específico

### 2. StoriesRepository
**Responsabilidade:** Carregar stories da coleção correta baseada no contexto

**Funcionalidades Existentes (OK):**
- `getAllByContext('nosso_proposito')` → stories_nosso_proposito
- `getStoriesByContexto('nosso_proposito')` → stories_nosso_proposito
- Mapeamento contexto → coleção já implementado

### 3. Context Validation System
**Responsabilidade:** Validar e normalizar contextos

**Problema Identificado:**
- Sistema está normalizando 'nosso_proposito' para 'principal'
- Precisa reconhecer 'nosso_proposito' como contexto válido

### 4. Story Favorites System
**Responsabilidade:** Gerenciar favoritos por contexto

**Modificações Necessárias:**
- Reconhecer 'nosso_proposito' como contexto válido
- Carregar favoritos específicos do contexto
- Mostrar título correto na tela de favoritos

## Data Models

### Story Loading Flow
```dart
// Contexto atual
String contexto = 'nosso_proposito';

// Carregamento de stories
Stream<List<StorieFileModel>> stories = StoriesRepository.getAllByContext(contexto);

// Detecção de não vistos
List<StorieFileModel> naoVistos = stories.where((story) => !vistosIds.contains(story.id));

// Indicador visual
bool mostrarIndicador = naoVistos.isNotEmpty;
```

### Context Mapping
```dart
Map<String, String> contextToCollection = {
  'principal': 'stories_files',
  'sinais_isaque': 'stories_sinais_isaque', 
  'sinais_rebeca': 'stories_sinais_rebeca',
  'nosso_proposito': 'stories_nosso_proposito', // ADICIONAR
};
```

## Error Handling

### Context Validation
- Se contexto 'nosso_proposito' não for reconhecido → Adicionar à lista de contextos válidos
- Se coleção não existir → Criar automaticamente
- Se não há stories → Mostrar estado vazio apropriado

### Fallback Strategy
- Se erro no carregamento → Mostrar mensagem de erro
- Se contexto inválido → Usar contexto padrão com log de warning
- Se coleção vazia → Mostrar logo sem indicador

## Testing Strategy

### Unit Tests
- Teste de carregamento por contexto
- Teste de mapeamento contexto → coleção
- Teste de validação de contexto
- Teste de detecção de stories não vistos

### Integration Tests
- Teste de fluxo completo: publicação → visualização
- Teste de isolamento entre contextos
- Teste de sistema de favoritos por contexto
- Teste de indicadores visuais

### Manual Tests
- Publicar story para 'nosso_proposito'
- Verificar se aparece no chat correto
- Testar favoritos específicos do contexto
- Verificar indicadores visuais

## Implementation Plan

### Phase 1: Context Detection
1. Modificar NossoPropositoView para usar contexto 'nosso_proposito'
2. Atualizar sistema de validação de contexto
3. Corrigir carregamento de stories na logo

### Phase 2: Story Loading
1. Implementar carregamento correto por contexto
2. Corrigir detecção de stories não vistos
3. Atualizar indicadores visuais

### Phase 3: Favorites Integration
1. Corrigir sistema de favoritos para contexto 'nosso_proposito'
2. Atualizar títulos e navegação
3. Testar integração completa

### Phase 4: Validation & Testing
1. Testes de isolamento entre contextos
2. Validação de fluxo completo
3. Correção de bugs identificados