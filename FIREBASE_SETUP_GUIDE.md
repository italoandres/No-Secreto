# 🔥 Guia de Configuração do Firebase - Sistema de Parceria

## 📋 Visão Geral

Este guia explica como configurar as coleções do Firebase Firestore para o sistema de parceria no Propósito, incluindo convites, parcerias, chats compartilhados e sistema de bloqueio.

## 🚀 Configuração Inicial

### 1. Aplicar Regras de Segurança

```bash
# Aplicar regras de segurança
firebase deploy --only firestore:rules

# Verificar se as regras foram aplicadas
firebase firestore:rules get
```

### 2. Configurar Índices

```bash
# Aplicar índices
firebase deploy --only firestore:indexes

# Verificar índices no console
# https://console.firebase.google.com/project/[SEU_PROJETO]/firestore/indexes
```

### 3. Inicializar Coleções (Código)

```dart
import 'package:whatsapp_chat/repositories/purpose_partnership_repository.dart';
import 'package:whatsapp_chat/utils/firebase_collections_test.dart';

// Em algum lugar da inicialização do app
await PurposePartnershipRepository.initializeCollections();

// Para testar se tudo está funcionando
await FirebaseCollectionsTest.runAllTests();
```

## 📊 Estrutura das Coleções

### 🎯 purpose_invites
Armazena convites de parceria e menções

**Campos principais:**
- `fromUserId` - ID do usuário que enviou
- `toUserId` - ID do usuário que recebeu  
- `type` - 'partnership' ou 'mention'
- `status` - 'pending', 'accepted', 'rejected', 'blocked'
- `message` - mensagem personalizada

### 💕 purpose_partnerships
Parcerias estabelecidas entre usuários

**Campos principais:**
- `user1Id`, `user2Id` - IDs dos parceiros
- `chatId` - ID do chat compartilhado
- `isActive` - se a parceria está ativa

### 💬 purpose_chats
Chats compartilhados entre parceiros

**Campos principais:**
- `participantIds` - array com IDs dos participantes
- `isActive` - se o chat está ativo
- Sub-coleção `messages` para as mensagens

### 🚫 blocked_users
Lista de usuários bloqueados

**Campos principais:**
- `blockedUserId` - ID do usuário bloqueado
- `blockerUserId` - ID de quem bloqueou

## 🔧 Comandos Úteis

### Verificar Saúde das Coleções

```dart
final health = await PurposePartnershipRepository.checkCollectionsHealth();
print('Saúde das coleções: $health');
```

### Teste Rápido

```dart
await FirebaseCollectionsTest.quickTest();
```

### Teste Completo

```dart
await FirebaseCollectionsTest.runAllTests();
```

## 🛡️ Segurança

### Regras Implementadas:

1. **Autenticação obrigatória** para todas as operações
2. **Propriedade de dados** - usuários só modificam seus dados
3. **Acesso controlado** - convites só acessíveis pelos envolvidos
4. **Chats privados** - apenas participantes podem acessar
5. **Bloqueio efetivo** - usuários bloqueados não podem enviar convites

### Validações no Frontend:

- ✅ Verificação de mesmo sexo
- ✅ Prevenção de auto-convite
- ✅ Verificação de usuário bloqueado
- ✅ Validação de convites duplicados

## 📈 Monitoramento

### Métricas Importantes:

1. **Convites por dia** - monitorar spam
2. **Taxa de aceitação** - engajamento
3. **Parcerias ativas** - sucesso do sistema
4. **Usuários bloqueados** - problemas de comportamento

### Logs a Observar:

```dart
// Logs de inicialização
✅ Coleções do Firebase inicializadas com sucesso
📁 Coleção purpose_invites inicializada

// Logs de saúde
✅ purpose_invites: OK
✅ purpose_partnerships: OK
```

## 🐛 Troubleshooting

### Problema: Coleção não inicializada
```dart
// Solução: Executar inicialização manual
await PurposePartnershipRepository.initializeCollections();
```

### Problema: Regras de segurança negando acesso
```bash
# Verificar regras no console Firebase
# Testar com usuário autenticado
```

### Problema: Índices faltando
```bash
# Aplicar índices novamente
firebase deploy --only firestore:indexes
```

### Problema: Performance lenta
- Verificar se todos os índices estão criados
- Monitorar uso de queries complexas
- Considerar paginação para listas grandes

## 🔄 Atualizações Futuras

Para adicionar novas funcionalidades:

1. **Atualizar modelos** em `lib/models/`
2. **Adicionar métodos** no repository
3. **Atualizar regras** em `firestore.rules`
4. **Criar novos índices** em `firestore.indexes.json`
5. **Testar** com `FirebaseCollectionsTest`

## 📞 Suporte

Em caso de problemas:

1. Verificar logs do console Firebase
2. Executar testes de saúde das coleções
3. Verificar autenticação do usuário
4. Consultar documentação do Firebase

---

**✨ Sistema configurado com sucesso! Agora você pode usar todas as funcionalidades de parceria no Propósito.**