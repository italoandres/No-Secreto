# Configuração do Firebase para Sistema de Parceria no Propósito

## Coleções Criadas

### 1. purpose_invites
**Descrição:** Armazena convites de parceria e menções entre usuários

**Estrutura:**
```json
{
  "id": "string (auto-generated)",
  "fromUserId": "string",
  "fromUserName": "string", 
  "toUserId": "string",
  "toUserEmail": "string",
  "type": "string", // 'partnership' ou 'mention'
  "message": "string", // mensagem personalizada
  "status": "string", // 'pending', 'accepted', 'rejected', 'blocked'
  "dataCriacao": "timestamp",
  "dataResposta": "timestamp (opcional)"
}
```

**Índices:**
- `toUserId + status + dataCriacao (desc)`
- `fromUserId + status + dataCriacao (desc)`
- `toUserId + type + status`

### 2. purpose_partnerships
**Descrição:** Armazena parcerias estabelecidas entre usuários

**Estrutura:**
```json
{
  "id": "string (auto-generated)",
  "user1Id": "string",
  "user1Name": "string",
  "user2Id": "string", 
  "user2Name": "string",
  "chatId": "string", // ID do chat compartilhado
  "isActive": "boolean",
  "dataCriacao": "timestamp",
  "dataDesconexao": "timestamp (opcional)"
}
```

**Índices:**
- `user1Id + isActive`
- `user2Id + isActive`

### 3. purpose_chats
**Descrição:** Chats compartilhados entre parceiros e admin

**Estrutura:**
```json
{
  "id": "string (auto-generated)",
  "participantIds": "array<string>", // IDs dos participantes
  "participantNames": "array<string>", // Nomes dos participantes
  "isActive": "boolean",
  "lastMessage": "string",
  "lastMessageTime": "timestamp",
  "dataCriacao": "timestamp"
}
```

**Sub-coleção: messages**
```json
{
  "id": "string (auto-generated)",
  "senderId": "string",
  "senderName": "string",
  "message": "string",
  "type": "string", // 'text', 'image', 'video', 'audio'
  "timestamp": "timestamp",
  "isRead": "boolean"
}
```

**Índices:**
- `participantIds (array-contains) + isActive`
- `messages: chatId + timestamp (desc)`

### 4. blocked_users
**Descrição:** Lista de usuários bloqueados

**Estrutura:**
```json
{
  "id": "string (auto-generated)",
  "blockedUserId": "string",
  "blockerUserId": "string", 
  "dataBlocked": "timestamp"
}
```

**Índices:**
- `blockerUserId + dataBlocked (desc)`
- `blockedUserId + blockerUserId`

## Regras de Segurança

As regras de segurança foram configuradas em `firestore.rules` com os seguintes princípios:

1. **Autenticação obrigatória** para todas as operações
2. **Propriedade de dados** - usuários só podem modificar seus próprios dados
3. **Acesso controlado** - convites e parcerias só acessíveis pelos envolvidos
4. **Prevenção de spam** - validações para criação de convites
5. **Privacidade** - chats só acessíveis pelos participantes

## Comandos de Deploy

Para aplicar as configurações:

```bash
# Deploy das regras de segurança
firebase deploy --only firestore:rules

# Deploy dos índices
firebase deploy --only firestore:indexes

# Deploy completo
firebase deploy
```

## Validações Implementadas

### No Frontend:
- ✅ Verificação de mesmo sexo
- ✅ Validação de usuário existente
- ✅ Prevenção de auto-convite
- ✅ Verificação de convites duplicados

### No Backend (Regras):
- ✅ Autenticação obrigatória
- ✅ Propriedade de dados
- ✅ Controle de acesso por participante
- ✅ Validação de permissões de escrita

## Monitoramento

Recomenda-se monitorar:
- Número de convites por usuário/dia
- Taxa de aceitação de convites
- Atividade nos chats compartilhados
- Usuários bloqueados

## Backup e Recuperação

- Configurar backup automático das coleções críticas
- Implementar logs de auditoria para ações importantes
- Manter histórico de parcerias desfeitas