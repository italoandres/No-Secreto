# 📋 Spec: Melhorar Tela de Matches Aceitos

## 🎯 Objetivo

Melhorar a tela de matches aceitos para incluir:
1. ✅ Fotos reais dos perfis
2. ✅ Status de presença online ("Online agora" / "Visto há X")
3. ✅ Notificações de mensagens sincronizadas em tempo real
4. ✅ Funcionamento correto no APK de produção
5. ✅ Visual elegante e informativo

## 📁 Arquivos da Spec

- **Requirements**: `.kiro/specs/melhorar-accepted-matches/requirements.md`
- **Design**: `.kiro/specs/melhorar-accepted-matches/design.md`
- **Tasks**: `.kiro/specs/melhorar-accepted-matches/tasks.md`

## 🔍 Problemas Identificados

### 1. Foto Genérica
**Atual**: Círculo rosa com coração
**Problema**: Não mostra a foto real do perfil
**Solução**: Buscar foto do Firestore e exibir no avatar

### 2. Sem Status de Presença
**Atual**: Não mostra se a pessoa está online
**Problema**: Usuário não sabe se pode esperar resposta rápida
**Solução**: Sistema de presença com "Online agora" / "Visto há X"

### 3. Notificações Não Sincronizam
**Atual**: Mostra "1 nova mensagem" mas não atualiza
**Problema**: Contador não reflete mensagens reais
**Solução**: Stream em tempo real do Firestore

### 4. Não Funciona no APK
**Atual**: Funciona em perfil antigo mas não no APK
**Problema**: Possível erro de permissões ou dados ausentes
**Solução**: Tratamento robusto de erros e fallbacks

## 🏗️ Arquitetura da Solução

```
SimpleAcceptedMatchesView
    ↓
AcceptedMatchesController
    ↓
├── SimpleAcceptedMatchesRepository (Matches + Fotos)
├── UserPresenceService (Status Online)
└── ChatUnreadCounter (Mensagens Não Lidas)
```

## 📊 Novo Visual do Card

```
┌─────────────────────────────────────────┐
│  ┌────┐                              🔴 │ ← Badge (3 não lidas)
│  │ 📷 │  Maria, 25                      │
│  │    │  São Paulo, SP                  │
│  └────┘  ● Online agora                 │ ← Status presença
│          "Oi, tudo bem?"                 │ ← Preview mensagem
│          há 5 minutos                    │ ← Tempo
└─────────────────────────────────────────┘
```

## 🎨 Componentes Novos

### 1. EnhancedMatchCard
- Foto 60x60 com indicador de presença
- Nome, idade e cidade
- Status online/offline
- Preview da última mensagem
- Badge de mensagens não lidas

### 2. UserPresenceService
```dart
// Atualizar presença
updatePresence(userId, isOnline)

// Stream de presença
getPresenceStream(userId) → Stream<UserPresence>

// Formatar tempo
formatLastSeen(DateTime) → "há 5 minutos"
```

### 3. ChatUnreadCounter
```dart
// Stream de não lidas
getUnreadCountStream(chatId, userId) → Stream<int>

// Marcar como lido
markAsRead(chatId, userId)

// Última mensagem
getLastMessage(chatId) → ChatMessage
```

## 📝 Fases de Implementação

### Fase 1: Fotos dos Perfis ✅
- Atualizar modelo com campo `otherUserPhoto`
- Buscar foto do Firestore
- Exibir na UI com fallback

### Fase 2: Sistema de Presença ✅
- Criar `UserPresence` model
- Criar `UserPresenceService`
- Integrar com AppLifecycle
- Exibir indicador no card

### Fase 3: Notificações de Mensagens ✅
- Criar `ChatUnreadCounter`
- Stream de contador em tempo real
- Badge animado na UI
- Zerar ao abrir chat

### Fase 4: Melhorias Visuais ✅
- Criar `EnhancedMatchCard`
- Preview da última mensagem
- Animações suaves
- Estados de loading/erro

### Fase 5: Correções para APK ✅
- Tratamento de permissões
- Logs de debug
- Testar em release build
- Atualizar regras Firestore

### Fase 6: Testes ⚠️ (Opcional)
- Unit tests
- Widget tests
- Integration tests

## 🚀 Como Começar

1. **Ler a spec completa**:
   ```bash
   # Requirements
   cat .kiro/specs/melhorar-accepted-matches/requirements.md
   
   # Design
   cat .kiro/specs/melhorar-accepted-matches/design.md
   
   # Tasks
   cat .kiro/specs/melhorar-accepted-matches/tasks.md
   ```

2. **Executar tarefas em ordem**:
   - Começar pela Fase 1 (Fotos)
   - Depois Fase 2 (Presença)
   - Depois Fase 3 (Notificações)
   - E assim por diante

3. **Testar incrementalmente**:
   - Testar cada fase antes de avançar
   - Verificar no Chrome e no APK
   - Garantir que nada quebrou

## ⚠️ Cuidados Importantes

### Não Quebrar Funcionalidades Existentes
- ✅ Manter compatibilidade com código atual
- ✅ Adicionar campos opcionais no modelo
- ✅ Fallbacks para dados ausentes
- ✅ Tratamento de erros robusto

### Performance
- ✅ Lazy loading de fotos
- ✅ Cache de imagens
- ✅ Debounce de presença (30s)
- ✅ Pagination de matches

### Firestore Rules
```javascript
// Permitir leitura de fotos
match /usuarios/{userId} {
  allow read: if request.auth != null;
}

// Permitir presença
match /user_presence/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}
```

## 📈 Benefícios Esperados

1. **UX Melhorada**: Usuários veem fotos reais e status
2. **Engajamento**: Notificações em tempo real aumentam respostas
3. **Confiança**: Saber quando alguém está online
4. **Profissionalismo**: Visual elegante e polido
5. **Estabilidade**: Funciona corretamente em produção

## 🎯 Próximos Passos

1. **Revisar a spec** com o time
2. **Aprovar o design** visual
3. **Começar implementação** pela Fase 1
4. **Testar incrementalmente** cada fase
5. **Deploy gradual** com monitoramento

---

**Status**: ✅ Spec Completa - Pronta para Implementação
**Prioridade**: 🔥 Alta
**Complexidade**: 🟡 Média
**Tempo Estimado**: 2-3 dias
