# 🚀 COMANDO PARA FORÇAR ADMIN

**SOLUÇÃO MAIS SIMPLES POSSÍVEL**

---

## ✅ EXECUTE ESTE COMANDO NO FIREBASE CONSOLE

### Passo 1: Abrir Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Selecione seu projeto
3. No menu lateral, clique em **"Firestore Database"**

### Passo 2: Encontrar o Usuário

1. Clique na collection **`usuarios`**
2. Procure pelo documento com email `deusepaimovement@gmail.com`
   - Use Ctrl+F para buscar mais rápido
3. Clique no documento para abri-lo

### Passo 3: Editar o Campo isAdmin

**OPÇÃO A: Se o campo `isAdmin` JÁ EXISTE:**
1. Clique no valor atual (provavelmente `false`)
2. Mude para `true`
3. Clique em **"Update"**

**OPÇÃO B: Se o campo `isAdmin` NÃO EXISTE:**
1. Clique em **"Add field"**
2. Preencha:
   - **Field name:** `isAdmin`
   - **Type:** `boolean`
   - **Value:** `true` (marque o checkbox)
3. Clique em **"Add"**

### Passo 4: Testar

1. Faça **logout** do app
2. Faça **login** com `deusepaimovement@gmail.com`
3. **PRONTO!** Você é admin! 🎉

---

## 🎯 ALTERNATIVA: Usar italolior@gmail.com

Se você não conseguir fazer `deusepaimovement@gmail.com` funcionar, simplesmente:

1. **Use `italolior@gmail.com` como admin**
   - Esse email JÁ está configurado no código
   - JÁ funciona automaticamente
   - Não precisa fazer nada!

2. **Não precisa criar novo admin**
   - Mantenha italolior como admin principal
   - Crie novos usuários de teste quando precisar

---

## 💡 POR QUE ISSO É MAIS SIMPLES

Fazer manualmente no Firebase Console:
- ✅ Funciona 100% das vezes
- ✅ Não depende de código
- ✅ Não precisa recompilar
- ✅ Leva 30 segundos

Fazer via código:
- ❌ Precisa recompilar
- ❌ Pode ter cache
- ❌ Pode ter problemas de timing
- ❌ Mais complexo

---

## 🎉 RECOMENDAÇÃO FINAL

**OPÇÃO 1 (MAIS SIMPLES):**
Use `italolior@gmail.com` como admin. Já funciona!

**OPÇÃO 2 (SE REALMENTE PRECISA):**
Edite manualmente no Firebase Console (passos acima)

**OPÇÃO 3 (ÚLTIMA ALTERNATIVA):**
Podemos continuar tentando via código, mas vai demorar mais

---

**Qual opção você prefere?**

1. Usar italolior@gmail.com (mais rápido)
2. Editar manualmente no Firebase (30 segundos)
3. Continuar tentando via código (mais demorado)

Me avise e eu te ajudo! 🚀
