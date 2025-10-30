# 🔍 DIAGNÓSTICO: Cloud Function Email Não Dispara

## ✅ O Que Está Funcionando

1. **App Flutter**: Salvando documento corretamente
2. **Firestore**: Documento criado com ID `ngpdnlaDkDopAFQ7wiib`
3. **Log do App**: Mostra "📧 Email para admin: Nova solicitação de Usuário"

## ❌ O Que NÃO Está Funcionando

A Cloud Function **NÃO está sendo executada** (email não chega)

---

## 🎯 VERIFICAÇÕES NECESSÁRIAS

### 1️⃣ Verificar Caminho do Documento no Firestore

**AÇÃO IMEDIATA:**

1. Abra: https://console.firebase.google.com
2. Selecione projeto: `app-no-secreto-com-o-pai`
3. Vá em **Firestore Database**
4. Procure o documento: `ngpdnlaDkDopAFQ7wiib`

**Qual é o caminho completo?**
- ✅ Correto: `certification_requests/ngpdnlaDkDopAFQ7wiib`
- ❌ Errado: `certificationRequests/ngpdnlaDkDopAFQ7wiib`
- ❌ Errado: `users/{userId}/certification_requests/...`

---

### 2️⃣ Verificar Logs da Cloud Function

**No Firebase Console:**

1. Vá em **Functions** (menu lateral)
2. Clique em **Logs**
3. Procure por erros ou mensagens relacionadas a `sendCertificationRequestEmail`

**O que procurar:**
- ❌ Erros de permissão
- ❌ Erros de autenticação Gmail
- ❌ Function não aparece nos logs (não foi acionada)

---

### 3️⃣ Verificar Status do Deploy

**No terminal, execute:**

```bash
cd functions
firebase functions:log --only sendCertificationRequestEmail
```

Ou veja todas as functions:

```bash
firebase functions:list
```

**Verifique:**
- A function está deployada?
- Qual é o trigger configurado?

---

## 🔧 SOLUÇÕES POSSÍVEIS

### Solução A: Caminho Errado no Código Flutter

Se o documento está sendo salvo em caminho diferente, precisamos corrigir.

**Verificar em:** `lib/services/spiritual_certification_service.dart`

Deve ser:
```dart
await _firestore
    .collection('certification_requests')  // ← Nome correto
    .doc(requestId)
    .set(data);
```

### Solução B: Trigger da Function Errado

Se o trigger está configurado para caminho diferente.

**Verificar em:** `functions/index.js`

Deve ser:
```javascript
exports.sendCertificationRequestEmail = functions.firestore
  .document('certification_requests/{requestId}')  // ← Caminho correto
  .onCreate(async (snap, context) => {
    // ...
  });
```

### Solução C: Credenciais Gmail Inválidas

Se as credenciais do Gmail estão erradas ou expiradas.

**Verificar:**
```bash
firebase functions:config:get
```

Deve mostrar:
```json
{
  "gmail": {
    "email": "sinais.aplicativo@gmail.com",
    "password": "sua-senha-de-app"
  }
}
```

---

## 🧪 TESTE MANUAL

Crie um documento manualmente no Firestore Console:

1. Collection: `certification_requests`
2. Document ID: `teste_manual_123`
3. Campos:
   ```
   userName: "Teste Manual"
   userEmail: "teste@gmail.com"
   purchaseEmail: "compra@gmail.com"
   requestedAt: [timestamp atual]
   status: "pending"
   ```

**Se o email chegar:**
- ✅ Function funciona
- ❌ Problema é no caminho do app Flutter

**Se o email NÃO chegar:**
- ❌ Problema na function ou credenciais

---

## 📋 PRÓXIMOS PASSOS

**Me informe:**

1. **Qual o caminho completo do documento no Firestore?**
   - Exemplo: `certification_requests/ngpdnlaDkDopAFQ7wiib`

2. **O que aparece nos logs da Cloud Function?**
   - Tem erros?
   - A function foi executada?

3. **O teste manual funcionou?**
   - Email chegou?

Com essas informações, vou corrigir o problema! 🚀
