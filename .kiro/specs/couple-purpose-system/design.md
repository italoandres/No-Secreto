# Sistema de Parceiro(a) no Propósito - Design Técnico

## Overview

O Sistema de Parceiro(a) no Propósito é uma extensão do chat "Nosso Propósito" que permite criar conversas compartilhadas entre casais e Deus. O sistema utiliza Firebase Firestore para gerenciar convites, parcerias e mensagens compartilhadas.

## Architecture

### Componentes Principais

1. **PurposePartnershipService** - Gerencia convites e parcerias
2. **PurposeInviteModel** - Modelo de dados para convites
3. **PurposePartnershipModel** - Modelo de dados para parcerias
4. **PurposeChatRepository** - Repositório específico para chat do propósito
5. **MentionSystem** - Sistema de @menções com convites
6. **PurposeNotificationService** - Notificações específicas do sistema

### Fluxo de Dados

```
[Usuário A] → [Convite] → [Firebase] → [Notificação] → [Usuário B]
     ↓                                                      ↓
[Chat Compartilhado] ← [Aceite] ← [Interface] ← [Decisão]
```

## Components and Interfaces

### 1. Modelos de Dados

#### PurposeInviteModel
```dart
class PurposeInviteModel {
  String? id;
  String? fromUserId;
  String? fromUserName;
  String? toUserId;
  String? toUserEmail;
  String? type; // 'partnership' ou 'mention'
  String? message; // Para convites de menção
  String? status; // 'pending', 'accepted', 'rejected'
  Timestamp? dataCriacao;
  Timestamp? dataResposta;
}
```

#### PurposePartnershipModel
```dart
class PurposePartnershipModel {
  String? id;
  String? user1Id;
  String? user2Id;
  String? chatId; // ID único do chat compartilhado
  bool? isActive;
  Timestamp? dataConexao;
  Timestamp? dataDesconexao;
}
```

#### PurposeChatModel (extensão do ChatModel)
```dart
class PurposeChatModel extends ChatModel {
  String? chatId; // ID do chat compartilhado
  List<String>? participantIds; // IDs dos participantes
  String? messagePosition; // 'left' (casal) ou 'right' (admin)
  String? mentionedUserId; // Para mensagens com @menção
}
```

### 2. Repositórios

#### PurposePartnershipRepository
```dart
class PurposePartnershipRepository {
  // Convites
  static Future<void> sendPartnershipInvite(String toUserEmail, UsuarioModel fromUser);
  static Future<void> sendMentionInvite(String toUserId, String message, UsuarioModel fromUser);
  static Stream<List<PurposeInviteModel>> getUserInvites(String userId);
  static Future<void> respondToInvite(String inviteId, bool accepted);
  
  // Parcerias
  static Future<PurposePartnershipModel?> getUserPartnership(String userId);
  static Future<void> createPartnership(String user1Id, String user2Id);
  static Future<void> disconnectPartnership(String partnershipId);
  
  // Chat
  static Stream<List<PurposeChatModel>> getSharedChat(String chatId);
  static Future<void> sendSharedMessage(String chatId, String message, List<String> participantIds);
  static Future<void> sendMentionMessage(String message, String mentionedUserId, UsuarioModel fromUser);
}
```

### 3. Serviços

#### PurposePartnershipService
```dart
class PurposePartnershipService {
  static Future<UsuarioModel?> searchUserByEmail(String email);
  static Future<bool> canInviteUser(String fromUserId, String toUserId);
  static Future<void> processInviteAcceptance(PurposeInviteModel invite);
  static Future<String> generateSharedChatId(String user1Id, String user2Id);
}
```

## Data Models

### Estrutura do Firebase Firestore

#### Coleção: `purpose_invites`
```json
{
  "id": "auto_generated",
  "fromUserId": "user_id_1",
  "fromUserName": "Nome do Usuário",
  "toUserId": "user_id_2", 
  "toUserEmail": "email@exemplo.com",
  "type": "partnership", // ou "mention"
  "message": "Mensagem para convite de menção",
  "status": "pending", // "accepted", "rejected"
  "dataCriacao": "timestamp",
  "dataResposta": "timestamp"
}
```

#### Coleção: `purpose_partnerships`
```json
{
  "id": "auto_generated",
  "user1Id": "user_id_1",
  "user2Id": "user_id_2", 
  "chatId": "shared_chat_unique_id",
  "isActive": true,
  "dataConexao": "timestamp",
  "dataDesconexao": null
}
```

#### Coleção: `purpose_chats`
```json
{
  "id": "auto_generated",
  "chatId": "shared_chat_unique_id",
  "participantIds": ["user_id_1", "user_id_2"],
  "tipo": "text",
  "msg": "Mensagem do chat",
  "messagePosition": "left", // "right" para admin
  "mentionedUserId": "user_id_3", // opcional
  "orginemAdmin": false,
  "dataCadastro": "timestamp",
  "autorId": "user_id_1",
  "autorNome": "Nome do Autor"
}
```

## Error Handling

### Tratamento de Erros Específicos

1. **Usuário não encontrado**
   - Exibir mensagem: "Usuário não encontrado. Verifique o email digitado."

2. **Convite já enviado**
   - Exibir mensagem: "Convite já foi enviado para este usuário."

3. **Usuário já conectado**
   - Exibir mensagem: "Você já possui um(a) parceiro(a) conectado."

4. **Erro de conexão**
   - Exibir mensagem: "Erro de conexão. Tente novamente."

5. **Convite expirado**
   - Exibir mensagem: "Este convite expirou."

## Testing Strategy

### Testes Unitários

1. **PurposePartnershipRepository**
   - Teste de envio de convites
   - Teste de busca de usuários
   - Teste de criação de parcerias
   - Teste de mensagens compartilhadas

2. **PurposePartnershipService**
   - Teste de validação de convites
   - Teste de geração de IDs únicos
   - Teste de processamento de respostas

3. **Modelos de Dados**
   - Teste de serialização/deserialização
   - Teste de validação de campos obrigatórios

### Testes de Integração

1. **Fluxo Completo de Convite**
   - Envio → Recebimento → Aceitação → Chat Compartilhado

2. **Sistema de @Menções**
   - Menção → Convite → Aceitação → Participação no Chat

3. **Notificações**
   - Push notifications para todos os eventos

### Testes de Interface

1. **Dialog de Convite**
   - Validação de campos
   - Feedback visual
   - Estados de loading

2. **Chat Compartilhado**
   - Posicionamento correto das mensagens
   - Indicadores de participantes
   - Funcionalidade de @menções

## Implementation Plan

### Fase 1: Modelos e Repositórios Base
- Criar modelos de dados
- Implementar repositório básico
- Configurar coleções no Firebase

### Fase 2: Sistema de Convites
- Interface de busca de usuários
- Envio e recebimento de convites
- Sistema de notificações

### Fase 3: Chat Compartilhado
- Lógica de chat triplo
- Posicionamento de mensagens
- Sincronização entre participantes

### Fase 4: Sistema de @Menções
- Parser de menções
- Convites automáticos
- Integração com chat compartilhado

### Fase 5: Stories Compartilhados
- Filtros para ambos os sexos
- Sincronização de visualizações
- Interface adaptada

### Fase 6: Testes e Refinamentos
- Testes completos
- Otimizações de performance
- Ajustes de UX

## Security Considerations

1. **Validação de Convites**
   - Verificar se usuário pode enviar convites
   - Limitar número de convites por período
   - Validar emails antes do envio

2. **Proteção de Dados**
   - Criptografar mensagens sensíveis
   - Controlar acesso aos chats compartilhados
   - Logs de auditoria para ações importantes

3. **Prevenção de Spam**
   - Rate limiting para convites
   - Blacklist de usuários problemáticos
   - Validação de relacionamentos legítimos

## Performance Optimization

1. **Cache de Parcerias**
   - Manter parcerias ativas em cache local
   - Sincronização eficiente com Firebase

2. **Paginação de Mensagens**
   - Carregar mensagens em lotes
   - Lazy loading para histórico antigo

3. **Otimização de Queries**
   - Índices compostos no Firestore
   - Queries otimizadas para busca de usuários

4. **Compressão de Dados**
   - Compressão de mensagens longas
   - Otimização de imagens compartilhadas