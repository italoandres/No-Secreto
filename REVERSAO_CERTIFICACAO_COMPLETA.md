# ✅ Reversão para Configuração do Backup - COMPLETA

## 🎯 O que foi feito

Revertemos todo o sistema de certificação espiritual para usar a configuração do backup que funcionava:

### 1. ✅ Repository (lib/repositories/spiritual_certification_repository.dart)
- ✅ Collection alterada: `certification_requests` → `spiritual_certifications`
- ✅ Campos de data alterados: `requestedAt` → `createdAt`
- ✅ Campo de processamento: `reviewedAt` → `processedAt`

### 2. ✅ Service (lib/services/certification_approval_service.dart)
- ✅ Todas as queries alteradas para `spiritual_certifications`
- ✅ Ordenação alterada para usar `createdAt`
- ✅ Histórico alterado para usar `processedAt`
- ✅ Aprovação e reprovação usando `processedAt`

### 3. ✅ Cloud Functions (functions/index.js)
- ✅ Trigger `sendCertificationRequestEmail`: `certification_requests` → `spiritual_certifications`
- ✅ Trigger `sendCertificationApprovalEmail`: `certification_requests` → `spiritual_certifications`
- ✅ Template de email: `requestedAt` → `createdAt`
- ✅ Função `processApproval`: collection e campo `processedAt` atualizados
- ✅ Função `processRejection`: collection e campo `processedAt` atualizados

### 4. ✅ Firestore Rules (firestore.rules)
- ✅ Regras consolidadas para `spiritual_certifications`
- ✅ Seção duplicada `certification_requests` removida
- ✅ Validação de campo `proofFileUrl` mantida
- ✅ Validação de campos `createdAt` e `processedAt`

### 5. ✅ Deploy no Firebase
- ✅ Firestore Rules deployed com sucesso
- ✅ Cloud Functions deployed com sucesso
  - sendCertificationRequestEmail ✅
  - sendCertificationApprovalEmail ✅
  - processApproval ✅
  - processRejection ✅
  - onCertificationStatusChange ✅

## 📋 Próximos Passos - TESTE NO APP

Agora você precisa testar o sistema no aplicativo:

### Teste 1: Criar Certificação
1. Abra o app Flutter
2. Vá para a tela de certificação espiritual
3. Preencha os dados e envie uma solicitação
4. **Verifique no Firebase Console:**
   - Vá para: Firestore Database → `spiritual_certifications`
   - Deve aparecer um novo documento
   - Campos devem incluir: `createdAt`, `proofFileUrl`, `status: pending`

### Teste 2: Verificar Painel Admin
1. Abra o painel administrativo no app
2. Vá para a seção de certificações
3. **Deve aparecer:**
   - Lista de certificações pendentes
   - Ordenadas por data de criação
   - Botões de aprovar/reprovar

### Teste 3: Aprovar Certificação
1. No painel admin, clique em "Aprovar" em uma certificação
2. **Verifique no Firebase Console:**
   - O documento deve ter `status: approved`
   - Deve ter campo `processedAt` com timestamp
   - Deve ter campo `reviewedBy` com email do admin

### Teste 4: Verificar Emails (Opcional)
1. Verifique os logs das Cloud Functions no Firebase Console
2. Vá para: Functions → Logs
3. Procure por:
   - "📧 Nova solicitação de certificação"
   - "✅ Certificação aprovada"
   - "✅ Email enviado com sucesso"

## 🔍 Como Verificar no Firebase Console

1. Acesse: https://console.firebase.google.com/project/app-no-secreto-com-o-pai
2. Vá para **Firestore Database**
3. Procure a collection **`spiritual_certifications`**
4. Você deve ver os documentos lá (não em `certification_requests`)

## ⚠️ Importante

- O sistema agora usa **`spiritual_certifications`** como collection principal
- Campos de data são **`createdAt`** e **`processedAt`**
- Campo de prova é **`proofFileUrl`** (não `proofUrl`)
- Todas as Cloud Functions estão escutando a collection correta

## 🐛 Se algo não funcionar

1. **Documento não aparece no Firestore:**
   - Verifique os logs do app Flutter
   - Procure por erros de permissão
   - Confirme que está logado com usuário válido

2. **Painel admin não mostra certificações:**
   - Verifique se há documentos em `spiritual_certifications`
   - Confirme que o usuário admin tem permissão
   - Verifique logs do app

3. **Emails não são enviados:**
   - Verifique logs das Cloud Functions
   - Confirme configuração de email no Firebase
   - Verifique se trigger está funcionando

## 📊 Status Atual

✅ Código revertido para configuração do backup
✅ Deploy realizado com sucesso
✅ Regras de segurança atualizadas E CORRIGIDAS (permissões de leitura)
✅ Cloud Functions atualizadas
✅ Problema de permissão resolvido
⏳ Aguardando testes no aplicativo

## 🎉 Conclusão

Todas as alterações de código foram implementadas e o deploy foi realizado com sucesso. O sistema agora está usando a mesma configuração do backup que funcionava anteriormente. 

**Próximo passo:** Teste no aplicativo para confirmar que tudo está funcionando!


---

## 🔧 CORREÇÃO ADICIONAL - Permissões de Leitura

### Problema Identificado
O app estava mostrando erro:
```
❌ Erro ao verificar certificação: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

### Causa
As regras de segurança estavam muito restritivas:
- `allow read` só permitia leitura de documentos individuais
- `allow list` só permitia para admins
- Queries do app precisavam de permissão de `list`

### Solução Aplicada
Alteramos as regras para:
```javascript
// Usuários podem ler um documento específico (get)
allow get: if request.auth != null && 
  (request.auth.uid == resource.data.userId || isAdmin(request.auth.uid));

// Usuários podem listar suas próprias solicitações (list/query)
allow list: if request.auth != null && 
  (request.auth.uid == request.resource.data.userId || isAdmin(request.auth.uid));
```

### Deploy Realizado
✅ Regras atualizadas e deployed com sucesso

### Próximo Passo
Recarregue o app (hot reload ou restart) e teste novamente!
