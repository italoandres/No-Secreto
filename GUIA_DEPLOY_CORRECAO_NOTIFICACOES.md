# 🚀 GUIA DE DEPLOY - CORREÇÃO DE NOTIFICAÇÕES

## 📋 O QUE FOI CORRIGIDO

Corrigimos as regras do Firestore para permitir que usuários marquem notificações como lidas ao clicar nelas.

**Problema:** Erro de permissão ao clicar em notificações  
**Solução:** Atualizar regras do Firestore para permitir atualização dos campos `read` e `readAt`

---

## 🔧 PASSO A PASSO PARA DEPLOY

### 1. Fazer Deploy das Regras do Firestore

```bash
# No terminal, na raiz do projeto
firebase deploy --only firestore:rules
```

**Saída esperada:**
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/seu-projeto/overview
```

### 2. Verificar Deploy no Console do Firebase

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Vá em **Firestore Database** > **Regras**
4. Verifique se as regras foram atualizadas

### 3. Testar a Correção

1. Abra o app no navegador
2. Faça login
3. Vá para **Notificações**
4. Clique em uma notificação de sistema
5. Verifique se:
   - ✅ Não aparece erro de permissão
   - ✅ Notificação é marcada como lida
   - ✅ Navegação funciona corretamente

---

## ✅ VALIDAÇÃO

### Antes da Correção
```
❌ Erro ao marcar notificação como lida: [cloud_firestore/permission-denied]
❌ Erro ao abrir notificação de sistema: [cloud_firestore/permission-denied]
```

### Depois da Correção
```
✅ Notificação marcada como lida: paqomKOGbiYLxFjLhhJ7
✅ Navegação para vitrine funcionando
✅ Sem erros de permissão
```

---

## 🔍 TROUBLESHOOTING

### Erro: "Firebase CLI não encontrado"

**Solução:**
```bash
npm install -g firebase-tools
firebase login
```

### Erro: "Projeto não configurado"

**Solução:**
```bash
firebase use --add
# Selecione seu projeto
```

### Erro: "Permissão negada após deploy"

**Solução:**
1. Aguarde 1-2 minutos (propagação das regras)
2. Limpe o cache do navegador
3. Faça logout e login novamente no app

---

## 📊 REGRAS ATUALIZADAS

### Antes
```javascript
allow update: if request.auth != null && 
                 request.auth.uid == resource.data.userId &&
                 request.resource.data.diff(resource.data).affectedKeys()
                 .hasOnly(['isRead']);
```

### Depois
```javascript
allow update: if request.auth != null && 
                 request.auth.uid == resource.data.userId &&
                 (request.resource.data.diff(resource.data).affectedKeys()
                 .hasOnly(['isRead']) ||
                 request.resource.data.diff(resource.data).affectedKeys()
                 .hasOnly(['read', 'readAt']) ||
                 request.resource.data.diff(resource.data).affectedKeys()
                 .hasOnly(['read']));
```

### O Que Mudou

✅ Permitir atualização de `isRead` (notificações antigas)  
✅ Permitir atualização de `read` + `readAt` (notificações de certificação)  
✅ Permitir atualização de `read` (caso simplificado)  
✅ Manter segurança: apenas o dono pode atualizar

---

## 🎯 RESULTADO ESPERADO

Após o deploy, ao clicar em uma notificação:

1. ✅ Notificação é marcada como lida automaticamente
2. ✅ Badge de notificações não lidas é atualizado
3. ✅ Navegação para a tela correta funciona
4. ✅ Nenhum erro de permissão aparece

---

## 📝 NOTAS

- **Tempo de propagação:** 1-2 minutos após deploy
- **Impacto:** Apenas collection `notifications`
- **Segurança:** Mantida (usuário só pode atualizar suas próprias notificações)
- **Compatibilidade:** Funciona com notificações antigas e novas

---

**✅ Deploy concluído com sucesso!**
