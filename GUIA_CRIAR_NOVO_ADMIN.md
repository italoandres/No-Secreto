# 🔐 GUIA: Como Criar Novo Admin

**Data:** 22/10/2025  
**Objetivo:** Criar um novo usuário admin para substituir italolior@gmail.com

---

## 📍 PASSO 1: Criar Conta no App

### 1.1 Abrir o App
- Abra seu aplicativo
- Se estiver logado, faça logout

### 1.2 Criar Nova Conta
- Clique em "Criar Conta" ou "Sign Up"
- Use um email novo, por exemplo:
  - `admin@seuapp.com`
  - `admin.novo@gmail.com`
  - Ou qualquer email que você tenha acesso

### 1.3 Completar Cadastro
- Preencha todos os dados necessários
- Complete o perfil
- **IMPORTANTE:** Anote o email usado!

---

## 📍 PASSO 2: Tornar Admin no Firebase Console

### 2.1 Abrir Firebase Console
1. Acesse: https://console.firebase.google.com/
2. Selecione seu projeto
3. No menu lateral, clique em **"Firestore Database"**

### 2.2 Encontrar o Usuário
1. Na lista de collections, clique em **`usuarios`**
2. Você verá uma lista de documentos (cada um é um usuário)
3. Procure pelo email que você acabou de criar
   - Dica: Use Ctrl+F para buscar pelo email

### 2.3 Editar o Documento
1. Clique no documento do usuário
2. Procure o campo **`isAdmin`**
   - Se não existir, você vai criar

### 2.4 Adicionar/Editar Campo isAdmin

**Se o campo JÁ EXISTE:**
1. Clique no valor atual (provavelmente `false`)
2. Mude para `true`
3. Clique em "Update" ou "Atualizar"

**Se o campo NÃO EXISTE:**
1. Clique em **"Add field"** ou **"Adicionar campo"**
2. Preencha:
   - **Field name:** `isAdmin`
   - **Type:** `boolean`
   - **Value:** `true` (marque o checkbox)
3. Clique em "Add" ou "Adicionar"

### 2.5 Verificar
- O documento deve ter agora: `isAdmin: true`
- Pronto! O usuário é admin agora

---

## 📍 PASSO 3: Testar Novo Admin

### 3.1 Fazer Login
- Abra o app
- Faça login com o novo email admin

### 3.2 Verificar Permissões Admin
Você deve ver:
- ✅ Botão de menu admin (ícone de engrenagem ou admin)
- ✅ Acesso ao painel de certificações
- ✅ Botões extras na tela principal

### 3.3 Se NÃO Aparecer
- Feche o app completamente
- Abra novamente
- Se ainda não funcionar, verifique o Firestore novamente

---

## 📍 PASSO 4: Backup do Admin Antigo (Opcional)

### 4.1 Manter italolior@gmail.com como Admin
Se quiser manter o admin antigo também:
- Não precisa fazer nada
- Ambos podem ser admin ao mesmo tempo

### 4.2 Remover italolior@gmail.com como Admin
Se quiser remover:
1. Vá no Firestore
2. Encontre o documento de `italolior@gmail.com`
3. Mude `isAdmin` para `false`

---

## 🎯 RESUMO VISUAL

```
┌─────────────────────────────────────┐
│  1. Criar conta no app              │
│     Email: admin@seuapp.com         │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  2. Firebase Console                │
│     → Firestore Database            │
│     → Collection: usuarios          │
│     → Encontrar documento           │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  3. Editar documento                │
│     Campo: isAdmin                  │
│     Tipo: boolean                   │
│     Valor: true                     │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  4. Testar no app                   │
│     Login com novo admin            │
│     Verificar permissões            │
└─────────────────────────────────────┘
```

---

## ⚠️ TROUBLESHOOTING

### Problema: Não encontro o campo isAdmin
**Solução:** Crie o campo manualmente (veja Passo 2.4)

### Problema: Mudei para true mas não funciona
**Solução:** 
1. Feche o app completamente
2. Limpe o cache (se possível)
3. Abra novamente

### Problema: Não encontro meu usuário no Firestore
**Solução:**
1. Verifique se completou o cadastro no app
2. Procure pelo email exato
3. Verifique se está na collection `usuarios` (não `users`)

### Problema: Firebase Console não abre
**Solução:**
1. Verifique sua conexão com internet
2. Tente outro navegador
3. Limpe cache do navegador

---

## 📧 EMAILS RECOMENDADOS PARA ADMIN

Sugestões de emails para usar:
- `admin@seuapp.com` (se tiver domínio próprio)
- `admin.principal@gmail.com`
- `seu.nome.admin@gmail.com`
- `admin.dev@gmail.com`

**Dica:** Use um email que você tenha acesso fácil!

---

## ✅ CHECKLIST

Antes de prosseguir para a limpeza, confirme:

- [ ] Criei nova conta no app
- [ ] Anotei o email usado
- [ ] Abri Firebase Console
- [ ] Encontrei o documento do usuário
- [ ] Adicionei/editei campo `isAdmin: true`
- [ ] Testei login com novo admin
- [ ] Vejo botões/menus de admin no app
- [ ] Tenho acesso ao painel de certificações

---

## 🎉 PRÓXIMOS PASSOS

Depois de criar o novo admin:
1. ✅ Confirme que tudo funciona
2. ✅ Anote o email do novo admin
3. ✅ Avise que está pronto para a limpeza
4. ➡️ Vamos para o PASSO 2: Limpar dados antigos

---

**Criado por:** Kiro  
**Última atualização:** 22/10/2025

**Dúvidas?** Me chame que eu te ajudo! 🚀
