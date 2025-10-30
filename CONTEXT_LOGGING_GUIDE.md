# 📋 Guia do Sistema de Logs de Contexto

## 🎯 **Visão Geral**

O sistema de logs de contexto foi implementado para monitorar e debuggar o isolamento entre contextos de stories. Este guia explica como usar e interpretar os logs.

## 🔧 **Configuração**

### Flags de Debug (lib/utils/context_debug.dart)

```dart
class ContextDebug {
  static const bool ENABLE_CONTEXT_LOGS = true;        // Habilitar logs gerais
  static const bool VALIDATE_CONTEXT_STRICT = true;    // Validação rigorosa
  static const bool FILTER_INVALID_CONTEXTS = true;    // Filtrar contextos inválidos
  static const bool DETECT_CONTEXT_LEAKS = true;       // Detectar vazamentos
  static const bool LOG_QUERY_PERFORMANCE = true;      // Logs de performance
}
```

## 📊 **Tipos de Logs**

### 1. **Logs de Carregamento** (`📥 CONTEXT_LOAD`)
```
📥 CONTEXT_LOAD: getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Coleção: "stories_sinais_rebeca"
   - Stories carregados: 3
```

### 2. **Logs de Filtro** (`🔍 CONTEXT_FILTER`)
```
🔍 CONTEXT_FILTER: getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Stories originais: 5
   - Stories após filtro: 3
   - ⚠️ Stories removidos: 2
```

### 3. **Logs de Validação** (`✅ CONTEXT_VALIDATE`)
```
✅ CONTEXT_VALIDATE: EnhancedStoriesViewer_initState - Contexto "sinais_rebeca" é válido
```

### 4. **Logs de Erro** (`❌ CONTEXT_ERROR`)
```
❌ CONTEXT_ERROR: toggleFavorite - Contexto "contexto_invalido" é inválido
```

### 5. **Logs de Vazamento** (`🚨 CONTEXT_LEAK`)
```
🚨 CONTEXT_LEAK: getUserFavoritesStream - Vazamentos detectados para contexto "sinais_rebeca":
   - 2 stories do contexto "principal"
   - 1 stories do contexto "sinais_isaque"
```

### 6. **Logs de Performance** (`⚡ CONTEXT_PERF`)
```
⚡ CONTEXT_PERF: getAllSinaisRebeca_query
   - Contexto: "sinais_rebeca"
   - Duração: 245ms
   - Resultados: 3
```

## 🔍 **Como Interpretar os Logs**

### ✅ **Logs Normais (Tudo OK)**
```
📥 CONTEXT_LOAD: getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Coleção: "stories_sinais_rebeca"
   - Stories carregados: 3

🔍 CONTEXT_FILTER: getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Stories originais: 3
   - Stories após filtro: 3
```

### 🚨 **Logs de Problema (Vazamento Detectado)**
```
📥 CONTEXT_LOAD: getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Coleção: "stories_sinais_rebeca"
   - Stories carregados: 5

🔍 CONTEXT_FILTER: getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Stories originais: 5
   - Stories após filtro: 3
   - ⚠️ Stories removidos: 2

🚨 CONTEXT_LEAK: getAllSinaisRebeca - Vazamentos detectados para contexto "sinais_rebeca":
   - 2 stories do contexto "principal"

❌ CONTEXT_ERROR: ERRO CRÍTICO em getAllSinaisRebeca
   - Contexto: "sinais_rebeca"
   - Erro: VAZAMENTO DE CONTEXTO DETECTADO
```

## 🛠️ **Métodos de Debug Disponíveis**

### 1. **Logs Básicos**
```dart
// Log de carregamento
ContextDebug.logLoad(context, collection, count, operation);

// Log de filtro
ContextDebug.logFilter(context, originalCount, filteredCount, operation);

// Log de validação
ContextDebug.logValidation(context, isValid, operation);

// Log de erro crítico
ContextDebug.logCriticalError(operation, error, context);
```

### 2. **Logs Avançados**
```dart
// Log de vazamento
ContextDebug.logLeak(expectedContext, leaks, operation);

// Log de performance
ContextDebug.logPerformance(operation, duration, context, count);

// Log de resumo
ContextDebug.logSummary(operation, context, data);
```

### 3. **Medição de Performance**
```dart
// Executar com medição de performance
final result = ContextDebug.measurePerformance('operation_name', context, () {
  return someExpensiveOperation();
});
```

## 🔧 **Utilitários de Teste**

### Executar Todos os Testes
```dart
import '../utils/context_utils.dart';

// Executar todos os testes das utilidades
ContextUtils.runTests();
```

### Simular Vazamento
```dart
// Simular um cenário de vazamento para testes
ContextUtils.simulateLeak();
```

## 📈 **Monitoramento em Produção**

### Logs Críticos para Monitorar

1. **Vazamentos de Contexto**
   - Procurar por: `🚨 CONTEXT_LEAK`
   - Ação: Investigar origem dos stories incorretos

2. **Contextos Inválidos**
   - Procurar por: `❌ CONTEXT_ERROR`
   - Ação: Verificar código que passa contextos

3. **Performance Degradada**
   - Procurar por: `⚡ CONTEXT_PERF` com duração > 1000ms
   - Ação: Otimizar consultas

4. **Stories Removidos por Filtro**
   - Procurar por: `⚠️ Stories removidos: X` onde X > 0
   - Ação: Investigar por que há stories incorretos

## 🎯 **Cenários de Debug**

### Cenário 1: Stories do Chat Principal aparecem no Sinais Rebeca
```
🔍 Procurar logs:
📥 CONTEXT_LOAD: getAllSinaisRebeca
🚨 CONTEXT_LEAK: getAllSinaisRebeca - Vazamentos detectados
   - X stories do contexto "principal"

🔧 Solução:
- Verificar se a coleção stories_sinais_rebeca tem stories com contexto "principal"
- Corrigir dados no Firebase ou investigar código de inserção
```

### Cenário 2: Favoritos não aparecem no contexto correto
```
🔍 Procurar logs:
📥 CONTEXT_LOAD: getUserFavoritesStream
🚨 CONTEXT_LEAK: getUserFavoritesStream - Vazamentos detectados
   - X favoritos do contexto "Y"

🔧 Solução:
- Verificar se os favoritos foram salvos com contexto correto
- Executar migração de favoritos legacy se necessário
```

### Cenário 3: Círculos de notificação incorretos
```
🔍 Procurar logs:
📋 CONTEXT_SUMMARY: hasUnviewedStories
📋 CONTEXT_SUMMARY: allStoriesViewedInContext_result

🔧 Solução:
- Verificar se os cálculos estão usando o contexto correto
- Verificar se stories vistos estão sendo marcados com contexto correto
```

## 🚀 **Dicas de Performance**

1. **Desabilitar Logs em Produção**
   ```dart
   static const bool ENABLE_CONTEXT_LOGS = false; // Para produção
   ```

2. **Logs Seletivos**
   ```dart
   static const bool LOG_QUERY_PERFORMANCE = false; // Desabilitar se não precisar
   ```

3. **Filtrar Logs por Contexto**
   ```bash
   # Filtrar logs de um contexto específico
   grep "sinais_rebeca" logs.txt
   
   # Filtrar apenas vazamentos
   grep "CONTEXT_LEAK" logs.txt
   ```

## 📋 **Checklist de Debug**

### ✅ **Verificações Básicas**
- [ ] Logs de carregamento mostram contexto correto
- [ ] Não há logs de vazamento (`🚨 CONTEXT_LEAK`)
- [ ] Não há logs de erro crítico (`❌ CONTEXT_ERROR`)
- [ ] Stories removidos por filtro = 0

### ✅ **Verificações Avançadas**
- [ ] Performance das consultas < 500ms
- [ ] Contextos são validados antes de usar
- [ ] Favoritos são salvos com contexto correto
- [ ] Círculos de notificação calculam apenas o contexto correto

### ✅ **Verificações de Produção**
- [ ] Logs críticos são monitorados
- [ ] Alertas configurados para vazamentos
- [ ] Dashboard de performance configurado
- [ ] Logs são arquivados regularmente

## 🎉 **Conclusão**

O sistema de logs de contexto fornece visibilidade completa sobre o isolamento entre contextos. Use este guia para:

1. **Debuggar** problemas de vazamento
2. **Monitorar** performance das consultas
3. **Validar** que o isolamento está funcionando
4. **Otimizar** o sistema baseado nos logs

Para mais informações, consulte os arquivos:
- `lib/utils/context_debug.dart` - Configurações de debug
- `lib/utils/context_validator.dart` - Validações de contexto
- `lib/utils/story_context_filter.dart` - Filtros de contexto