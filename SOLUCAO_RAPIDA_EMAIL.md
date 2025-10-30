# ⚡ Solução Rápida - Email Não Chega

## 🎯 Problema
Certificação criada, mas email não chega em `sinais.aplicativo@gmail.com`

---

## ✅ Solução em 3 Passos

### **PASSO 1: Deploy das Functions** (2 minutos)

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

**Aguarde:** 2-5 minutos para completar

**Sucesso quando ver:**
```
✔  functions[sendCertificationRequestEmail]: Successful create operation
✔  functions[sendCertificationApprovalEmail]: Successful create operation
```

---

### **PASSO 2: Configurar Gmail** (3 minutos)

#### **2.1. Gerar Senha de App**

1. Abra: https://myaccount.google.com/apppasswords
2. Se pedir, ative "Verificação em 2 etapas" primeiro
3. Clique em "Selecionar app" → "Outro"
4. Digite: "Firebase Sinais"
5. Clique em "Gerar"
6. **COPIE a senha de 16 caracteres**

Exemplo: `abcd efgh ijkl mnop`

#### **2.2. Configurar no Firebase**

```bash
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="abcd efgh ijkl mnop"
```

**⚠️ IMPORTANTE:** Substitua `abcd efgh ijkl mnop` pela senha que você copiou!

#### **2.3. Re-deploy (OBRIGATÓRIO)**

```bash
firebase deploy --only functions
```

---

### **PASSO 3: Testar** (1 minuto)

1. Abra o app
2. Crie uma solicitação de certificação
3. Aguarde 30 segundos
4. Verifique `sinais.aplicativo@gmail.com`
5. **Verifique também a pasta SPAM**

---

## 🔍 Verificar se Funcionou

```bash
firebase functions:log
```

**Deve mostrar:**
```
📧 Nova solicitação de certificação: [ID]
✅ Email enviado com sucesso para: sinais.aplicativo@gmail.com
```

---

## ❌ Ainda não funciona?

### **Verificação 1: Functions estão deployadas?**

```bash
firebase functions:list
```

**Deve mostrar:**
- `sendCertificationRequestEmail`
- `sendCertificationApprovalEmail`

**Se não mostrar:** Volte ao PASSO 1

---

### **Verificação 2: Credenciais configuradas?**

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

**Se não mostrar:** Volte ao PASSO 2

---

### **Verificação 3: Plano Blaze ativo?**

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Verifique se está no **Plano Blaze**

**Se estiver no Spark:**
- Cloud Functions não funcionam no plano gratuito
- Faça upgrade para Blaze
- **Tranquilo:** 2 milhões de invocações grátis/mês

---

## 🎯 Comandos Completos (Copiar e Colar)

```bash
# 1. Deploy
cd functions && npm install && cd .. && firebase deploy --only functions

# 2. Configurar (SUBSTITUA A SENHA!)
firebase functions:config:set email.user="sinais.aplicativo@gmail.com"
firebase functions:config:set email.password="SUA_SENHA_APP_AQUI"

# 3. Re-deploy
firebase deploy --only functions

# 4. Verificar
firebase functions:list
firebase functions:config:get
firebase functions:log
```

---

## 📧 Gerar Senha de App - Passo a Passo Visual

### **Opção 1: Link Direto**
https://myaccount.google.com/apppasswords

### **Opção 2: Manualmente**
1. https://myaccount.google.com
2. Clique em "Segurança"
3. Role até "Verificação em duas etapas" → Ative
4. Role até "Senhas de app"
5. Clique em "Senhas de app"
6. Selecione "Outro" → Digite "Firebase Sinais"
7. Clique em "Gerar"
8. **COPIE a senha**

---

## ⏱️ Tempo Total

- **PASSO 1:** 2-5 minutos (deploy)
- **PASSO 2:** 3 minutos (configurar Gmail)
- **PASSO 3:** 1 minuto (testar)

**Total:** ~10 minutos

---

## ✅ Quando Funcionar

Você verá no email:

```
🏆 Nova Solicitação de Certificação Espiritual

👤 Nome do Usuário: [Nome]
📧 Email do Usuário: [Email]
🛒 Email de Compra: [Email de compra]
📅 Data da Solicitação: [Data]
🆔 ID da Solicitação: [ID]

[Botão: 📄 Ver Comprovante]
```

---

## 🆘 Precisa de Ajuda?

Execute e me envie:

```bash
firebase functions:list
firebase functions:config:get
firebase functions:log --limit 20
```

---

## 💡 Dica Final

Após configurar as variáveis de ambiente, **SEMPRE** faça re-deploy:

```bash
firebase functions:config:set email.user="..."
firebase functions:config:set email.password="..."
firebase deploy --only functions  # ← NÃO ESQUEÇA!
```

Sem o re-deploy, as functions não terão acesso às credenciais! 🔑

---

**Boa sorte! 🚀**
