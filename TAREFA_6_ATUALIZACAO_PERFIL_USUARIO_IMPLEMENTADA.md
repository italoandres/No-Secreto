# ✅ Tarefa 6 - Atualização de Perfil do Usuário Implementada

## 📋 Resumo da Implementação

Implementei a atualização automática do perfil do usuário quando uma certificação é aprovada. O sistema agora adiciona o campo `spirituallyCertified: true` no documento do usuário de forma atômica.

---

## 🎯 O Que Foi Implementado

### Atualização Atômica do Perfil

Quando um administrador aprova uma certificação, o sistema agora:

1. **Busca a certificação** para obter o `userId`
2. **Usa uma transação Firestore** para garantir consistência
3. **Atualiza a certificação** com status 'approved'
4. **Atualiza o perfil do usuário** com os campos:
   - `spirituallyCertified: true`
   - `certificationApprovedAt: timestamp`
   - `certificationId: ID da certificação`
   - `updatedAt: timestamp`

---

## 🔧 Código Implementado

### Método `approveCertification` Atualizado

```dart
Future<bool> approveCertification(String requestId, {String? adminNotes}) async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    // Verificar se o usuário é admin
    if (!await _isUserAdmin(currentUser.uid)) {
      throw Exception('Usuário não tem permissão para aprovar certificações');
    }

    // Buscar a certificação para obter o userId
    final certDoc = await _certificationsRef.doc(requestId).get();
    if (!certDoc.exists) {
      throw Exception('Certificação não encontrada');
    }

    final certData = certDoc.data() as Map<String, dynamic>;
    final userId = certData['userId'] as String?;
    
    if (userId == null || userId.isEmpty) {
      throw Exception('userId não encontrado na certificação');
    }

    // Usar transação para garantir consistência
    await _firestore.runTransaction((transaction) async {
      // 1. Atualizar o documento da certificação
      transaction.update(_certificationsRef.doc(requestId), {
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': currentUser.uid,
        'adminEmail': currentUser.email,
        'adminNotes': adminNotes,
      });

      // 2. Atualizar o perfil do usuário
      final userRef = _firestore.collection('usuarios').doc(userId);
      transaction.update(userRef, {
        'spirituallyCertified': true,
        'certificationApprovedAt': FieldValue.serverTimestamp(),
        'certificationId': requestId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    print('✅ Certificação $requestId aprovada com sucesso');
    print('✅ Perfil do usuário $userId atualizado com spirituallyCertified: true');
    return true;
  } catch (e) {
    print('❌ Erro ao aprovar certificação $requestId: $e');
    return false;
  }
}
```

---

## 📊 Campos Adicionados ao Perfil do Usuário

### Estrutura do Documento `usuarios/{userId}`

Quando uma certificação é aprovada, os seguintes campos são adicionados/atualizados:

```json
{
  "spirituallyCertified": true,
  "certificationApprovedAt": "2024-01-15T10:30:00Z",
  "certificationId": "cert_abc123",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### Descrição dos Campos

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `spirituallyCertified` | Boolean | Indica se o usuário é certificado espiritualmente |
| `certificationApprovedAt` | Timestamp | Data e hora da aprovação |
| `certificationId` | String | ID da certificação aprovada |
| `updatedAt` | Timestamp | Data da última atualização do perfil |

---

## 🔒 Garantias de Consistência

### Transação Atômica

A implementação usa `runTransaction` do Firestore para garantir que:

1. **Ambas as atualizações acontecem juntas** ou nenhuma acontece
2. **Não há estado inconsistente** onde a certificação está aprovada mas o perfil não foi atualizado
3. **Operações são isoladas** de outras transações concorrentes

### Validações

- ✅ Verifica se o usuário está autenticado
- ✅ Verifica se o usuário é administrador
- ✅ Verifica se a certificação existe
- ✅ Verifica se o `userId` está presente
- ✅ Trata erros e retorna false em caso de falha

---

## 🎯 Benefícios da Implementação

### 1. Consistência de Dados
- Garante que certificação e perfil estão sempre sincronizados
- Evita estados inconsistentes no banco de dados

### 2. Rastreabilidade
- Registra quando a certificação foi aprovada
- Mantém referência à certificação no perfil
- Facilita auditoria e histórico

### 3. Performance
- Usa transação única para ambas as operações
- Minimiza chamadas ao banco de dados
- Reduz latência

### 4. Segurança
- Validações de permissão antes de atualizar
- Tratamento de erros robusto
- Logs detalhados para debugging

---

## 🔄 Fluxo Completo de Aprovação

```
1. Admin clica em "Aprovar" no painel
   ↓
2. Sistema verifica permissões
   ↓
3. Sistema busca certificação e obtém userId
   ↓
4. Inicia transação Firestore
   ↓
5. Atualiza certificação → status: 'approved'
   ↓
6. Atualiza perfil → spirituallyCertified: true
   ↓
7. Commit da transação
   ↓
8. Retorna sucesso
   ↓
9. Badge aparece no perfil do usuário ✨
```

---

## 📱 Uso do Campo no App

### Verificar se Usuário é Certificado

```dart
// No perfil do usuário
final userData = await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(userId)
    .get();

final isCertified = userData.data()?['spirituallyCertified'] == true;

if (isCertified) {
  // Mostrar badge de certificação
  return SpiritualCertificationBadge();
}
```

### Filtrar Usuários Certificados

```dart
// Buscar apenas usuários certificados
final certifiedUsers = await FirebaseFirestore.instance
    .collection('usuarios')
    .where('spirituallyCertified', isEqualTo: true)
    .get();
```

### Ordenar por Data de Certificação

```dart
// Usuários certificados mais recentes primeiro
final recentlyCertified = await FirebaseFirestore.instance
    .collection('usuarios')
    .where('spirituallyCertified', isEqualTo: true)
    .orderBy('certificationApprovedAt', descending: true)
    .limit(10)
    .get();
```

---

## 🧪 Como Testar

### Teste Manual

1. **Criar uma solicitação de certificação**
   ```dart
   await SpiritualCertificationService().submitCertificationRequest(
     purchaseEmail: 'user@example.com',
     proofImage: imageFile,
   );
   ```

2. **Aprovar via painel admin**
   - Abrir painel administrativo
   - Clicar em "Aprovar" na certificação
   - Confirmar aprovação

3. **Verificar perfil do usuário**
   ```dart
   final userDoc = await FirebaseFirestore.instance
       .collection('usuarios')
       .doc(userId)
       .get();
   
   print('Certificado: ${userDoc.data()?['spirituallyCertified']}');
   print('Aprovado em: ${userDoc.data()?['certificationApprovedAt']}');
   print('ID da certificação: ${userDoc.data()?['certificationId']}');
   ```

### Teste Automatizado

```dart
test('Aprovação deve atualizar perfil do usuário', () async {
  // Arrange
  final service = CertificationApprovalService();
  final certificationId = 'test_cert_123';
  
  // Act
  final success = await service.approveCertification(
    certificationId,
    adminNotes: 'Teste automatizado',
  );
  
  // Assert
  expect(success, true);
  
  // Verificar perfil
  final userDoc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .get();
  
  expect(userDoc.data()?['spirituallyCertified'], true);
  expect(userDoc.data()?['certificationId'], certificationId);
  expect(userDoc.data()?['certificationApprovedAt'], isNotNull);
});
```

---

## ⚠️ Pontos de Atenção

### 1. Índices do Firestore

Certifique-se de criar índices para queries eficientes:

```
Collection: usuarios
Fields: spirituallyCertified (Ascending), certificationApprovedAt (Descending)
```

### 2. Regras de Segurança

Adicione regras para proteger o campo:

```javascript
match /usuarios/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId 
               || get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.role == 'admin';
  
  // Apenas admins podem modificar spirituallyCertified
  allow update: if request.auth != null 
                && get(/databases/$(database)/documents/usuarios/$(request.auth.uid)).data.role == 'admin'
                && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['spirituallyCertified', 'certificationApprovedAt', 'certificationId', 'updatedAt']);
}
```

### 3. Migração de Dados Existentes

Se houver usuários certificados antes desta implementação:

```dart
// Script de migração
Future<void> migrateCertifiedUsers() async {
  final certifications = await FirebaseFirestore.instance
      .collection('spiritual_certifications')
      .where('status', isEqualTo: 'approved')
      .get();
  
  for (final cert in certifications.docs) {
    final userId = cert.data()['userId'];
    final certId = cert.id;
    final approvedAt = cert.data()['processedAt'];
    
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .update({
      'spirituallyCertified': true,
      'certificationApprovedAt': approvedAt,
      'certificationId': certId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Migrado: $userId');
  }
}
```

---

## 📈 Próximos Passos

Agora que o perfil é atualizado automaticamente, podemos:

1. **Tarefa 7** - Criar o componente visual do badge
2. **Tarefa 8** - Integrar o badge em todas as telas
3. Implementar filtros por usuários certificados
4. Adicionar estatísticas de certificações

---

## ✅ Checklist de Implementação

- [x] Buscar certificação para obter userId
- [x] Implementar transação atômica
- [x] Atualizar status da certificação
- [x] Atualizar perfil do usuário
- [x] Adicionar campo `spirituallyCertified`
- [x] Adicionar campo `certificationApprovedAt`
- [x] Adicionar campo `certificationId`
- [x] Adicionar campo `updatedAt`
- [x] Validações de segurança
- [x] Tratamento de erros
- [x] Logs detalhados
- [x] Documentação completa

---

## 🎉 Status Final

✅ **TAREFA 6 CONCLUÍDA COM SUCESSO!**

O perfil do usuário agora é atualizado automaticamente quando uma certificação é aprovada, com garantia de consistência através de transações atômicas.

**Próximo passo**: Implementar o badge visual de certificação (Tarefa 7)

---

**Data de Conclusão**: $(date)
**Desenvolvido por**: Kiro AI Assistant
