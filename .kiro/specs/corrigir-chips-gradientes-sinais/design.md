# Design Document

## Overview

O problema relatado é que os gradientes implementados nos chips de valores (Educação, Idiomas, etc.) não estão aparecendo nem no Chrome (Flutter Web) nem no APK compilado. A investigação revelou que:

1. Os gradientes **JÁ ESTÃO IMPLEMENTADOS** no arquivo correto (`value_highlight_chips.dart`)
2. O `ProfileRecommendationCard` **JÁ USA** o `ValueHighlightChips`
3. O problema é causado por **cache do Flutter Web** e possivelmente **build incompleto**

## Architecture

### Fluxo de Renderização Atual

```
sinais_view.dart
  └─> ProfileRecommendationCard
       └─> ValueHighlightChips (COM GRADIENTES)
            ├─> _buildPurpose() - Gradiente azul/roxo
            ├─> _buildSpiritualValues() - Gradientes por cor
            ├─> _buildPersonalInfo() - Gradientes por cor
            └─> _buildCommonInterests() - Gradiente roxo
```

### Problema Identificado

O Flutter Web tem uma limitação conhecida onde `hot reload` na verdade faz `hot restart`, o que pode não aplicar mudanças visuais corretamente. Além disso, o navegador pode estar cacheando a versão antiga do código compilado.

## Components and Interfaces

### 1. ValueHighlightChips (JÁ IMPLEMENTADO)

**Localização:** `lib/components/value_highlight_chips.dart`

**Status:** ✅ Gradientes já implementados corretamente

**Gradientes Existentes:**
- Propósito: Azul (#4169E1) → Roxo (#6A5ACD)
- Certificação: Âmbar (dourado)
- Deus é Pai: Índigo
- Virgindade: Rosa
- Educação: Azul
- Idiomas: Teal
- Filhos: Laranja
- Bebidas: Roxo
- Fumo: Marrom
- Hobbies: Roxo profundo

### 2. ProfileRecommendationCard (JÁ INTEGRADO)

**Localização:** `lib/components/profile_recommendation_card.dart`

**Linha 217:** Usa `ValueHighlightChips(profile: widget.profile)`

**Status:** ✅ Integração correta

### 3. SinaisView (JÁ RENDERIZANDO)

**Localização:** `lib/views/sinais_view.dart`

**Linha 258:** Renderiza `ProfileRecommendationCard`

**Status:** ✅ Renderização correta

## Data Models

Não há mudanças necessárias nos modelos de dados. O `ScoredProfile` já fornece todos os dados necessários para os chips.

## Error Handling

### Cenários de Erro

1. **Cache do Navegador**
   - Sintoma: Mudanças não aparecem no Chrome
   - Solução: Ctrl+Shift+R ou limpar cache manualmente

2. **Build Incompleto**
   - Sintoma: APK não mostra gradientes
   - Solução: `flutter clean` + rebuild completo

3. **Hot Reload Não Funciona**
   - Sintoma: Hot reload não aplica mudanças visuais
   - Solução: Hot restart (Ctrl+Shift+F5) ou rebuild completo

## Testing Strategy

### Checklist de Verificação

1. **Verificação de Código**
   - ✅ Confirmar que `value_highlight_chips.dart` tem gradientes
   - ✅ Confirmar que `ProfileRecommendationCard` usa `ValueHighlightChips`
   - ✅ Confirmar que `sinais_view.dart` renderiza o card

2. **Teste em Flutter Web**
   - Fazer `flutter clean`
   - Fazer `flutter run -d chrome`
   - Abrir DevTools e desabilitar cache
   - Verificar visualmente os gradientes

3. **Teste em APK**
   - Fazer `flutter clean`
   - Fazer `flutter build apk --release`
   - Instalar APK em dispositivo físico
   - Verificar visualmente os gradientes

4. **Teste de Cache**
   - Abrir Chrome DevTools (F12)
   - Ir em Network tab
   - Marcar "Disable cache"
   - Fazer hard refresh (Ctrl+Shift+R)

## Solution Design

### Opção A: Rebuild Completo (RECOMENDADO)

```bash
# 1. Limpar build anterior
flutter clean

# 2. Obter dependências
flutter pub get

# 3. Para Web
flutter run -d chrome --web-renderer html

# 4. Para APK
flutter build apk --release
```

### Opção B: Forçar Atualização no Chrome

1. Abrir DevTools (F12)
2. Clicar com botão direito no ícone de refresh
3. Selecionar "Empty Cache and Hard Reload"
4. Ou usar Ctrl+Shift+R

### Opção C: Adicionar Key Única (Se necessário)

Se o problema persistir, podemos adicionar uma `Key` única ao `ValueHighlightChips` para forçar rebuild:

```dart
ValueHighlightChips(
  key: ValueKey('chips_${widget.profile.userId}'),
  profile: widget.profile,
)
```

## Design Decisions

### Decisão 1: Não Modificar Código Existente

**Rationale:** O código já está correto. O problema é de cache/build, não de implementação.

### Decisão 2: Priorizar Flutter Clean

**Rationale:** `flutter clean` remove todos os artifacts de build e força recompilação completa, garantindo que mudanças sejam aplicadas.

### Decisão 3: Documentar Processo

**Rationale:** Este é um problema comum no Flutter Web. Documentar ajuda a evitar confusão futura.

## Visual Reference

### Antes (Chips Cinzas - Cache Antigo)
```
┌─────────────────────────────┐
│ 🎓 Educação                 │
│    Ensino Superior          │
│    [Fundo cinza simples]    │
└─────────────────────────────┘
```

### Depois (Chips com Gradiente - Código Atual)
```
┌─────────────────────────────┐
│ 🎓 Educação                 │
│    Ensino Superior          │
│    [Gradiente azul suave]   │
│    [Ícone com sombra]       │
└─────────────────────────────┘
```

## Implementation Notes

- O código dos gradientes está em `value_highlight_chips.dart` linhas 138-450
- Cada chip usa `_buildValueChip()` que aplica gradientes condicionalmente
- Chips destacados (`isHighlighted: true`) têm gradientes mais intensos
- Chips normais têm gradientes sutis em cinza claro
