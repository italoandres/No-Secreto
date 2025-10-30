# Design Document - Preferências de Interação (Rebuild)

## Overview

Esta implementação criará um sistema completamente novo para gerenciar preferências de interação, substituindo a implementação atual que apresenta problemas críticos de tipos de dados. O design foca em robustez, simplicidade e prevenção de conflitos de tipos.

## Architecture

### Componentes Principais

1. **PreferencesInteractionView** - Nova view limpa sem dependências do código problemático
2. **PreferencesService** - Serviço dedicado para lógica de preferências
3. **DataSanitizer** - Utilitário para sanitização e validação de dados
4. **PreferencesRepository** - Repository específico para operações de preferências

### Fluxo de Dados

```
User Input → PreferencesInteractionView → PreferencesService → DataSanitizer → PreferencesRepository → Firestore
```

## Components and Interfaces

### 1. PreferencesInteractionView

**Responsabilidade:** Interface do usuário para configuração de preferências

**Características:**
- Implementação completamente nova, sem herança do código problemático
- Estado local simples com apenas campos necessários
- Validação de entrada antes de envio
- Feedback visual claro para todas as operações

**Interface:**
```dart
class PreferencesInteractionView extends StatefulWidget {
  final String profileId;
  final Function(String taskName) onTaskCompleted;
  
  // Estado interno
  bool _allowInteractions = true;
  bool _isLoading = false;
  String? _errorMessage;
}
```

### 2. PreferencesService

**Responsabilidade:** Lógica de negócio para preferências de interação

**Características:**
- Validação de dados de entrada
- Coordenação entre sanitização e persistência
- Tratamento de erros específicos
- Logs estruturados

**Interface:**
```dart
class PreferencesService {
  static Future<PreferencesResult> savePreferences({
    required String profileId,
    required bool allowInteractions,
  });
  
  static Future<PreferencesData> loadPreferences(String profileId);
  static Future<void> markTaskComplete(String profileId);
}
```

### 3. DataSanitizer

**Responsabilidade:** Sanitização e validação de dados

**Características:**
- Conversão segura de tipos
- Validação de integridade
- Correção automática de dados corrompidos
- Logs detalhados de transformações

**Interface:**
```dart
class DataSanitizer {
  static Map<String, dynamic> sanitizePreferencesData(Map<String, dynamic> data);
  static bool sanitizeBoolean(dynamic value, bool defaultValue);
  static Map<String, bool> sanitizeCompletionTasks(dynamic tasks);
}
```

### 4. PreferencesRepository

**Responsabilidade:** Persistência específica para preferências

**Características:**
- Operações atômicas
- Múltiplas estratégias de persistência (update, set, merge)
- Retry automático com backoff
- Validação pós-persistência

**Interface:**
```dart
class PreferencesRepository {
  static Future<void> updatePreferences(String profileId, PreferencesData data);
  static Future<PreferencesData?> getPreferences(String profileId);
  static Future<void> updateTaskCompletion(String profileId, String task, bool completed);
}
```

## Data Models

### PreferencesData

```dart
class PreferencesData {
  final bool allowInteractions;
  final DateTime updatedAt;
  final String version; // Para controle de versão
  
  // Métodos de serialização seguros
  Map<String, dynamic> toFirestore();
  static PreferencesData fromFirestore(Map<String, dynamic> data);
}
```

### PreferencesResult

```dart
class PreferencesResult {
  final bool success;
  final String? errorMessage;
  final PreferencesData? data;
  final List<String> appliedCorrections;
}
```

## Error Handling

### Estratégia de Múltiplas Camadas

1. **Camada de Validação:** Validação de entrada na UI
2. **Camada de Sanitização:** Correção automática de dados
3. **Camada de Persistência:** Múltiplas estratégias de save
4. **Camada de Recuperação:** Fallbacks e retry

### Tipos de Erro e Tratamento

```dart
enum PreferencesError {
  validationError,    // Dados de entrada inválidos
  sanitizationError,  // Falha na correção de dados
  persistenceError,   // Falha na persistência
  networkError,       // Problemas de conectividade
  unknownError        // Erros não categorizados
}
```

### Estratégias de Persistência

1. **Estratégia Primária:** `update()` normal
2. **Estratégia Secundária:** `update()` campo por campo
3. **Estratégia Terciária:** `set()` com merge
4. **Estratégia Final:** `set()` completo (substituição total)

## Testing Strategy

### Testes Unitários

1. **DataSanitizer Tests**
   - Conversão de Timestamp para boolean
   - Conversão de String para boolean
   - Conversão de null para boolean padrão
   - Sanitização de completionTasks

2. **PreferencesService Tests**
   - Fluxo completo de save
   - Tratamento de erros
   - Validação de entrada
   - Coordenação entre componentes

3. **PreferencesRepository Tests**
   - Múltiplas estratégias de persistência
   - Retry e backoff
   - Validação pós-persistência

### Testes de Integração

1. **Fluxo Completo**
   - UI → Service → Repository → Firestore
   - Cenários de sucesso e falha
   - Recuperação automática

2. **Cenários de Dados Corrompidos**
   - Dados com Timestamp em campos boolean
   - Dados com tipos mistos
   - Dados parcialmente corrompidos

## Implementation Phases

### Fase 1: Estrutura Base
- Criar novos arquivos sem dependências do código atual
- Implementar DataSanitizer com testes
- Implementar PreferencesData model

### Fase 2: Lógica de Negócio
- Implementar PreferencesService
- Implementar PreferencesRepository
- Testes unitários completos

### Fase 3: Interface do Usuário
- Implementar PreferencesInteractionView
- Integração com serviços
- Testes de integração

### Fase 4: Substituição e Cleanup
- Substituir implementação atual
- Remover código problemático
- Validação final

## Security Considerations

1. **Validação de Entrada:** Todos os dados de entrada são validados
2. **Sanitização:** Dados são sanitizados antes da persistência
3. **Logs Seguros:** Logs não expõem dados sensíveis
4. **Controle de Acesso:** Apenas o próprio usuário pode alterar suas preferências

## Performance Considerations

1. **Operações Atômicas:** Updates são atômicos para evitar estados inconsistentes
2. **Caching Local:** Estado local para evitar reads desnecessários
3. **Batch Operations:** Múltiplas operações são agrupadas quando possível
4. **Lazy Loading:** Dados são carregados apenas quando necessários

## Monitoring and Logging

### Logs Estruturados

```dart
// Exemplo de log estruturado
EnhancedLogger.info('Preferences save initiated', 
  tag: 'PREFERENCES_V2',
  data: {
    'profileId': profileId,
    'allowInteractions': allowInteractions,
    'version': '2.0.0',
  }
);
```

### Métricas

1. **Taxa de Sucesso:** Percentual de saves bem-sucedidos
2. **Tempo de Resposta:** Tempo médio para save
3. **Correções Aplicadas:** Número de correções automáticas
4. **Estratégias Usadas:** Qual estratégia de persistência foi usada

## Migration Strategy

### Dados Existentes

1. **Detecção:** Identificar perfis com dados corrompidos
2. **Migração:** Aplicar sanitização durante primeira operação
3. **Validação:** Verificar integridade após migração
4. **Rollback:** Capacidade de reverter se necessário

### Compatibilidade

- Sistema novo deve ser compatível com dados existentes
- Migração transparente para usuários
- Fallback para sistema antigo se necessário (temporário)