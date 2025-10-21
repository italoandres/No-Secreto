# ✅ Verificação Completa - Firebase Cloud Functions

## 🎯 Execute Estes Comandos em Ordem

Copie e cole cada comando no terminal e me envie o resultado.

---

## **1️⃣ Verificar Firebase CLI**

```powershell
firebase --version
```

**Esperado:** Versão 12.x.x ou superior

---

## **2️⃣ Verificar Login**

```powershell
firebase login:list
```

**Esperado:** Mostrar seu email do Google

---

## **3️⃣ Verificar Projeto Ativo**

```powershell
firebase use
```

**Esperado:** Mostrar o projeto ativo (ex: `app-no-secreto-com-o-pai`)

---

## **4️⃣ Listar Functions Deployadas** ⚠️ CRÍTICO

```powershell
firebase functions:list
```

**✅ SUCESSO se mostrar:**
```
┌─────────────────────────────────────┬────────────┐
│ Function Name                       │ Status     │
├─────────────────────────────────────┼────────────┤
│ sendCertificationRequestEmail       │ ACTIVE     │
│ sendCertificationApprovalEmail      │ ACTIVE     │
└─────────────────────────────────────┴────────────┘
```

**❌ PROBLEMA se:**
- Lista vazia
- Erro "No functions deployed"
- Não mostra as 2 functions

---

## **5️⃣ Verificar Configurações de Email** ⚠️ CRÍTICO

```powershell
firebase functions:config:get
```

**✅ SUCESSO se mostrar:**
```json
{
  "email": {
    "user": "sinais.aplicativo@gmail.com",
    "password": "xxxx xxxx xxxx xxxx"
  }
}
```

**❌ PROBLEMA se:**
- Vazio: `{}`
- Sem a chave "email"
- Password está vazio

---

## **6️⃣ Ver Logs Recentes** ⚠️ CRÍTICO

```powershell
firebase functions:log --limit 20
```

**Procure por:**
- ✅ `📧 Nova solicitação de certificação`
- ✅ `✅ Email enviado com sucesso`
- ❌ `❌ Erro ao enviar email`
- ❌ `Invalid login credentials`
- ❌ `Error: getaddrinfo ENOTFOUND`

---

## **7️⃣ Verificar Plano Firebase**

1. Abra: https://console.firebase.google.com
2. Selecione seu projeto: `app-no-secreto-com-o-pai`
3. Clique em "⚙️" (engrenagem) → "Configurações do projeto"
4. Vá em "Uso e faturamento"
5. Verifique se está no **Plano Blaze** (não Spark)

---

## 📊 Análise dos Resultados

### **Se o comando 4 (functions:list) mostrar lista vazia:**

**Problema:** Functions NÃO foram deployadas

**Solução:**
```powershell
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

### **Se o comando 5 (config:get) mostrar vazio:**

**Problema:** Credenciais do Gmail NÃO foram configuradas

**Solução:**

1. **Gerar senha de app:**
   - Acesse: https://myaccount.google.com/apppasswords
   - Gere senha para "Firebase Sinais"
   - Copie a senha (16 caracteres)

2. **Configurar:**
```powershell
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="COLE_A_SENHA_AQUI"
```

3. **Re-deploy (OBRIGATÓRIO):**
```powershell
firebase deploy --only functions
```

---

### **Se o comando 6 (logs) mostrar erro:**

**Erros comuns:**

1. **"Invalid login credentials"**
   - Senha de app incorreta
   - Solução: Gerar nova senha e reconfigurar

2. **"Error: getaddrinfo ENOTFOUND"**
   - Problema de rede
   - Solução: Verificar conexão com internet

3. **"Insufficient permissions"**
   - Problema de permissões
   - Solução: `firebase deploy --only functions --force`

---

## 🎯 Comandos Resumidos

Execute todos de uma vez e me envie o resultado:

```powershell
Write-Host "=== VERIFICACAO FIREBASE ===" -ForegroundColor Green
Write-Host ""
Write-Host "1. Versao CLI:" -ForegroundColor Yellow
firebase --version
Write-Host ""
Write-Host "2. Usuario logado:" -ForegroundColor Yellow
firebase login:list
Write-Host ""
Write-Host "3. Projeto ativo:" -ForegroundColor Yellow
firebase use
Write-Host ""
Write-Host "4. Functions deployadas:" -ForegroundColor Yellow
firebase functions:list
Write-Host ""
Write-Host "5. Configuracoes de email:" -ForegroundColor Yellow
firebase functions:config:get
Write-Host ""
Write-Host "6. Logs recentes:" -ForegroundColor Yellow
firebase functions:log --limit 10
```

---

## 💡 Dica Importante

Baseado no seu log do app:

```
📧 Email para admin: Nova solicitação de Usuário
Request ID: zg2lc9l9sxTe9X390dqg
```

O app está tentando enviar o email, mas:
- Se as functions não estão deployadas → Email não é enviado
- Se as credenciais não estão configuradas → Email falha

---

## 🆘 Me Envie

Execute os comandos acima e me envie:

1. Resultado do comando 4 (`firebase functions:list`)
2. Resultado do comando 5 (`firebase functions:config:get`)
3. Resultado do comando 6 (`firebase functions:log --limit 20`)

Com isso vou saber exatamente o que está faltando! 🔍
