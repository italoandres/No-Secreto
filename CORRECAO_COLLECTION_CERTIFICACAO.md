# 🔧 CORREÇÃO CRÍTICA - Collection de Certificação

## ❌ O Problema Encontrado

O sistema estava salvando e escutando em **collections diferentes**:

### Flutter (App) salvava em:
```dart
static const String _collectionName = 'certification_requests';
```

### Cloud Functions escutavam em:
```javascript
.document("spiritual_certifications/{requestId}")
```

**Resultado:** Nada funcionava porque eram collections diferentes! 😱

---

## ✅ Correção Aplicada

Todas as Cloud Functions foram corrigidas para escutar a collection correta:

### 1. sendCertificationRequestEmail
```javascript
// ANTES
.document("spiritual_certifications/{requestId}")

// DEPOIS
.document("certification_requests/{requestId}")
```

### 2. sendCertificationApprovalEmail
```javascript
// ANTES
.document("spiritual_certifications/{requestId}")

// DEPOIS
.document("certification_requests/{requestId}")
```

### 3. processApproval
```javascript
// ANTES
.collection("spiritual_certifications")

// DEPOIS
.collection("certification_requests")
```

### 4. processRejection
```javascript
// ANTES
.collection("spiritual_certifications")

// DEPOIS
.collection("certification_requests")
```

---

## 🚀 Deploy Realizado

```bash
firebase deploy --only functions
```

**Status:** ✅ Deploy completo com sucesso!

**Functions atualizadas:**
- ✅ sendCertificationRequestEmail
- ✅ sendCertificationApprovalEmail
- ✅ processApproval
- ✅ processRejection
- ✅ onCertificationStatusChange

---

## 🧪 Como Testar Agora

### 1. Limpar dados antigos (se houver)
No Firebase Console, verifique se existe algum documento em `spiritual_certifications` e delete.

### 2. Fazer nova solicitação no app
1. Abra o app
2. Vá em Certificação Espiritual
3. Preencha o formulário
4. Envie a solicitação

### 3. Verificar no Firebase Console

**Firestore:**
```
certification_requests/
  └── {requestId}/
      ├── userId: "..."
      ├── userName: "..."
      ├── userEmail: "..."
      ├── purchaseEmail: "..."
      ├── status: "pending"
      ├── requestedAt: timestamp
      └── proofFileUrl: "..."
```

**Email:**
- Deve chegar em: `sinais.aplicativo@gmail.com`
- Assunto: "🏆 Nova Solicitação de Certificação Espiritual"
- Com botões de Aprovar/Reprovar

---

## 📊 Logs para Monitorar

No Firebase Console > Functions > Logs, procure por:

```
📧 Nova solicitação de certificação: {requestId}
✅ Email enviado com sucesso para: sinais.aplicativo@gmail.com
```

Se aparecer erro:
```
❌ Erro ao enviar email: [detalhes do erro]
```

---

## 🔍 Checklist de Verificação

- [x] Collection corrigida no código
- [x] Cloud Functions atualizadas
- [x] Deploy realizado com sucesso
- [ ] Teste real no app
- [ ] Documento aparece no Firestore
- [ ] Email chega no admin

---

## 💡 Próximos Passos

1. **Teste agora mesmo** fazendo uma nova solicitação
2. **Verifique o Firestore** se o documento foi criado em `certification_requests`
3. **Confira o email** em `sinais.aplicativo@gmail.com`
4. **Monitore os logs** no Firebase Console

---

## 🎯 O Que Esperar

Quando você enviar uma solicitação:

1. ✅ Documento salvo em `certification_requests`
2. ✅ Cloud Function disparada automaticamente
3. ✅ Email enviado para admin
4. ✅ Logs aparecem no Firebase Console

**Agora sim vai funcionar!** 🚀
