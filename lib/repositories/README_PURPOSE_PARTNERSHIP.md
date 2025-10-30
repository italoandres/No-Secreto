# 🤝 PurposePartnershipRepository

## 📋 Visão Geral

O `PurposePartnershipRepository` é o repositório central para gerenciar todas as operações relacionadas ao sistema de parceria no Propósito, incluindo convites, parcerias, chats compartilhados e sistema de bloqueio.

## 🏗️ Arquitetura

### Coleções Firebase:
- **purpose_invites** - Convites de parceria e menções
- **purpose_partnerships** - Parcerias estabelecidas
- **purpose_chats** - Chats compartilhados
- **blocked_users** - Sistema de bloqueio
- **usuarios** - Dados dos usuários

## 🔧 Funcionalidades Principais

### 🎯 Inicialização
```dart
// Inicializar coleções (executar uma vez)
await PurposePartnershipRepository.initializeCollections();

// Verificar saúde das coleções
final health = await PurposePartnershipRepository.checkCollectionsHealth();
```

### 📨 Sistema de Convites

#### Enviar Convites
```dart
// Convite de parceria com mensagem personalizada
await PurposePartnershipRepository.sendPartnershipInviteWithMessage(
  'email@exemplo.com',
  'Mensagem personalizada',
  usuarioAtual
);

// Convite de menção
await PurposePartnershipRepository.sendMentionInvite(
  'userId',
  'Mensagem da menção',
  usuarioAtual
);
```

#### Gerenciar Convites
```dart
// Obter convites do usuário (Stream)
Stream<List<PurposeInviteModel>> convites = 
  PurposePartnershipRepository.getUserInvites(userId);

// Responder a convite
await PurposePartnershipRepository.respondToInviteWithAction(
  inviteId, 
  'accepted' // 'accepted', 'rejected', 'blocked'
);
```

### 💕 Sistema de Parcerias

#### Gerenciar Parcerias
```dart
// Obter parceria do usuário
final parceria = await PurposePartnershipRepository.getUserPartnership(userId);

// Criar parceria
await PurposePartnershipRepository.createPartnership(user1Id, user2Id);

// Desconectar parceria
await PurposePartnershipRepository.disconnectPartnership(partnershipId);

// Verificar se já foram parceiros
final foramParceiros = await PurposePartnershipRepository.werePartners(
  user1Id, user2Id
);
```

#### Histórico e Estatísticas
```dart
// Obter parcerias ativas
final ativas = await PurposePartnershipRepository.getActivePartnerships();

// Histórico do usuário
final historico = await PurposePartnershipRepository.getUserPartnershipHistory(userId);

// Estatísticas do usuário
final stats = await PurposePartnershipRepository.getUserInviteStats(userId);

// Estatísticas do sistema
final systemStats = await PurposePartnershipRepository.getSystemStats();
```

### 💬 Chat Compartilhado

```dart
// Obter mensagens (Stream)
Stream<List<PurposeChatModel>> mensagens = 
  PurposePartnershipRepository.getSharedChat(chatId);

// Enviar mensagem do casal
await PurposePartnershipRepository.sendSharedMessage(
  chatId, 
  'mensagem', 
  participantIds,
  mentionedUserId: 'userId' // opcional
);

// Enviar mensagem de admin
await PurposePartnershipRepository.sendAdminMessage(
  chatId, 
  'mensagem do admin', 
  participantIds
);
```

### 🔍 Busca de Usuários

```dart
// Buscar por email
final usuario = await PurposePartnershipRepository.searchUserByEmail(
  'email@exemplo.com'
);

// Buscar por nome (para @menções)
final usuarios = await PurposePartnershipRepository.searchUsersByName('nome');
```

### 🚫 Sistema de Bloqueio

```dart
// Verificar se usuário está bloqueado
final bloqueado = await PurposePartnershipRepository.isUserBlocked(
  fromUserId, toUserId
);

// Verificar se pode enviar convite
final podeEnviar = await PurposePartnershipRepository.canInviteUser(
  fromUserId, toUserId
);
```

## ✅ Validações

### Validação de Convites
```dart
final valido = PurposePartnershipRepository.validateInviteData(
  fromUserId, 
  toUserEmail, 
  message
);
```

**Regras:**
- ✅ Email deve ter formato válido
- ✅ Mensagem máximo 500 caracteres
- ✅ IDs não podem estar vazios

### Validação de Parcerias
```dart
final valido = PurposePartnershipRepository.validatePartnershipData(
  user1Id, user2Id
);
```

**Regras:**
- ✅ IDs devem ser diferentes
- ✅ IDs não podem estar vazios

## 🛡️ Tratamento de Erros

Todos os métodos lançam `Exception` com mensagens descritivas:

```dart
try {
  await PurposePartnershipRepository.sendPartnershipInvite(email, user);
} catch (e) {
  print('Erro: ${e.toString()}');
  // Exemplos de erros:
  // - "Usuário não encontrado com este email"
  // - "Convite já foi enviado para este usuário"
  // - "Você já possui um(a) parceiro(a) conectado"
  // - "Não é possível adicionar pessoa do mesmo sexo"
}
```

## 📊 Rate Limiting

- **Convites por dia:** Máximo 5 convites por usuário
- **Verificação automática** antes de enviar convites
- **Prevenção de spam** integrada

## 🔄 Streams vs Futures

### Use Streams para:
- ✅ Lista de convites (`getUserInvites`)
- ✅ Mensagens do chat (`getSharedChat`)
- ✅ Dados que mudam em tempo real

### Use Futures para:
- ✅ Operações únicas (`sendInvite`, `createPartnership`)
- ✅ Validações (`isUserBlocked`, `canInviteUser`)
- ✅ Estatísticas (`getUserInviteStats`)

## 🧪 Testes

Execute os testes unitários:
```bash
flutter test test/repositories/purpose_partnership_repository_test.dart
```

### Cobertura de Testes:
- ✅ Validações de dados
- ✅ Tratamento de erros
- ✅ Lógica de negócio
- ⏳ Testes de integração (com Firebase Emulator)

## 🚀 Performance

### Otimizações Implementadas:
- ✅ Índices compostos no Firestore
- ✅ Queries limitadas (`.limit()`)
- ✅ Ordenação eficiente
- ✅ Cache de validações

### Monitoramento:
- 📊 Número de queries por operação
- ⏱️ Tempo de resposta das operações
- 💾 Uso de cache local

## 🔮 Próximas Funcionalidades

- [ ] Cache local com Hive/SharedPreferences
- [ ] Retry automático para operações falhadas
- [ ] Batch operations para múltiplas operações
- [ ] Paginação para listas grandes
- [ ] Notificações push integradas

## 📞 Suporte

Para problemas ou dúvidas:

1. **Verificar logs** do console Firebase
2. **Executar testes** de saúde das coleções
3. **Consultar documentação** do Firebase
4. **Verificar regras** de segurança

---

**✨ Repository completo e otimizado para o sistema de parceria no Propósito!**