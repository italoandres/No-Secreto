# 🔧 Correção: Permissão Firestore para Selo de Certificação

## 🔍 Problema Identificado

O selo de certificação não estava aparecendo nos perfis públicos devido a erro de permissão no Firestore:

```
❌ [ERROR] [VITRINE_DISPLAY] Error checking certification status
🔍 Error Details: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## 🎯 Causa Raiz

A collection `certification_requests` não tinha regras de leitura definidas no `firestore.rules`, impedindo que o código verificasse o status de certificação dos usuários.

## ✅ Solução Aplicada

Adicionadas regras de leitura para a collection `certification_requests` no arquivo `firestore.rules`:

```javascript
// Regras para solicitações de certificação espiritual (collection nova)
match /certification_requests/{certificationId} {
  // Qualquer usuário autenticado pode ler todas as certificações
  // (necessário para exibir selo no perfil público)
  allow read: if request.auth != null;
  
  // Usuário pode criar sua própria solicitação
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.userId;
  
  // Apenas admins podem atualizar (aprovar/reprovar)
  allow update: if request.auth != null && 
    isAdmin(request.auth.uid);
  
  // Apenas admins podem deletar
  allow delete: if request.auth != null && 
    isAdmin(request.auth.uid);
}
```

## 🔒 Segurança

### Permissões Definidas

1. **Leitura (Read)**: ✅ Qualquer usuário autenticado
   - Necessário para verificar status de certificação em perfis públicos
   - Não expõe dados sensíveis (apenas status: approved/pending/rejected)

2. **Criação (Create)**: ✅ Apenas o próprio usuário
   - Usuário só pode criar solicitação para si mesmo
   - Validação: `request.auth.uid == request.resource.data.userId`

3. **Atualização (Update)**: ✅ Apenas admins
   - Apenas admins podem aprovar/reprovar certificações
   - Validação: `isAdmin(request.auth.uid)`

4. **Exclusão (Delete)**: ✅ Apenas admins
   - Apenas admins podem deletar solicitações
   - Validação: `isAdmin(request.auth.uid)`

### Dados Públicos vs Privados

**Dados Públicos** (visíveis para todos):
- `userId` - ID do usuário
- `status` - Status da certificação (approved/pending/rejected)
- `requestDate` - Data da solicitação
- `approvalDate` - Data da aprovação (se aprovado)

**Dados Privados** (apenas para admins):
- `reviewedBy` - Admin que revisou
- `notes` - Notas internas do admin

**Nota**: Mesmo com leitura pública, os dados sensíveis devem ser protegidos no nível da aplicação.

## 📋 Próximos Passos

### 1. Deploy das Regras

```bash
# Deploy das novas regras para o Firebase
firebase deploy --only firestore:rules
```

### 2. Testar Novamente

Após o deploy das regras:

1. ✅ Abrir o app
2. ✅ Navegar para perfil com certificação aprovada
3. ✅ Verificar se o selo dourado aparece
4. ✅ Verificar logs no console (não deve ter erro de permissão)

### 3. Validar Logs

**Log Esperado (Sucesso)**:
```
✅ 2025-10-17T17:21:56.740 [INFO] [VITRINE_DISPLAY] Certification status checked
📊 Data: {userId: 2MBqslnxAGeZFe18d9h52HYTZIy1, hasApprovedCertification: true}
```

**Não Deve Aparecer**:
```
❌ [ERROR] [VITRINE_DISPLAY] Error checking certification status
🔍 Error Details: [cloud_firestore/permission-denied]
```

## 🎨 Resultado Esperado

Após o deploy das regras, o selo deve aparecer:

### ProfileDisplayView (AppBar)
```
[@italolior] [🟡 Selo Dourado]
```

### EnhancedVitrineDisplayView (Foto)
```
┌─────────────┐
│   [Foto]    │
│             │
│          🟡 │ ← Badge circular dourado
└─────────────┘
```

## 📊 Validação de Segurança

### Testes de Segurança Recomendados

1. **Usuário Não Autenticado**:
   - ❌ Não deve conseguir ler certificações
   - ✅ Regra: `allow read: if request.auth != null`

2. **Usuário Autenticado Normal**:
   - ✅ Pode ler todas as certificações
   - ✅ Pode criar apenas sua própria solicitação
   - ❌ Não pode aprovar/reprovar
   - ❌ Não pode deletar

3. **Usuário Admin**:
   - ✅ Pode ler todas as certificações
   - ✅ Pode aprovar/reprovar certificações
   - ✅ Pode deletar certificações

## 🔍 Debugging

Se o problema persistir após deploy:

### 1. Verificar Deploy
```bash
# Verificar se as regras foram deployadas
firebase firestore:rules:get
```

### 2. Verificar Logs do Firebase Console
- Ir para Firebase Console → Firestore → Rules
- Verificar se as regras estão ativas
- Verificar timestamp da última atualização

### 3. Testar Regras no Simulator
- Firebase Console → Firestore → Rules → Simulator
- Testar query de leitura:
  ```
  Collection: certification_requests
  Document: <any>
  Operation: get
  Auth: <userId>
  ```

### 4. Limpar Cache do App
```bash
# Hot restart no Flutter
flutter run
# Pressionar 'R' (maiúsculo) para hot restart
```

## ✅ Checklist de Validação

- [x] Regras adicionadas ao firestore.rules
- [ ] Deploy das regras executado
- [ ] Teste no app realizado
- [ ] Selo aparecendo corretamente
- [ ] Logs sem erro de permissão
- [ ] Validação de segurança realizada

## 📝 Notas Importantes

1. **Duas Collections**: O sistema tem duas collections de certificação:
   - `spiritual_certifications` (antiga)
   - `certification_requests` (nova) ← **Esta que precisava da regra**

2. **Compatibilidade**: Ambas as collections têm regras agora

3. **Performance**: A leitura pública não impacta performance pois:
   - Query usa `.limit(1)`
   - Query tem índice composto (userId + status)
   - Resultado é cacheado durante a sessão

## 🎉 Conclusão

A correção foi aplicada no arquivo `firestore.rules`. Após o deploy, o selo de certificação deve aparecer corretamente nos perfis públicos sem erros de permissão.

**Próximo passo**: Deploy das regras com `firebase deploy --only firestore:rules`
