# Correção de Erros de Logging no Repository

## Problema
O EnhancedLogger não aceita parâmetro `error`, apenas `data`. Todos os usos de `error: e` devem ser convertidos para `data: {'error': e.toString()}`.

## Correções Aplicadas

### 1. Método _indexMissingFallback
- Linha 1046: `error: e` → `data: {'error': e.toString()}`
- Linha 1059: `error: e` → `data: {'error': e.toString()}`

### 2. Método _permissionDeniedFallback  
- Linha 1088: `error: e` → `data: {'error': e.toString()}`

### 3. Método _cacheFallback
- Linha 1123: `error: e` → `data: {'error': e.toString()}`

### 4. Método _networkErrorFallback
- Linha 1139: `error: e` → `data: {'error': e.toString()}`

### 5. Método _quotaExceededFallback
- Linha 1173: `error: e` → `data: {'error': e.toString()}`

### 6. Método _emergencyFallback
- Linha 1203: `error: e` → `data: {'error': e.toString()}`

## Status
✅ Identificados todos os erros de logging
⏳ Aplicando correções...