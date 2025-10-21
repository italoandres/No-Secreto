# 🔍 Diagnóstico: Email Não Recebido

## ❌ Problema
Solicitação de certificação criada com sucesso, mas email não chega em `sinais.aplicativo@gmail.com`

---

## 🎯 Causas Mais Prováveis

### **1. Cloud Functions NÃO foram deployadas** ⚠️ (MAIS PROVÁVEL)

As funções foram criadas no código, mas **não foram enviadas para o Firebase**.

**Como verificar:**
```bash
firebase functions:list
```

**Solução:**
```bash
cd functions
npm install
firebase deploy --only functions
```

---

### **2. Variáveis de ambiente NÃO configuradas** ⚠️

As credenciais do Gmail não foram configuradas no Firebase.

**Como verificar:**
```bash
firebase functions:config:get
```

**Deve mostrar:**
```json
{
  "email": {
    "user": "sinais.aplicativo@gmail.com",
    "password": "xxxx xxxx xxxx xxxx"
  }
}
```

**Solução:**
```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="SUA_SENHA_APP_AQUI"
```

---

### **3. Senha de App do Gmail NÃO gerada** ⚠️

Você precisa de uma senha específica para apps, não a senha normal do Gmail.

**Como gerar:**

1. Acesse: https://myaccount.google.com/security
2. Ative "Verificação em duas etapas" (se não estiver ativa)
3. Acesse: https://myaccount.google.com/apppasswords
4. Selecione "App": Outro (nome personalizado)
5. Digite: "Firebase Sinais"
6. Clique em "Gerar"
7. **Copie a senha de 16 caracteres** (formato: xxxx xxxx xxxx xxxx)

---

### **4. Plano Firebase não é Blaze** ⚠️

Cloud Functions só funcionam no plano Blaze (pay-as-you-go).

**Como verificar:**
1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Vá em "Upgrade" no menu lateral
4. Verifique se está no plano "Blaze"

**Solução:**
- Faça upgrade para o plano Blaze
- **Não se preocupe:** Tem 2 milhões de invocações GRÁTIS por mês
- Para certificações, provavelmente será 100% grátis

---

### **5. Firebase CLI não instalado**

**Como verificar:**
```bash
firebase --version
```

**Solução:**
```bash
npm install -g firebase-tools
firebase login
```

---

## 🚀 Solução Passo a Passo

### **PASSO 1: Verificar se Functions existem no Firebase**

```bash
firebase functions:list
```

**Se mostrar erro ou lista vazia:**
- As functions NÃO foram deployadas
- Prossiga para o PASSO 2

**Se mostrar as 3 functions:**
- `sendCertificationRequestEmail`
- `sendCertificationApprovalEmail`
- Prossiga para o PASSO 3

---

### **PASSO 2: Deploy das Functions**

```bash
# 1. Entre na pasta functions
cd functions

# 2. Instale dependências
npm install

# 3. Volte para raiz do projeto
cd ..

# 4. Deploy
firebase deploy --only functions
```

**Aguarde:** O deploy pode levar 2-5 minutos.

**Sucesso quando ver:**
```
✔  functions: Finished running predeploy script.
✔  functions[sendCertificationRequestEmail(us-central1)]: Successful create operation.
✔  functions[sendCertificationApprovalEmail(us-central1)]: Successful create operation.
```

---

### **PASSO 3: Configurar Credenciais do Gmail**

#### **3.1. Gerar Senha de App**

1. Acesse: https://myaccount.google.com/security
2. Ative "Verificação em duas etapas"
3. Acesse: https://myaccount.google.com/apppasswords
4. Gere senha para "Firebase Sinais"
5. **Copie a senha** (ex: `abcd efgh ijkl mnop`)

#### **3.2. Configurar no Firebase**

```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="abcd efgh ijkl mnop"
```

**Substitua** `abcd efgh ijkl mnop` pela senha que você copiou.

#### **3.3. Re-deploy (necessário após configurar)**

```bash
firebase deploy --only functions
```

---

### **PASSO 4: Testar**

1. Abra o app
2. Crie uma nova solicitação de certificação
3. Aguarde 10-30 segundos
4. Verifique o email `sinais.aplicativo@gmail.com`
5. **Verifique também a pasta SPAM**

---

### **PASSO 5: Verificar Logs (se não funcionar)**

```bash
firebase functions:log
```

**Procure por:**
- ✅ `📧 Nova solicitação de certificação:`
- ✅ `✅ Email enviado com sucesso para:`
- ❌ `❌ Erro ao enviar email:`

---

## 🔍 Comandos de Diagnóstico

### **Ver configurações atuais:**
```bash
firebase functions:config:get
```

### **Ver functions deployadas:**
```bash
firebase functions:list
```

### **Ver logs em tempo real:**
```bash
firebase functions:log --only sendCertificationRequestEmail
```

### **Ver projeto atual:**
```bash
firebase projects:list
```

---

## 📊 Checklist de Verificação

Execute cada item e marque:

- [ ] **Firebase CLI instalado:** `firebase --version`
- [ ] **Login feito:** `firebase login`
- [ ] **Projeto correto:** `firebase use --add`
- [ ] **Plano Blaze ativo:** Verificar no console
- [ ] **Pasta functions existe:** `ls functions/`
- [ ] **Dependências instaladas:** `cd functions && npm install`
- [ ] **Functions deployadas:** `firebase deploy --only functions`
- [ ] **Senha de app gerada:** https://myaccount.google.com/apppasswords
- [ ] **Variáveis configuradas:** `firebase functions:config:get`
- [ ] **Re-deploy após config:** `firebase deploy --only functions`
- [ ] **Teste realizado:** Criar solicitação no app
- [ ] **Logs verificados:** `firebase functions:log`

---

## 🎯 Teste Rápido

Execute este comando para ver se as functions estão ativas:

```bash
firebase functions:list
```

**Resultado esperado:**
```
┌─────────────────────────────────────┬────────────┐
│ Function Name                       │ Status     │
├─────────────────────────────────────┼────────────┤
│ sendCertificationRequestEmail       │ ACTIVE     │
│ sendCertificationApprovalEmail      │ ACTIVE     │
└─────────────────────────────────────┴────────────┘
```

**Se não aparecer nada ou der erro:**
- As functions NÃO foram deployadas
- Execute: `firebase deploy --only functions`

---

## 💡 Dica Importante

Após configurar as variáveis de ambiente (`email.user` e `email.password`), você **DEVE** fazer re-deploy:

```bash
firebase deploy --only functions
```

Sem o re-deploy, as functions não terão acesso às credenciais!

---

## 🆘 Ainda não funciona?

Execute e me envie o resultado:

```bash
# 1. Ver functions
firebase functions:list

# 2. Ver configurações
firebase functions:config:get

# 3. Ver logs
firebase functions:log --limit 50
```

---

## ✅ Quando Funcionar

Você verá:

1. **No console do Firebase:**
   - Logs mostrando "📧 Nova solicitação de certificação"
   - "✅ Email enviado com sucesso"

2. **No email:**
   - Email bonito com HTML
   - Informações da solicitação
   - Link para o comprovante

3. **Tempo de entrega:**
   - Geralmente 10-30 segundos após criar a solicitação

---

**Comece pelo PASSO 1 e vá seguindo em ordem! 🚀**
